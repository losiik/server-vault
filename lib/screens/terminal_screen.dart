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

    _terminal.write('Подключение к ${widget.connection.effectiveHost}...\r\n');

    if (widget.connection.type == ConnectionType.password) {
      _terminal.write('Авторизация по паролю...\r\n');
    } else {
      _terminal.write('Авторизация по SSH команде...\r\n');
      _terminal.write('Команда: ${widget.connection.sshCommand}\r\n');
    }

    try {
      final connected = await _sshService.connect(widget.connection);

      if (!connected) {
        throw Exception('Не удалось подключиться');
      }

      final shell = await _sshService.openShell();

      if (shell == null) {
        throw Exception('Не удалось открыть терминал');
      }

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

      _terminal.onOutput = (data) {
        _sshService.write(data);
      };

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
      _terminal.write('Сервер: ${widget.connection.effectiveUsername}@${widget.connection.effectiveHost}:${widget.connection.effectivePort}\r\n');
      _terminal.write('Тип: ${widget.connection.type == ConnectionType.password ? "Пароль" : "SSH команда"}\r\n');
      _terminal.write('─────────────────────────────────────\r\n\r\n');
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _errorMessage = e.toString();
      });

      _terminal.write('✗ Ошибка подключения: $e\r\n');

      if (widget.connection.type == ConnectionType.command) {
        _terminal.write('\r\nПроверьте:\r\n');
        _terminal.write('- Корректность SSH команды\r\n');
        _terminal.write('- Наличие ключей в ~/.ssh/\r\n');
        _terminal.write('- Права доступа к ключам\r\n');
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
              '${widget.connection.effectiveUsername}@${widget.connection.effectiveHost}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              avatar: Icon(
                widget.connection.type == ConnectionType.password
                    ? Icons.password
                    : Icons.terminal,
                size: 16,
              ),
              label: Text(
                widget.connection.type == ConnectionType.password ? 'PWD' : 'CMD',
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
            '${widget.connection.effectiveUsername}@${widget.connection.effectiveHost}:${widget.connection.effectivePort}',
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
              widget.connection.type == ConnectionType.password
                  ? Icons.lock_outline
                  : Icons.terminal,
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
            if (widget.connection.type == ConnectionType.command) ...[
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
                          'Проверьте SSH-ключи',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Ключи должны находиться в ~/.ssh/\n'
                          '• Проверьте права доступа (chmod 600)\n'
                          '• Публичный ключ должен быть на сервере',
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