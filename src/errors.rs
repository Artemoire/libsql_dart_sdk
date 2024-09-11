pub fn map_database_closed_error<T>() -> Result<T, String> {
    Err("The database connection is not open".to_string())
}

pub fn map_libsql_error<T>(err: libsql::Error) -> Result<T, String> {
    match err {
        libsql::Error::SqliteFailure(code, err) => {
            let err = err.to_string();
            Err(err)
            //         let err = JsError::error(cx, err).unwrap();
            //         let code_num = cx.number(code);
            //         err.set(cx, "rawCode", code_num).unwrap();
            //         let code = cx.string(convert_sqlite_code(code));
            //         err.set(cx, "code", code).unwrap();
            //         let val = cx.boolean(true);
            //         err.set(cx, "libsqlError", val).unwrap();
            //         cx.throw(err)?
        }
        _ => {
            let err = err.to_string();
            Err(err)
            //         let err = JsError::error(cx, err).unwrap();
            //         let code = cx.string("");
            //         err.set(cx, "code", code).unwrap();
            //         cx.throw(err)?
        }
    }
}
