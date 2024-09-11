import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'native_libsql_api.def.dart';

final DynamicLibrary _lib = Platform.isWindows
    ? DynamicLibrary.open('target\\debug\\liblibsql_dart_sdk.dll')
    : Platform.isMacOS
        ? DynamicLibrary.open('target/debug/liblibsql_dart_sdk.dylib')
        : DynamicLibrary.open('target/debug/liblibsql_dart_sdk.so');

final class NativeDatabase extends Opaque {}

typedef LibsqlOpenFunction = NativeHandleResult Function(
    Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef LibsqlOpenNativeFunction = NativeHandleResult Function(
    Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);


final _nativeLibsqlOpen = _lib.lookupFunction<LibsqlOpenNativeFunction, LibsqlOpenFunction>('_dapi_libsql_open');

Pointer<NativeDatabase> nativeLibsqlOpen(String dbPath, String authToken, String encryptionCipher, String encryptionKey) {
  var nativeResult = _nativeLibsqlOpen(
    dbPath.toNativeUtf8(),
    authToken.toNativeUtf8(),
    encryptionCipher.toNativeUtf8(),
    encryptionKey.toNativeUtf8(),
  );

  if (nativeResult.is_error) {
    throw new Exception(nativeResult.error_message.toDartString());
  }

  return nativeResult.handle.cast<NativeDatabase>();
}

typedef DatabaseFreeFunction = void Function(Pointer<NativeDatabase>);
typedef DatabaseFreeNativeFunction = Void Function(Pointer<NativeDatabase>);

final nativeDatabaseFreeAddress = _lib.lookup<NativeFunction<DatabaseFreeNativeFunction>>('_dapi_db_box_from_raw');
final nativeDatabaseFree = nativeDatabaseFreeAddress.asFunction<DatabaseFreeFunction>();

typedef LibsqlExecSyncFunction = NativeVoidResult Function(Pointer<NativeDatabase>, Pointer<Utf8>);
typedef LibsqlExecSyncNativeFunction = NativeVoidResult Function(Pointer<NativeDatabase>, Pointer<Utf8>);

final _nativeLibsqlExecSync = _lib.lookupFunction<LibsqlExecSyncNativeFunction, LibsqlExecSyncFunction>('_dapi_libsql_exec_sync');

void nativeLibsqlExecSync(Pointer<NativeDatabase> db, String sql) {
  var nativeSql = sql.toNativeUtf8();
  var nativeResult = _nativeLibsqlExecSync(db, nativeSql);
  calloc.free(nativeSql);

  if (nativeResult.is_error) {
    throw new Exception(nativeResult.error_message.toDartString());
  }
}

typedef LibsqlCloseFunction = void Function(Pointer<NativeDatabase>);
typedef LibsqlCloseNativeFunction = Void Function(Pointer<NativeDatabase>);

final nativeLibsqlClose = _lib.lookupFunction<LibsqlCloseNativeFunction, LibsqlCloseFunction>('_dapi_libsql_close');
