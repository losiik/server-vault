class Connection {
  final int? id;
  final int userId;
  final String name;
  final ConnectionType type;

  // Для типа COMMAND
  final String? sshCommand;

  // Для типа PASSWORD
  final String? host;
  final int? port;
  final String? username;
  final String? password;

  final DateTime? createdAt;
  final DateTime? lastUsed;

  Connection({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.sshCommand,
    this.host,
    this.port,
    this.username,
    this.password,
    this.createdAt,
    this.lastUsed,
  });

  Map<String, dynamic> get parsedCommand {
    if (type != ConnectionType.command || sshCommand == null) {
      return {
        'username': username ?? 'root',
        'host': host ?? 'localhost',
        'port': port ?? 22,
      };
    }

    String cmd = sshCommand!.trim();
    String? parsedUsername;
    String? parsedHost;
    int parsedPort = 22;

    // Убираем "ssh" в начале
    if (cmd.startsWith('ssh ')) {
      cmd = cmd.substring(4).trim();
    }

    final parts = cmd.split(RegExp(r'\s+'));
    final Set<int> processedIndices = {}; // Отслеживаем обработанные индексы

    // Первый проход: обрабатываем флаги и их значения
    for (int i = 0; i < parts.length; i++) {
      if (processedIndices.contains(i)) continue;

      final part = parts[i];

      // Флаг -l (логин)
      if (part == '-l' && i + 1 < parts.length) {
        parsedUsername = parts[i + 1];
        processedIndices.add(i);     // Помечаем флаг как обработанный
        processedIndices.add(i + 1); // Помечаем значение как обработанное
        continue;
      }

      // Флаг -p (порт)
      if (part == '-p' && i + 1 < parts.length) {
        parsedPort = int.tryParse(parts[i + 1]) ?? 22;
        processedIndices.add(i);
        processedIndices.add(i + 1);
        continue;
      }

      // Формат user@host
      if (part.contains('@') && !part.startsWith('-')) {
        final split = part.split('@');
        if (split.length == 2) {
          parsedUsername = split[0];
          parsedHost = split[1];
          processedIndices.add(i);
        }
        continue;
      }
    }

    // Второй проход: ищем хост среди необработанных элементов
    for (int i = 0; i < parts.length; i++) {
      if (processedIndices.contains(i)) continue;

      final part = parts[i];

      // Это должен быть хост (IP или домен)
      if (!part.startsWith('-')) {
        // Проверяем что это похоже на IP или домен
        if (RegExp(r'^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$').hasMatch(part) ||
            RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$').hasMatch(part) ||
            part == 'localhost') {
          parsedHost = part;
          processedIndices.add(i);
          break; // Нашли хост, выходим
        }
      }
    }

    print('🔍 Парсинг команды: "$sshCommand"');
    print('   Username: $parsedUsername');
    print('   Host: $parsedHost');
    print('   Port: $parsedPort');

    return {
      'username': parsedUsername ?? 'root',
      'host': parsedHost ?? 'localhost',
      'port': parsedPort,
    };
  }

  String get effectiveUsername => type == ConnectionType.command
      ? parsedCommand['username']
      : username ?? 'root';

  String get effectiveHost => type == ConnectionType.command
      ? parsedCommand['host']
      : host ?? 'localhost';

  int get effectivePort => type == ConnectionType.command
      ? parsedCommand['port']
      : port ?? 22;

  Connection copyWith({
    int? id,
    int? userId,
    String? name,
    ConnectionType? type,
    String? sshCommand,
    String? host,
    int? port,
    String? username,
    String? password,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return Connection(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      sshCommand: sshCommand ?? this.sshCommand,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  @override
  String toString() {
    return 'Connection(name: $name, type: $type, '
        'effectiveUser: $effectiveUsername, '
        'effectiveHost: $effectiveHost, '
        'effectivePort: $effectivePort)';
  }
}

enum ConnectionType {
  password,
  command;

  @override
  String toString() => name;

  static ConnectionType fromString(String value) {
    return ConnectionType.values.firstWhere(
          (e) => e.toString() == value,
      orElse: () => ConnectionType.password,
    );
  }
}