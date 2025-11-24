import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';
import '../entity/connection.dart' as entity;

class ConnectionService {
  final AppDatabase _database = AppDatabase();

  /// Получить все подключения пользователя
  Future<List> getConnections(int userId) async {
    final connections = await (_database.select(_database.connections)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.lastUsed)]))
        .get();

    return connections.map(_mapToEntity as Function(Connection e)).toList();
  }

  /// Добавить новое подключение
  Future<int> addConnection(entity.Connection connection) async {
    return await _database.into(_database.connections).insert(
      ConnectionsCompanion.insert(
        userId: connection.userId,
        name: connection.name,
        host: connection.host,
        port: drift.Value(connection.port),
        username: connection.username,
        authType: drift.Value(connection.authType.toString()),
        password: drift.Value(connection.password),
        privateKey: drift.Value(connection.privateKey),
        publicKey: drift.Value(connection.publicKey),
        passphrase: drift.Value(connection.passphrase),
      ),
    );
  }

  /// Удалить подключение
  Future<void> deleteConnection(int connectionId) async {
    await (_database.delete(_database.connections)
      ..where((tbl) => tbl.id.equals(connectionId)))
        .go();
  }

  /// Переименовать подключение
  Future<void> renameConnection(int connectionId, String newName) async {
    await (_database.update(_database.connections)
      ..where((tbl) => tbl.id.equals(connectionId)))
        .write(ConnectionsCompanion(name: drift.Value(newName)));
  }

  /// Обновить время последнего использования
  Future<void> updateLastUsed(int connectionId) async {
    await (_database.update(_database.connections)
      ..where((tbl) => tbl.id.equals(connectionId)))
        .write(ConnectionsCompanion(lastUsed: drift.Value(DateTime.now())));
  }

  /// Обновить подключение
  Future<void> updateConnection(entity.Connection connection) async {
    if (connection.id == null) return;

    await (_database.update(_database.connections)
      ..where((tbl) => tbl.id.equals(connection.id!)))
        .write(ConnectionsCompanion(
      name: drift.Value(connection.name),
      host: drift.Value(connection.host),
      port: drift.Value(connection.port),
      username: drift.Value(connection.username),
      authType: drift.Value(connection.authType.toString()),
      password: drift.Value(connection.password),
      privateKey: drift.Value(connection.privateKey),
      publicKey: drift.Value(connection.publicKey),
      passphrase: drift.Value(connection.passphrase),
    ));
  }

  /// Преобразование из БД в entity
  entity.Connection _mapToEntity(entity.Connection dbConnection) {
    return entity.Connection(
      id: dbConnection.id,
      userId: dbConnection.userId,
      name: dbConnection.name,
      host: dbConnection.host,
      port: dbConnection.port,
      username: dbConnection.username,
      authType: entity.AuthType.fromString(dbConnection.authType as String),
      password: dbConnection.password,
      privateKey: dbConnection.privateKey,
      publicKey: dbConnection.publicKey,
      passphrase: dbConnection.passphrase,
      createdAt: dbConnection.createdAt,
      lastUsed: dbConnection.lastUsed,
    );
  }

  void dispose() {
    _database.close();
  }
}