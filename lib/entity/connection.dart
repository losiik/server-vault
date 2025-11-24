class Connection {
  final int? id;
  final int userId;
  final String name;
  final String host;
  final int port;
  final String username;
  final AuthType authType;

  // Для авторизации по паролю
  final String? password;

  // Для авторизации по ключу (загруженному)
  final String? privateKey;
  final String? publicKey;
  final String? passphrase;

  // Для системного ключа
  final String? systemKeyPath;

  final DateTime? createdAt;
  final DateTime? lastUsed;

  Connection({
    this.id,
    required this.userId,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.authType,
    this.password,
    this.privateKey,
    this.publicKey,
    this.passphrase,
    this.systemKeyPath,
    this.createdAt,
    this.lastUsed,
  });

  Connection copyWith({
    int? id,
    int? userId,
    String? name,
    String? host,
    int? port,
    String? username,
    AuthType? authType,
    String? password,
    String? privateKey,
    String? publicKey,
    String? passphrase,
    String? systemKeyPath,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return Connection(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      authType: authType ?? this.authType,
      password: password ?? this.password,
      privateKey: privateKey ?? this.privateKey,
      publicKey: publicKey ?? this.publicKey,
      passphrase: passphrase ?? this.passphrase,
      systemKeyPath: systemKeyPath ?? this.systemKeyPath,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'authType': authType.toString(),
      'password': password,
      'privateKey': privateKey,
      'publicKey': publicKey,
      'passphrase': passphrase,
      'systemKeyPath': systemKeyPath,
      'createdAt': createdAt?.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Connection(id: $id, name: $name, host: $host:$port, username: $username, authType: $authType)';
  }
}

enum AuthType {
  password,      // Авторизация по паролю
  key,          // Авторизация по загруженному ключу
  systemKey;    // ⬅️ НОВОЕ: Авторизация по системному ключу

  @override
  String toString() => name;

  static AuthType fromString(String value) {
    return AuthType.values.firstWhere(
          (e) => e.toString() == value,
      orElse: () => AuthType.password,
    );
  }
}