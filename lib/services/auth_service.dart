import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../database/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'logger_service.dart';

class AuthService {
  final AppDatabase _database = AppDatabase();
  final _logger = LoggerService();

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<AuthResult> register(String login, String password) async {
    _logger.info('👤 Попытка регистрации пользователя: $login');

    try {
      final existingUser = await (_database.select(_database.users)
        ..where((tbl) => tbl.login.equals(login)))
          .getSingleOrNull();

      if (existingUser != null) {
        _logger.warning('⚠️ Пользователь $login уже существует');
        return AuthResult(
          success: false,
          message: 'Пользователь с таким логином уже существует',
        );
      }

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

      final hashedPassword = _hashPassword(password);

      final userId = await _database.into(_database.users).insert(
        UsersCompanion.insert(
          login: login.trim(),
          password: hashedPassword,
          createdAt: drift.Value(DateTime.now()),
        ),
      );

      _logger.logAuth('регистрация', success: true, username: login);
      _logger.logDatabase('создание пользователя', table: 'users', count: 1);

      return AuthResult(
        success: true,
        message: 'Регистрация успешна!',
        userId: userId,
      );
    } catch (e, stackTrace) {
      _logger.logAuth('регистрация', success: false, username: login, error: e.toString());
      _logger.error('Ошибка регистрации', e, stackTrace);
      return AuthResult(
        success: false,
        message: 'Ошибка регистрации: $e',
      );
    }
  }

  Future<AuthResult> login(String login, String password) async {
    _logger.info('🔐 Попытка входа: $login');

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (login.trim().isEmpty || password.isEmpty) {
        return AuthResult(
          success: false,
          message: 'Заполните все поля',
        );
      }

      final user = await (_database.select(_database.users)
        ..where((tbl) => tbl.login.equals(login.trim())))
          .getSingleOrNull();

      if (user == null) {
        _logger.logAuth('вход', success: false, username: login, error: 'Пользователь не найден');
        return AuthResult(
          success: false,
          message: 'Пользователь не найден',
        );
      }

      final hashedPassword = _hashPassword(password);

      if (user.password != hashedPassword) {
        _logger.logAuth('вход', success: false, username: login, error: 'Неверный пароль');
        return AuthResult(
          success: false,
          message: 'Неверный пароль',
        );
      }

      _logger.logAuth('вход', success: true, username: login);

      return AuthResult(
        success: true,
        message: 'Вход выполнен успешно',
        userId: user.id,
      );
    } catch (e, stackTrace) {
      _logger.logAuth('вход', success: false, username: login, error: e.toString());
      _logger.error('Ошибка авторизации', e, stackTrace);
      return AuthResult(
        success: false,
        message: 'Ошибка авторизации: $e',
      );
    }
  }

  void dispose() {
    _database.close();
  }
}

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