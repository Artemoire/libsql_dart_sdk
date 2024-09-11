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

typedef DbExecAsyncCallback = Void Function(NativeVoidResult);
typedef DbExecAsyncFunction = void Function(Pointer<NativeDatabase>,
    Pointer<Utf8>, Pointer<NativeFunction<DbExecAsyncCallback>>);
typedef DbExecAsyncNativeFunction = Void Function(Pointer<NativeDatabase>,
    Pointer<Utf8>, Pointer<NativeFunction<DbExecAsyncCallback>>);

final _nativeDbExecAsync = _lib.lookupFunction<DbExecAsyncNativeFunction, DbExecAsyncFunction>('_dapi_libsql_exec_async');

Future<void> nativeDbExecAsync(Pointer<NativeDatabase> db, String sql) {
  final sqlCStr = sql.toNativeUtf8();

  final completer = Completer<void>();
  late final NativeCallable<DbExecAsyncCallback> callback;
  void onResult(NativeVoidResult result) {
    if (result.is_error) {
      completer.completeError(new Exception(result.error_message.toDartString()));
    } else {
      completer.complete();
    }
    calloc.free(sqlCStr);
    
    callback.close();
  }
  callback = NativeCallable<DbExecAsyncCallback>.listener(onResult);

  _nativeDbExecAsync(db, sqlCStr, callback.nativeFunction);

  return completer.future;
}
