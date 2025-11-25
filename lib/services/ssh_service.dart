import 'dart:typed_data';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:path/path.dart' as path;
import '../entity/connection.dart';
import 'logger_service.dart';

class SSHService {
  SSHClient? _client;
  SSHSession? _shell;
  final _logger = LoggerService();

  bool get isConnected => _client != null;

  Future<bool> connect(Connection connection) async {
    _logger.logSSH(
      'попытка подключения',
      host: connection.effectiveHost,
      port: connection.effectivePort,
      username: connection.effectiveUsername,
    );

    try {
      final socket = await SSHSocket.connect(
        connection.effectiveHost,
        connection.effectivePort,
        timeout: const Duration(seconds: 10),
      );

      if (connection.type == ConnectionType.password) {
        _logger.debug('🔐 Авторизация по паролю');
        _client = SSHClient(
          socket,
          username: connection.effectiveUsername,
          onPasswordRequest: () => connection.password ?? '',
        );
      } else {
        _logger.debug('🔑 Авторизация по системным ключам');
        final keyPairs = await _loadSystemKeys();

        if (keyPairs.isEmpty) {
          throw Exception('Не найдено ни одного SSH-ключа в ~/.ssh/');
        }

        _logger.info('🔑 Найдено ключей: ${keyPairs.length}');

        _client = SSHClient(
          socket,
          username: connection.effectiveUsername,
          identities: keyPairs,
          onPasswordRequest: () => '',
        );
      }

      _logger.logSSH(
        'подключение установлено',
        host: connection.effectiveHost,
        port: connection.effectivePort,
        username: connection.effectiveUsername,
      );
      return true;
    } catch (e, stackTrace) {
      _logger.logSSH(
        'ошибка подключения',
        host: connection.effectiveHost,
        port: connection.effectivePort,
        username: connection.effectiveUsername,
        error: e.toString(),
      );
      _logger.error('SSH connection error', e, stackTrace);
      return false;
    }
  }

  Future<List<SSHKeyPair>> _loadSystemKeys() async {
    final List<SSHKeyPair> keys = [];
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';

    final possibleKeys = [
      path.join(home, '.ssh', 'id_rsa'),
      path.join(home, '.ssh', 'id_ed25519'),
      path.join(home, '.ssh', 'id_ecdsa'),
    ];

    for (final keyPath in possibleKeys) {
      try {
        final file = File(keyPath);
        if (await file.exists()) {
          final content = await file.readAsString();
          keys.addAll(SSHKeyPair.fromPem(content));
          _logger.info('✅ Загружен ключ: $keyPath');
        }
      } catch (e) {
        _logger.warning('⚠️ Не удалось загрузить ключ $keyPath', e);
      }
    }

    return keys;
  }

  Future<SSHSession?> openShell() async {
    if (_client == null) return null;

    try {
      _shell = await _client!.shell(
        pty: SSHPtyConfig(
          width: 80,
          height: 25,
        ),
      );
      _logger.info('🖥️ SSH shell открыт');
      return _shell;
    } catch (e, stackTrace) {
      _logger.error('Shell open error', e, stackTrace);
      return null;
    }
  }

  void write(String data) {
    _shell?.write(Uint8List.fromList(data.codeUnits));
  }

  void resizeTerminal(int width, int height) {
    _shell?.resizeTerminal(width, height);
  }

  Future<void> disconnect() async {
    _shell?.close();
    _client?.close();
    _shell = null;
    _client = null;
    _logger.info('🔌 SSH отключен');
  }
}