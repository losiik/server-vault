import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'screens/login_screen.dart';
import 'services/encryption_service.dart';
import 'services/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация логгера
  final logger = LoggerService();
  await logger.init();

  logger.info('🚀 Приложение запускается...');

  // Вывести путь к базе данных
  try {
    final dir = await getApplicationSupportDirectory();
    final dbPath = '${dir.path}/my_database.sqlite';
    logger.info('📁 База данных: $dbPath');
  } catch (e) {
    logger.error('Ошибка получения пути к БД', e);
  }

  // Тест шифрования
  try {
    final encryption = EncryptionService();
    logger.info('🔐 Тестирование шифрования...');
    final isValid = await encryption.testEncryption();
    if (isValid) {
      logger.info('✅ Шифрование работает корректно');
    } else {
      logger.error('❌ ВНИМАНИЕ: Проблема с шифрованием!');
    }
  } catch (e) {
    logger.error('Ошибка теста шифрования', e);
  }

  // Удаляем старые логи (старше 7 дней)
  await logger.deleteOldLogs(keepDays: 7);

  logger.info('✅ Инициализация завершена');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Server Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}