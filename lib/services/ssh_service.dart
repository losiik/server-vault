import 'dart:typed_data';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:path/path.dart' as path;
import '../entity/connection.dart';

class SSHService {
  SSHClient? _client;
  SSHSession? _shell;

  bool get isConnected => _client != null;

  Future<bool> connect(Connection connection) async {
    try {
      print('🔌 Подключение SSH:');
      print('   Тип: ${connection.type}');
      print('   Host: ${connection.effectiveHost}');
      print('   Port: ${connection.effectivePort}');
      print('   Username: ${connection.effectiveUsername}');

      final socket = await SSHSocket.connect(
        connection.effectiveHost,
        connection.effectivePort,
        timeout: const Duration(seconds: 10),
      );

      if (connection.type == ConnectionType.password) {
        print('🔐 Авторизация по паролю...');
        _client = SSHClient(
          socket,
          username: connection.effectiveUsername,
          onPasswordRequest: () => connection.password ?? '',
        );
      } else {
        print('🔑 Авторизация по системным ключам...');
        final keyPairs = await _loadSystemKeys();

        if (keyPairs.isEmpty) {
          throw Exception('Не найдено ни одного SSH-ключа в ~/.ssh/');
        }

        print('   Найдено ключей: ${keyPairs.length}');

        _client = SSHClient(
          socket,
          username: connection.effectiveUsername,
          identities: keyPairs,
          onPasswordRequest: () => '',
        );
      }

      print('✓ Подключение установлено');
      return true;
    } catch (e) {
      print('✗ SSH connection error: $e');
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
          print('✓ Загружен ключ: $keyPath');
        }
      } catch (e) {
        print('✗ Не удалось загрузить ключ $keyPath: $e');
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
      return _shell;
    } catch (e) {
      print('Shell open error: $e');
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
  }
}