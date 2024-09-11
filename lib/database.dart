import 'dart:ffi';

import 'package:libsql_dart_sdk/native_libsql_api.dart';

class Database implements Finalizable {
  static final _finalizer = NativeFinalizer(nativeDatabaseFreeAddress.cast());

  final Pointer<NativeDatabase> _db;
  bool _closed = false;

  Database({
    required String dbPath,
    String? authToken,
    String? encryptionKey,
    String? encryptionCipher,
  }) : _db = nativeLibsqlOpen(dbPath, authToken ?? "",
            encryptionCipher ?? "aes256cbc", encryptionKey ?? "") {
    _finalizer.attach(this, _db.cast(), detach: this);
  }

  void exec(String sql) {
    if (_closed) {
      throw StateError('The database has been closed.');
    }
    
    nativeLibsqlExecSync(_db, sql);
  }

  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    nativeLibsqlClose(_db);
    _finalizer.detach(this);
    nativeDatabaseFree(_db);
  }
}
