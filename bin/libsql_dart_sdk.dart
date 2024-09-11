import 'package:libsql_dart_sdk/database.dart';

void main(List<String> arguments) async {
  var db = new Database(dbPath: "local.db");
  await db.execAsync("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT);");

  await Future.wait([
    db.execAsync("INSERT INTO users (name) VALUES('1 WINRAR');"),
    db.execAsync("INSERT INTO users (name) VALUES('2 WINRAR');"),
    db.execAsync("INSERT INTO users (name) VALUES('3 WINRAR');"),
    db.execAsync("INSERT INTO users (name) VALUES('4 WINRAR');"),
  ]);
}
