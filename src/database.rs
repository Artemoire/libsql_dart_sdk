use libsql::replication::Replicated;
use std::borrow::{Borrow, BorrowMut};
use std::cell::RefCell;
use std::io::Error;
use std::str::FromStr;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::Mutex;
// use tracing::trace;

use crate::errors::{map_database_closed_error, map_libsql_error};
use crate::{map_dart_void_result, runtime, DartVoidResultCallback};
// use crate::Statement;

pub(crate) struct Database {
    db: Arc<Mutex<libsql::Database>>,
    conn: RefCell<Option<Arc<Mutex<libsql::Connection>>>>,
    default_safe_integers: RefCell<bool>,
}

impl Database {
    pub fn new(db: libsql::Database, conn: libsql::Connection) -> Self {
        Database {
            db: Arc::new(Mutex::new(db)),
            conn: RefCell::new(Some(Arc::new(Mutex::new(conn)))),
            default_safe_integers: RefCell::new(false),
        }
    }

    pub fn open(
        db_path: String,
        auth_token: String,
        encryption_cipher: String,
        encryption_key: String,
    ) -> Result<Database, String> {
        let rt = runtime()?;
        let db = if is_remote_path(&db_path) {
            let version = version("remote");
            libsql::Database::open_remote_internal(db_path.clone(), auth_token, version)
        } else {
            let cipher = libsql::Cipher::from_str(&encryption_cipher).or_else(|err| {
                map_libsql_error(libsql::Error::SqliteFailure(err.extended_code, "".into()))
            })?;
            let mut builder = libsql::Builder::new_local(&db_path);
            if !encryption_key.is_empty() {
                let encryption_config =
                    libsql::EncryptionConfig::new(cipher, encryption_key.into());
                builder = builder.encryption_config(encryption_config);
            }
            rt.block_on(builder.build())
        }
        .or_else(|err| map_libsql_error(err))?;
        let conn = db.connect().or_else(|err| map_libsql_error(err))?;
        let db = Database::new(db, conn);
        Ok(db)
    }

    pub fn exec_sync(&self, sql: String) -> Result<(), String> {
        // trace!("Executing SQL statement (sync): {}", sql);
        let conn = match self.get_conn() {
            Some(conn) => conn,
            None => map_database_closed_error()?,
        };
        let rt = runtime()?;
        let result = rt.block_on(async { conn.lock().await.execute_batch(&sql).await });
        result.or_else(|err| map_libsql_error(err))?;
        Ok(())
    }

    pub fn exec_async(&self, sql: String, cb: DartVoidResultCallback) -> Result<(), String> {
        // trace!("Executing SQL statement (async): {}", sql);
        let conn = match self.get_conn() {
            Some(conn) => conn,
            None => map_database_closed_error()?,
        };
        let rt = runtime()?;
        rt.spawn(async move {
            let res = conn.lock().await.execute_batch(&sql).await
                .map(|_| ())
                .map_err(|err| map_libsql_error::<()>(err).unwrap_err());
            cb(map_dart_void_result(res));
        });
        Ok(())
    }

    pub fn close(&self) {
        // trace!("Closing database");
        self.conn.replace(None);
    }

    fn get_conn(&self) -> Option<Arc<Mutex<libsql::Connection>>> {
        let conn = self.conn.borrow();
        conn.as_ref().map(|conn| conn.clone())
    }
}

fn is_remote_path(path: &str) -> bool {
    path.starts_with("libsql://") || path.starts_with("http://") || path.starts_with("https://")
}

fn version(protocol: &str) -> String {
    let ver = env!("CARGO_PKG_VERSION");
    format!("libsql-dart-sdk-{protocol}-{ver}")
}
