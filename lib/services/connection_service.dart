import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';
import '../entity/connection.dart' as entity;
import 'encryption_service.dart';
import 'logger_service.dart';

class ConnectionService {
  final AppDatabase _database = AppDatabase();
  final _encryptionService = EncryptionService();
  final _logger = LoggerService();

  Future<List<entity.Connection>> getConnections(int userId) async {
    _logger.debug('📋 Загрузка подключений для пользователя ID: $userId');

    try {
      final connections = await (_database.select(_database.connections)
        ..where((tbl) => tbl.userId.equals(userId))
        ..orderBy([
              (tbl) => drift.OrderingTerm.desc(tbl.lastUsed),
              (tbl) => drift.OrderingTerm.desc(tbl.createdAt),
        ]))
          .get();

      final decryptedConnections = await Future.wait(
        connections.map((dbConn) => _mapToEntityWithDecryption(dbConn)),
      );

      _logger.logDatabase('загрузка подключений', table: 'connections', count: decryptedConnections.length);

      return decryptedConnections;
    } catch (e, stackTrace) {
      _logger.error('Ошибка загрузки подключений', e, stackTrace);
      return [];
    }
  }

  Future<int> addConnection(entity.Connection connection) async {
    _logger.logConnection('добавление', name: connection.name, host: connection.effectiveHost, username: connection.effectiveUsername);

    try {
      String? encryptedPassword;
      if (connection.password != null) {
        encryptedPassword = await _encryptionService.encryptPassword(connection.password);
        _logger.logEncryption('шифрование пароля', success: encryptedPassword != null);
      }

      final id = await _database.into(_database.connections).insert(
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

      _logger.logDatabase('создание подключения', table: 'connections', count: 1);
      return id;
    } catch (e, stackTrace) {
      _logger.logConnection('добавление', name: connection.name, error: e.toString());
      _logger.error('Ошибка добавления подключения', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteConnection(int connectionId) async {
    _logger.logConnection('удаление', name: 'ID: $connectionId');

    try {
      await (_database.delete(_database.connections)
        ..where((tbl) => tbl.id.equals(connectionId)))
          .go();

      _logger.logDatabase('удаление подключения', table: 'connections');
    } catch (e, stackTrace) {
      _logger.error('Ошибка удаления подключения', e, stackTrace);
      rethrow;
    }
  }

  Future<void> renameConnection(int connectionId, String newName) async {
    _logger.logConnection('переименование', name: newName);

    try {
      await (_database.update(_database.connections)
        ..where((tbl) => tbl.id.equals(connectionId)))
          .write(ConnectionsCompanion(name: drift.Value(newName)));

      _logger.logDatabase('обновление подключения', table: 'connections');
    } catch (e, stackTrace) {
      _logger.error('Ошибка переименования', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateLastUsed(int connectionId) async {
    try {
      await (_database.update(_database.connections)
        ..where((tbl) => tbl.id.equals(connectionId)))
          .write(ConnectionsCompanion(lastUsed: drift.Value(DateTime.now())));

      _logger.debug('⏰ Обновлено время использования подключения ID: $connectionId');
    } catch (e) {
      _logger.warning('Ошибка обновления времени использования', e);
    }
  }

  Future<entity.Connection> _mapToEntityWithDecryption(Connection dbConnection) async {
    String? decryptedPassword;
    if (dbConnection.password != null) {
      decryptedPassword = await _encryptionService.decryptPassword(dbConnection.password);
      _logger.logEncryption('расшифровка пароля', success: decryptedPassword != null);
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