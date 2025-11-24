import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import '../services/ssh_service.dart';
import '../widgets/terminal/terminal_view.dart';
import '../entity/connection.dart';

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

    try {
      final connected = await _sshService.connect(
        host: widget.connection.host,
        port: widget.connection.port,
        username: widget.connection.username,
        password: widget.connection.password,
      );

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

      _terminal.write('✓ Подключено успешно!\r\n\r\n');
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _errorMessage = e.toString();
      });

      _terminal.write('✗ Ошибка подключения: $e\r\n');
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Подключение...'),
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
            const Icon(
              Icons.error_outline,
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