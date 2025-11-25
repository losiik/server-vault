import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  Logger? _logger;
  File? _logFile;
  String? _logFilePath;

  /// Инициализация логгера
  Future<void> init() async {
    try {
      // Получаем директорию для логов
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory(path.join(directory.path, 'logs'));

      // Создаем директорию если не существует
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      // Создаем файл лога с датой
      final timestamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _logFilePath = path.join(logsDir.path, 'app_$timestamp.log');
      _logFile = File(_logFilePath!);

      // Создаем логгер с кастомным выводом
      _logger = Logger(
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 80,
          colors: true,
          printEmojis: true,
          printTime: true,
        ),
        output: MultiOutput([
          ConsoleOutput(),
          FileOutput(file: _logFile!),
        ]),
      );

      _logger!.i('═══════════════════════════════════════════════════════');
      _logger!.i('📝 Логирование инициализировано');
      _logger!.i('📁 Файл логов: $_logFilePath');
      _logger!.i('⏰ Время запуска: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
      _logger!.i('═══════════════════════════════════════════════════════');
    } catch (e) {
      print('❌ Ошибка инициализации логгера: $e');
    }
  }

  // Уровни логирования
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.d(message, error: error, stackTrace: stackTrace);
  }

  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.i(message, error: error, stackTrace: stackTrace);
  }

  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.w(message, error: error, stackTrace: stackTrace);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.e(message, error: error, stackTrace: stackTrace);
  }

  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.f(message, error: error, stackTrace: stackTrace);
  }

  // Специализированные методы логирования
  void logAuth(String action, {required bool success, String? username, String? error}) {
    final emoji = success ? '✅' : '❌';
    final status = success ? 'успешно' : 'ошибка';
    final msg = '$emoji Авторизация: $action - $status${username != null ? " (пользователь: $username)" : ""}';

    if (success) {
      info(msg);
    } else {
      error!;
    }
  }

  void logConnection(String action, {required String name, String? host, String? username, String? error}) {
    final msg = '🔌 Подключение "$name": $action${host != null ? " ($username@$host)" : ""}';

    if (error == null) {
      info(msg);
    } else {
      this.error(msg, error);
    }
  }

  void logDatabase(String action, {String? table, int? count, String? error}) {
    final msg = '💾 База данных: $action${table != null ? " (таблица: $table)" : ""}${count != null ? " (записей: $count)" : ""}';

    if (error == null) {
      debug(msg);
    } else {
      this.error(msg, error);
    }
  }

  void logEncryption(String action, {required bool success, String? error}) {
    final emoji = success ? '🔒' : '❌';
    final msg = '$emoji Шифрование: $action';

    if (success) {
      debug(msg);
    } else {
      this.error(msg, error);
    }
  }

  void logSSH(String action, {String? host, int? port, String? username, String? error}) {
    final msg = '🖥️ SSH: $action${host != null ? " ($username@$host:$port)" : ""}';

    if (error == null) {
      info(msg);
    } else {
      this.error(msg, error);
    }
  }

  /// Получить путь к файлу логов
  String? get logFilePath => _logFilePath;

  /// Получить содержимое логов
  Future<String> getLogsContent() async {
    if (_logFile == null || !await _logFile!.exists()) {
      return 'Логи не найдены';
    }
    return await _logFile!.readAsString();
  }

  /// Очистить логи
  Future<void> clearLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.delete();
      await init(); // Пересоздаем файл
      info('🗑️ Логи очищены');
    }
  }

  /// Получить список всех файлов логов
  Future<List<File>> getAllLogFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory(path.join(directory.path, 'logs'));

      if (!await logsDir.exists()) return [];

      return logsDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.log'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path)); // Сортируем по дате (новые первые)
    } catch (e) {
      error('Ошибка получения списка логов', e);
      return [];
    }
  }

  /// Удалить старые логи (оставить только последние N дней)
  Future<void> deleteOldLogs({int keepDays = 7}) async {
    try {
      final files = await getAllLogFiles();
      final now = DateTime.now();

      for (final file in files) {
        final stat = await file.stat();
        final age = now.difference(stat.modified).inDays;

        if (age > keepDays) {
          await file.delete();
          info('🗑️ Удален старый лог: ${path.basename(file.path)} (возраст: $age дней)');
        }
      }
    } catch (e) {
      error('Ошибка удаления старых логов', e);
    }
  }
}

/// Вывод логов в консоль
class ConsoleOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      if (kDebugMode) {
        print(line);
      }
    }
  }
}

/// Вывод логов в файл
class FileOutput extends LogOutput {
  final File file;

  FileOutput({required this.file});

  @override
  void output(OutputEvent event) {
    try {
      final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
      for (var line in event.lines) {
        // Убираем ANSI escape коды для файла
        final cleanLine = line.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
        file.writeAsStringSync('[$timestamp] $cleanLine\n', mode: FileMode.append);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Ошибка записи в лог файл: $e');
      }
    }
  }
}