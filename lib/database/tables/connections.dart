import 'package:drift/drift.dart';

class Connections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();
  TextColumn get name => text()();

  // Тип подключения: 'password' или 'command'
  TextColumn get type => text().withDefault(const Constant('password'))();

  // Для типа COMMAND
  TextColumn get sshCommand => text().nullable()();

  // Для типа PASSWORD
  TextColumn get host => text().nullable()();
  IntColumn get port => integer().nullable()();
  TextColumn get username => text().nullable()();
  TextColumn get password => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastUsed => dateTime().nullable()();
}