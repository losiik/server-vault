import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import '../entity/connection.dart';

class SSHService {
  SSHClient? _client;
  SSHSession? _shell;

  bool get isConnected => _client != null;

  /// Подключение к SSH серверу
  Future<bool> connect(Connection connection) async {
    try {
      final socket = await SSHSocket.connect(
        connection.host,
        connection.port,
      );

      if (connection.authType == AuthType.password) {
        // Подключение по паролю
        _client = SSHClient(
          socket,
          username: connection.username,
          onPasswordRequest: () => connection.password ?? '',
        );
      } else {
        // Подключение по ключу
        if (connection.privateKey == null) {
          throw Exception('Private key is required');
        }

        _client = SSHClient(
          socket,
          username: connection.username,
          identities: [
            ...SSHKeyPair.fromPem(connection.privateKey!),
          ],
        );
      }

      return true;
    } catch (e) {
      print('SSH connection error: $e');
      return false;
    }
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