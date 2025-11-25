import 'package:flutter/material.dart';
import '../entity/connection.dart';

class AddConnectionScreen extends StatefulWidget {
  final int userId;
  final Function(Connection) onAdd;

  const AddConnectionScreen({
    super.key,
    required this.userId,
    required this.onAdd,
  });

  @override
  State<AddConnectionScreen> createState() => _AddConnectionScreenState();
}

class _AddConnectionScreenState extends State<AddConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commandController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  ConnectionType _connectionType = ConnectionType.password;

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _saveConnection() {
    if (_formKey.currentState!.validate()) {
      final connection = Connection(
        userId: widget.userId,
        name: _nameController.text.trim(),
        type: _connectionType,
        sshCommand: _connectionType == ConnectionType.command
            ? _commandController.text.trim()
            : null,
        host: _connectionType == ConnectionType.password
            ? _hostController.text.trim()
            : null,
        port: _connectionType == ConnectionType.password
            ? int.tryParse(_portController.text) ?? 22
            : null,
        username: _connectionType == ConnectionType.password
            ? _usernameController.text.trim()
            : null,
        password: _connectionType == ConnectionType.password
            ? _passwordController.text
            : null,
      );

      widget.onAdd(connection);
      Navigator.pop(context);
    }
  }

  void _previewCommand() {
    if (_commandController.text.trim().isEmpty) return;

    final tempConn = Connection(
      userId: 0,
      name: '',
      type: ConnectionType.command,
      sshCommand: _commandController.text.trim(),
    );

    final parsed = tempConn.parsedCommand;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Параметры подключения'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Распознанные параметры:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Пользователь', parsed['username']),
            _buildInfoRow('Хост', parsed['host']),
            _buildInfoRow('Порт', '${parsed['port']}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Команда подключения:\nssh ${parsed['username']}@${parsed['host']} -p ${parsed['port']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Новое подключение"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.terminal,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Название подключения",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                    hintText: "Мой сервер",
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите название';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Выбор типа подключения
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Тип подключения',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        RadioListTile<ConnectionType>(
                          title: const Text('По логину и паролю'),
                          subtitle: const Text('Классическое подключение'),
                          value: ConnectionType.password,
                          groupValue: _connectionType,
                          onChanged: (value) {
                            setState(() => _connectionType = value!);
                          },
                        ),
                        RadioListTile<ConnectionType>(
                          title: const Text('По SSH команде'),
                          subtitle: const Text('Использовать системные ключи'),
                          value: ConnectionType.command,
                          groupValue: _connectionType,
                          onChanged: (value) {
                            setState(() => _connectionType = value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Поля в зависимости от типа
                if (_connectionType == ConnectionType.password) ...[
                  TextFormField(
                    controller: _hostController,
                    decoration: const InputDecoration(
                      labelText: "Хост (IP или домен)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.dns),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите хост';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: "Порт",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.settings_ethernet),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите порт';
                      }
                      final port = int.tryParse(value);
                      if (port == null || port < 1 || port > 65535) {
                        return 'Введите корректный порт (1-65535)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: "Имя пользователя",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите имя пользователя';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Пароль",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите пароль';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  TextFormField(
                    controller: _commandController,
                    decoration: InputDecoration(
                      labelText: "SSH команда",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.computer),
                      hintText: "ssh -l user 192.168.1.1",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.preview),
                        onPressed: _previewCommand,
                        tooltip: 'Предпросмотр',
                      ),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите SSH команду';
                      }
                      if (!value.trim().startsWith('ssh')) {
                        return 'Команда должна начинаться с "ssh"';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, size: 20, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Примеры команд',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• ssh -l username 192.168.1.1\n'
                              '• ssh username@example.com\n'
                              '• ssh 192.168.1.1 -p 2222 -l user\n'
                              '• ssh user@host.com -p 22',
                          style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: _saveConnection,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    "Сохранить подключение",
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}