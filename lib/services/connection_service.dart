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
        systemKeyPath: drift.Value(connection.systemKeyPath),  // ⬅️ ДОБАВЛЕНО
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
      systemKeyPath: drift.Value(connection.systemKeyPath),  // ⬅️ ДОБАВЛЕНО
    ));
  }

  entity.Connection _mapToEntity(Connection dbConnection) {
    return entity.Connection(
      id: dbConnection.id,
      userId: dbConnection.userId,
      name: dbConnection.name,
      host: dbConnection.host,
      port: dbConnection.port,
      username: dbConnection.username,
      authType: entity.AuthType.fromString(dbConnection.authType),
      password: dbConnection.password,
      privateKey: dbConnection.privateKey,
      publicKey: dbConnection.publicKey,
      passphrase: dbConnection.passphrase,
      systemKeyPath: dbConnection.systemKeyPath,  // ⬅️ ДОБАВЛЕНО
      createdAt: dbConnection.createdAt,
      lastUsed: dbConnection.lastUsed,
    );
  }

  void dispose() {
    _database.close();
  }
}