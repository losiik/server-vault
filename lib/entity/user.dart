class User {
  late String id;
  final String login;
  final String password;

  User({
    required this.id,
    required this.login,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'login': login,
      'password': password
    };
  }

  /// Создание из Map (для загрузки из БД или JSON)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      login: json['login'] as String,
      password: json['password'] as String
    );
  }
}