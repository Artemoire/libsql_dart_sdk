import 'package:libsql_dart_sdk/database.dart';

void main(List<String> arguments) async {
  var db = new Database(dbPath: "local.db");
  db.exec("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT);");
  db.exec("INSERT INTO users (name) VALUES('WINRAR');");
  db.close();
  db.exec("INSERT INTO users (name) VALUES('WINRAR');");
}
