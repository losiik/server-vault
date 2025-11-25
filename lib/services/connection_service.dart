import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';
import '../entity/connection.dart' as entity;

class ConnectionService {
  final AppDatabase _database = AppDatabase();

  Future<List<entity.Connection>> getConnections(int userId) async {
    final connections = await (_database.select(_database.connections)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([
            (tbl) => drift.OrderingTerm.desc(tbl.lastUsed),
            (tbl) => drift.OrderingTerm.desc(tbl.createdAt),
      ]))
        .get();

    return connections.map((dbConn) => _mapToEntity(dbConn)).toList();
  }

  Future<int> addConnection(entity.Connection connection) async {
    print('💾 Сохранение подключения:');
    print('   Тип: ${connection.type}');
    print('   Команда: ${connection.sshCommand}');
    print('   Host: ${connection.host}');
    print('   Username: ${connection.username}');

    return await _database.into(_database.connections).insert(
      ConnectionsCompanion.insert(
        userId: connection.userId,
        name: connection.name,
        type: drift.Value(connection.type.toString()),
        sshCommand: drift.Value(connection.sshCommand),
        host: drift.Value(connection.host),
        port: drift.Value(connection.port),
        username: drift.Value(connection.username),
        password: drift.Value(connection.password),
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
      password: dbConnection.password,
      createdAt: dbConnection.createdAt,
      lastUsed: dbConnection.lastUsed,
    );
  }

  void dispose() {
    _database.close();
  }
}