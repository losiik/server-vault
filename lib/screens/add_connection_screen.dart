import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
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
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passphraseController = TextEditingController();
  final _keyPathController = TextEditingController();

  AuthType _authType = AuthType.password;
  String? _privateKeyPath;
  String? _privateKeyContent;

  @override
  void initState() {
    super.initState();
    // Устанавливаем путь по умолчанию для системного ключа
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    _keyPathController.text = Platform.isWindows
        ? '$home\\.ssh\\id_rsa'
        : '$home/.ssh/id_rsa';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _passphraseController.dispose();
    _keyPathController.dispose();
    super.dispose();
  }

  Future<void> _pickPrivateKey() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      setState(() {
        _privateKeyPath = result.files.single.name;
        _privateKeyContent = content;
      });
    }
  }

  void _saveConnection() {
    if (_formKey.currentState!.validate()) {
      // Проверка для типа авторизации по загруженному ключу
      if (_authType == AuthType.key && _privateKeyContent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Выберите файл приватного ключа'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final connection = Connection(
        userId: widget.userId,
        name: _nameController.text.trim(),
        host: _hostController.text.trim(),
        port: int.tryParse(_portController.text) ?? 22,
        username: _usernameController.text.trim(),
        authType: _authType,
        password: _authType == AuthType.password ? _passwordController.text : null,
        privateKey: _authType == AuthType.key ? _privateKeyContent : null,
        passphrase: _authType == AuthType.key && _passphraseController.text.isNotEmpty
            ? _passphraseController.text
            : null,
        systemKeyPath: _authType == AuthType.systemKey ? _keyPathController.text.trim() : null,
      );

      widget.onAdd(connection);
      Navigator.pop(context);
    }
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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Название",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите название';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

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

                const SizedBox(height: 24),

                // Выбор типа авторизации
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Тип авторизации',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        RadioListTile<AuthType>(
                          title: const Text('По паролю'),
                          subtitle: const Text('Обычная авторизация'),
                          value: AuthType.password,
                          groupValue: _authType,
                          onChanged: (value) {
                            setState(() => _authType = value!);
                          },
                        ),
                        RadioListTile<AuthType>(
                          title: const Text('Системный SSH-ключ'),
                          subtitle: const Text('Использовать ~/.ssh/id_rsa'),
                          value: AuthType.systemKey,
                          groupValue: _authType,
                          onChanged: (value) {
                            setState(() => _authType = value!);
                          },
                        ),
                        RadioListTile<AuthType>(
                          title: const Text('Загрузить SSH-ключ'),
                          subtitle: const Text('Загрузить приватный ключ'),
                          value: AuthType.key,
                          groupValue: _authType,
                          onChanged: (value) {
                            setState(() => _authType = value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Поля в зависимости от типа авторизации
                if (_authType == AuthType.password) ...[
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
                ] else if (_authType == AuthType.systemKey) ...[
                  TextFormField(
                    controller: _keyPathController,
                    decoration: const InputDecoration(
                      labelText: "Путь к приватному ключу",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.folder),
                      helperText: 'Обычно: ~/.ssh/id_rsa',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите путь к ключу';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Используется SSH-ключ, уже настроенный в системе',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: _pickPrivateKey,
                    icon: const Icon(Icons.file_upload),
                    label: Text(
                      _privateKeyPath ?? 'Выбрать приватный ключ',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  if (_privateKeyPath != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Выбран: $_privateKeyPath',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passphraseController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Passphrase (если есть)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                      hintText: "Оставьте пустым, если ключ без пароля",
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