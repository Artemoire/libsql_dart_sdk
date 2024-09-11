part of 'native_api.dart';

typedef DbExecFunction = NativeVoidResult Function(
    Pointer<NativeDatabase>, Pointer<Utf8>);
typedef DbExecNativeFunction = NativeVoidResult Function(
    Pointer<NativeDatabase>, Pointer<Utf8>);

final _nativeDbExec = _lib.lookupFunction<DbExecNativeFunction, DbExecFunction>(
    '_dapi_libsql_exec_sync');

void nativeDbExec(Pointer<NativeDatabase> db, String sql) {
  var sqlCStr = sql.toNativeUtf8();
  var nativeResult = _nativeDbExec(db, sqlCStr);
  calloc.free(sqlCStr);

  if (nativeResult.is_error) {
    throw new Exception(nativeResult.error_message.toDartString());
  }
}
