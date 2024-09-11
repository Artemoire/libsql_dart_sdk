part of 'native_api.dart';

final class NativeDatabase extends Opaque {}

typedef DbFreeFunction = void Function(Pointer<NativeDatabase>);
typedef DbFreeNativeFunction = Void Function(Pointer<NativeDatabase>);

final nativeDbFreeAddress = _lib.lookup<NativeFunction<DbFreeNativeFunction>>('_dapi_db_box_from_raw');
final nativeDbFree = nativeDbFreeAddress.asFunction<DbFreeFunction>();
