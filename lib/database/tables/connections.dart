import 'package:drift/drift.dart';

class Connections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();  // Связь с пользователем
  TextColumn get name => text()();
  TextColumn get host => text()();
  IntColumn get port => integer().withDefault(const Constant(22))();
  TextColumn get username => text()();

  // Тип авторизации: 'password' или 'key'
  TextColumn get authType => text().withDefault(const Constant('password'))();

  // Для авторизации по паролю
  TextColumn get password => text().nullable()();

  // Для авторизации по ключу
  TextColumn get privateKey => text().nullable()();
  TextColumn get publicKey => text().nullable()();
  TextColumn get passphrase => text().nullable()();  // Пароль для ключа (если есть)

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastUsed => dateTime().nullable()();
}