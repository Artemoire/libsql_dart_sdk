import 'dart:ffi';

import 'package:libsql_dart_sdk/native/native_api.dart';

class Database implements Finalizable {
  static final _finalizer = NativeFinalizer(nativeDbFreeAddress.cast());

  final Pointer<NativeDatabase> _db;
  bool _closed = false;

  Database({
    required String dbPath,
    String? authToken,
    String? encryptionKey,
    String? encryptionCipher,
  }) : _db = nativeDbOpen(dbPath, authToken ?? "",
            encryptionCipher ?? "aes256cbc", encryptionKey ?? "") {
    _finalizer.attach(this, _db.cast(), detach: this);
  }

  void exec(String sql) {
    if (_closed) {
      throw StateError('The database has been closed.');
    }

    nativeDbExec(_db, sql);
  }

  Future<void> execAsync(String sql) {
    if (_closed) {
      throw StateError('The database has been closed.');
    }

    return nativeDbExecAsync(_db, sql);
  }

  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    nativeDbClose(_db);
    _finalizer.detach(this);
    nativeDbFree(_db);
  }
}
