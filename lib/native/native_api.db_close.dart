part of 'native_api.dart';

typedef DbCloseFunction = void Function(Pointer<NativeDatabase>);
typedef DbCloseNativeFunction = Void Function(Pointer<NativeDatabase>);

final nativeDbClose = _lib.lookupFunction<DbCloseNativeFunction, DbCloseFunction>('_dapi_libsql_close');
