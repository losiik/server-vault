import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';
import '../entity/connection.dart' as entity;
import 'encryption_service.dart';

class ConnectionService {
  final AppDatabase _database = AppDatabase();
  final _encryptionService = EncryptionService();

  Future<List<entity.Connection>> getConnections(int userId) async {
    final connections = await (_database.select(_database.connections)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([
            (tbl) => drift.OrderingTerm.desc(tbl.lastUsed),
            (tbl) => drift.OrderingTerm.desc(tbl.createdAt),
      ]))
        .get();

    // Расшифровываем пароли при получении
    final decryptedConnections = await Future.wait(
      connections.map((dbConn) => _mapToEntityWithDecryption(dbConn)),
    );

    return decryptedConnections;
  }

  Future<int> addConnection(entity.Connection connection) async {
    print('💾 Сохранение подключения с шифрованием...');

    // Шифруем пароль перед сохранением
    String? encryptedPassword;
    if (connection.password != null) {
      encryptedPassword = await _encryptionService.encryptPassword(connection.password);
      print('   Пароль зашифрован: ${encryptedPassword != null ? "✓" : "✗"}');
    }

    return await _database.into(_database.connections).insert(
      ConnectionsCompanion.insert(
        userId: connection.userId,
        name: connection.name,
        type: drift.Value(connection.type.toString()),
        sshCommand: drift.Value(connection.sshCommand),
        host: drift.Value(connection.host),
        port: drift.Value(connection.port),
        username: drift.Value(connection.username),
        password: drift.Value(encryptedPassword),
      ),
    );
  }

  Future<void> deleteConnection(int connectionId) async {
    await (_database.delete(_database.connections)
      ..where((tbl) => tbl.id.equals(connectionId)))
        .go();
  }

  Future<void> renameConnection(int connectionId, String newName) async {
    await (_database.update(_database.connections)
      ..where((tbl) => tbl.id.equals(connectionId)))
        .write(ConnectionsCompanion(name: drift.Value(newName)));
  }

  Future<void> updateLastUsed(int connectionId) async {
    await (_database.update(_database.connections)
      ..where((tbl) => tbl.id.equals(connectionId)))
        .write(ConnectionsCompanion(lastUsed: drift.Value(DateTime.now())));
  }

  // Старый метод (без расшифровки)
  entity.Connection _mapToEntity(Connection dbConnection) {
    return entity.Connection(
      id: dbConnection.id,
      userId: dbConnection.userId,
      name: dbConnection.name,
      type: entity.ConnectionType.fromString(dbConnection.type),
      sshCommand: dbConnection.sshCommand,
      host: dbConnection.host,
      port: dbConnection.port,
      username: dbConnection.username,
      password: dbConnection.password,  // Зашифрованный пароль
      createdAt: dbConnection.createdAt,
      lastUsed: dbConnection.lastUsed,
    );
  }

  // Новый метод (с расшифровкой)
  Future<entity.Connection> _mapToEntityWithDecryption(Connection dbConnection) async {
    // Расшифровываем пароль
    String? decryptedPassword;
    if (dbConnection.password != null) {
      decryptedPassword = await _encryptionService.decryptPassword(dbConnection.password);
    }

    return entity.Connection(
      id: dbConnection.id,
      userId: dbConnection.userId,
      name: dbConnection.name,
      type: entity.ConnectionType.fromString(dbConnection.type),
      sshCommand: dbConnection.sshCommand,
      host: dbConnection.host,
      port: dbConnection.port,
      username: dbConnection.username,
      password: decryptedPassword,
      createdAt: dbConnection.createdAt,
      lastUsed: dbConnection.lastUsed,
    );
  }

  void dispose() {
    _database.close();
  }
}