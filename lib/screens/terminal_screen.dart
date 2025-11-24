import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import '../entity/connection.dart';
import '../services/ssh_service.dart';
import '../widgets/terminal/terminal_view.dart';

class TerminalScreen extends StatefulWidget {
  final Connection connection;

  const TerminalScreen({
    super.key,
    required this.connection,
  });

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _sshService = SSHService();
  final _terminal = Terminal();
  bool _isConnecting = true;
  bool _isConnected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _connectToSSH();
  }

  Future<void> _connectToSSH() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    _terminal.write('Подключение к ${widget.connection.host}...\r\n');

    if (widget.connection.authType == AuthType.password) {
      _terminal.write('Авторизация по паролю...\r\n');
    } else if (widget.connection.authType == AuthType.systemKey) {
      _terminal.write('Авторизация по системному SSH-ключу...\r\n');
      _terminal.write('Ключ: ${widget.connection.systemKeyPath ?? "~/.ssh/id_rsa"}\r\n');
    } else {
      _terminal.write('Авторизация по загруженному SSH-ключу...\r\n');
    }

    try {
      // Подключаемся к SSH
      final connected = await _sshService.connect(widget.connection);

      if (!connected) {
        throw Exception('Не удалось подключиться');
      }

      // Открываем shell
      final shell = await _sshService.openShell();

      if (shell == null) {
        throw Exception('Не удалось открыть терминал');
      }

      // Подключаем вывод SSH к терминалу
      shell.stdout.listen((data) {
        if (mounted) {
          _terminal.write(utf8.decode(data));
        }
      });

      shell.stderr.listen((data) {
        if (mounted) {
          _terminal.write(utf8.decode(data));
        }
      });

      // Подключаем ввод терминала к SSH
      _terminal.onOutput = (data) {
        _sshService.write(data);
      };

      // Обработка изменения размера терминала
      _terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        _sshService.resizeTerminal(width, height);
      };

      setState(() {
        _isConnecting = false;
        _isConnected = true;
      });

      _terminal.write('✓ Подключено успешно!\r\n');
      _terminal.write('─────────────────────────────────────\r\n');
      _terminal.write('Подключение: ${widget.connection.name}\r\n');
      _terminal.write('Сервер: ${widget.connection.username}@${widget.connection.host}:${widget.connection.port}\r\n');
      _terminal.write('Тип авторизации: ${widget.connection.authType == AuthType.password ? "Пароль" : "SSH-ключ"}\r\n');
      _terminal.write('─────────────────────────────────────\r\n\r\n');
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _errorMessage = e.toString();
      });

      _terminal.write('✗ Ошибка подключения: $e\r\n');

      if (widget.connection.authType == AuthType.key) {
        _terminal.write('\r\nПроверьте:\r\n');
        _terminal.write('- Корректность приватного ключа\r\n');
        _terminal.write('- Правильность passphrase (если есть)\r\n');
        _terminal.write('- Наличие публичного ключа на сервере\r\n');
      }
    }
  }

  Future<void> _disconnect() async {
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отключиться?'),
        content: const Text('Вы уверены, что хотите закрыть соединение?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Отключиться'),
          ),
        ],
      ),
    );

    if (shouldDisconnect == true) {
      await _sshService.disconnect();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _sshService.disconnect();
    _terminal.onOutput = null;
    _terminal.onResize = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.connection.name),
            Text(
              '${widget.connection.username}@${widget.connection.host}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          // Индикатор типа подключения
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              avatar: Icon(
                widget.connection.authType == AuthType.password
                    ? Icons.password
                    : widget.connection.authType == AuthType.systemKey
                    ? Icons.computer
                    : Icons.vpn_key,
                size: 16,
              ),
              label: Text(
                widget.connection.authType == AuthType.password
                    ? 'PWD'
                    : widget.connection.authType == AuthType.systemKey
                    ? 'SYS'
                    : 'KEY',
                style: const TextStyle(fontSize: 11),
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.power_settings_new),
              tooltip: 'Отключиться',
              onPressed: _disconnect,
            ),
        ],
      ),
      body: _isConnecting
          ? _buildLoadingView()
          : _errorMessage != null
          ? _buildErrorView()
          : SSHTerminalWidget(terminal: _terminal),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Подключение...'),
          const SizedBox(height: 8),
          Text(
            '${widget.connection.username}@${widget.connection.host}:${widget.connection.port}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.connection.authType == AuthType.password
                  ? Icons.lock_outline
                  : Icons.key_off,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ошибка подключения',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            if (widget.connection.authType == AuthType.key) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Проверьте SSH-ключ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Приватный ключ должен быть в формате PEM\n'
                          '• Публичный ключ должен быть на сервере\n'
                          '• Проверьте правильность passphrase',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _connectToSSH,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закрыть'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}