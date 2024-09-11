part of 'native_api.dart';

final class NativeHandleResult extends Struct {
  @Bool()
  external bool is_error;
  external Pointer<Utf8> error_message;
  external Pointer<Void> handle;
}

final class NativeVoidResult extends Struct {
  @Bool()
  external bool is_error;
  external Pointer<Utf8> error_message;
}
