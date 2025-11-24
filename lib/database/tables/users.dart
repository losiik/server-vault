import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn  get id => integer().autoIncrement()();
  TextColumn get login => text()();
  TextColumn get password => text()();
  DateTimeColumn get createdAt => dateTime().nullable()();
}