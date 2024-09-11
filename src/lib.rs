mod database;
mod errors;

use database::Database;
use once_cell::sync::OnceCell;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::os::raw::c_void;
use std::sync::Arc;
use tokio::runtime::Runtime;

fn runtime() -> Result<&'static Runtime, String> {
    static RUNTIME: OnceCell<Runtime> = OnceCell::new();

    RUNTIME
        .get_or_try_init(Runtime::new)
        .or_else(|err| Err(err.to_string()))
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
pub struct DartHandleResult {
    pub is_error: bool,
    pub error_message: *const c_char,
    pub handle: *const c_void,
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
pub struct DartVoidResult {
    pub is_error: bool,
    pub error_message: *const c_char,
}

type DartVoidResultCallback = extern "C" fn(DartVoidResult);

fn wrap_dart_void_callback(callback: DartVoidResultCallback) -> impl Fn(Result<(), String>) {
    move |result| {
        let dart_result = match result {
            Ok(()) => DartVoidResult {
                is_error: false,
                error_message: std::ptr::null(),
            },
            Err(err) => DartVoidResult {
                is_error: true,
                error_message: CString::new(err).expect("CString::new failed").into_raw(),
            },
        };

        callback(dart_result);
    }
}

#[no_mangle]
pub extern "C" fn _dapi_db_box_from_raw(ptr: *mut c_void) {
    let arc_ptr: *mut Arc<Database> = ptr as *mut Arc<Database>;

    unsafe {
        let _db = Box::from_raw(arc_ptr);
    }
}

#[no_mangle]
pub extern "C" fn _dapi_libsql_open(
    db_path: *const c_char,
    auth_token: *const c_char,
    encryption_cipher: *const c_char,
    encryption_key: *const c_char,
) -> DartHandleResult {
    Database::open(
        c_str_to_str(db_path),
        c_str_to_str(auth_token),
        c_str_to_str(encryption_cipher),
        c_str_to_str(encryption_key),
    )
    .map_or_else(
        |v| DartHandleResult {
            is_error: true,
            error_message: CString::new(v).expect("CString::new failed").into_raw(),
            handle: std::ptr::null() as *const c_void,
        },
        |f| DartHandleResult {
            is_error: false,
            error_message: std::ptr::null() as *const c_char,
            handle: (Box::into_raw(Box::new(Arc::new(f)))) as *mut c_void,
        },
    )
}

#[no_mangle]
pub extern "C" fn _dapi_libsql_exec_sync(
    db_ptr: *mut c_void,
    sql: *const c_char,
) -> DartVoidResult {
    let arc_ptr: *mut Arc<Database> = db_ptr as *mut Arc<Database>;

    unsafe {
        let db = (*arc_ptr).clone();
        db.exec_sync(c_str_to_str(sql)).map_or_else(
            |err| DartVoidResult {
                is_error: true,
                error_message: CString::new(err).expect("CString::new failed").into_raw(),
            },
            |_| DartVoidResult {
                is_error: false,
                error_message: std::ptr::null() as *const c_char,
            },
        )
    }
}

#[no_mangle]
pub extern "C" fn _dapi_libsql_exec_async(
    db_ptr: *mut c_void,
    sql: *const c_char,
    cb: DartVoidResultCallback,
) {
    let arc_ptr: *mut Arc<Database> = db_ptr as *mut Arc<Database>;
    let wrapped_cb = wrap_dart_void_callback(cb);

    unsafe {
        let db = (*arc_ptr).clone();
        let _ = db.exec_async(c_str_to_str(sql), wrapped_cb).map_err(|err| {
            cb(DartVoidResult {
                is_error: true,
                error_message: CString::new(err).expect("CString::new failed").into_raw(),
            });            
        });
    }
}

#[no_mangle]
pub extern "C" fn _dapi_libsql_close(db_ptr: *mut c_void) {
    let arc_ptr: *mut Arc<Database> = db_ptr as *mut Arc<Database>;

    unsafe {
        let db = (*arc_ptr).clone();
        db.close();
    }
}

fn c_str_to_str(c_str_ptr: *const c_char) -> String {
    if c_str_ptr.is_null() {
        return "".to_string();
    }

    unsafe {
        let c_str = CStr::from_ptr(c_str_ptr);

        match c_str.to_str() {
            Ok(str_slice) => str_slice.to_string(),
            Err(_) => "".to_string(),
        }
    }
}
