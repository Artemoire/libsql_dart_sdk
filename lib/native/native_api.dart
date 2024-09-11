import 'dart:async';
import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

part 'native_api.result.dart';
part 'native_api.database.dart';
part 'native_api.db_open.dart';
part 'native_api.db_close.dart';
part 'native_api.db_exec.dart';

final DynamicLibrary _lib = Platform.isWindows
    ? DynamicLibrary.open('target\\debug\\liblibsql_dart_sdk.dll')
    : Platform.isMacOS
        ? DynamicLibrary.open('target/debug/liblibsql_dart_sdk.dylib')
        : DynamicLibrary.open('target/debug/liblibsql_dart_sdk.so');
