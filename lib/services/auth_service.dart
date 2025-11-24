import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../database/app_database.dart';
import 'package:drift/drift.dart' as drift;

class AuthService {
  final AppDatabase _database = AppDatabase();

  /// Хеширование пароля для безопасного хранения
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Регистрация нового пользователя
  Future<AuthResult> register(String login, String password) async {
    try {
      // Проверяем, существует ли пользователь с таким логином
      final existingUser = await (_database.select(_database.users)
        ..where((tbl) => tbl.login.equals(login)))
          .getSingleOrNull();

      if (existingUser != null) {
        return AuthResult(
          success: false,
          message: 'Пользователь с таким логином уже существует',
        );
      }

      // Проверка валидности данных
      if (login.trim().isEmpty) {
        return AuthResult(
          success: false,
          message: 'Логин не может быть пустым',
        );
      }

      if (password.length < 4) {
        return AuthResult(
          success: false,
          message: 'Пароль должен содержать минимум 4 символа',
        );
      }

      // Хешируем пароль для безопасного хранения
      final hashedPassword = _hashPassword(password);

      // Создаем нового пользователя
      await _database.into(_database.users).insert(
        UsersCompanion.insert(
          login: login.trim(),
          password: hashedPassword,
          createdAt: drift.Value(DateTime.now()),
        ),
      );

      return AuthResult(
        success: true,
        message: 'Регистрация успешна!',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Ошибка регистрации: $e',
      );
    }
  }

  /// Авторизация пользователя
  Future<AuthResult> login(String login, String password) async {
    try {
      // Имитация задержки (как на реальном сервере)
      await Future.delayed(const Duration(milliseconds: 500));

      // Проверка на пустые поля
      if (login.trim().isEmpty || password.isEmpty) {
        return AuthResult(
          success: false,
          message: 'Заполните все поля',
        );
      }

      // Ищем пользователя по логину
      final user = await (_database.select(_database.users)
        ..where((tbl) => tbl.login.equals(login.trim())))
          .getSingleOrNull();

      if (user == null) {
        return AuthResult(
          success: false,
          message: 'Пользователь не найден',
        );
      }

      // Хешируем введенный пароль и сравниваем с сохраненным
      final hashedPassword = _hashPassword(password);

      if (user.password != hashedPassword) {
        return AuthResult(
          success: false,
          message: 'Неверный пароль',
        );
      }

      return AuthResult(
        success: true,
        message: 'Вход выполнен успешно',
        userId: user.id,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Ошибка авторизации: $e',
      );
    }
  }

  /// Проверка существования пользователя
  Future<bool> userExists(String login) async {
    final user = await (_database.select(_database.users)
      ..where((tbl) => tbl.login.equals(login.trim())))
        .getSingleOrNull();
    return user != null;
  }

  /// Получить всех пользователей (для отладки)
  Future<List<User>> getAllUsers() async {
    return await _database.select(_database.users).get();
  }

  /// Удалить пользователя (для отладки)
  Future<void> deleteUser(int userId) async {
    await (_database.delete(_database.users)
      ..where((tbl) => tbl.id.equals(userId)))
        .go();
  }

  /// Закрыть соединение с базой данных
  void dispose() {
    _database.close();
  }
}

/// Класс результата авторизации/регистрации
class AuthResult {
  final bool success;
  final String message;
  final int? userId;

  AuthResult({
    required this.success,
    required this.message,
    this.userId,
  });
}