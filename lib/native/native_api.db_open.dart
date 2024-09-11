part of 'native_api.dart';

typedef DbOpenFunction = NativeHandleResult Function(
    Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef DbOpenNativeFunction = NativeHandleResult Function(
    Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);

final _nativeDbOpen = _lib.lookupFunction<DbOpenNativeFunction, DbOpenFunction>('_dapi_libsql_open');

Pointer<NativeDatabase> nativeDbOpen(String dbPath, String authToken, String encryptionCipher, String encryptionKey) {
  var nativeResult = _nativeDbOpen(
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
