import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final _secureStorage = const FlutterSecureStorage();
  static const _keyStorageKey = 'encryption_master_key';

  Key? _cachedKey;

  /// Получить или создать мастер-ключ
  Future<Key> _getMasterKey() async {
    if (_cachedKey != null) return _cachedKey!;

    // Пытаемся загрузить существующий ключ
    String? storedKey = await _secureStorage.read(key: _keyStorageKey);

    if (storedKey != null) {
      // Декодируем base64 в байты
      final keyBytes = base64.decode(storedKey);
      _cachedKey = Key(Uint8List.fromList(keyBytes));
      print('🔑 Загружен существующий мастер-ключ');
      return _cachedKey!;
    }

    // Генерируем новый ключ (256 бит = 32 байта)
    final key = Key.fromSecureRandom(32);

    // Сохраняем в безопасное хранилище
    await _secureStorage.write(
      key: _keyStorageKey,
      value: base64.encode(key.bytes),
    );

    _cachedKey = key;
    print('🔐 Создан новый мастер-ключ');
    return key;
  }

  /// Зашифровать пароль
  Future<String?> encryptPassword(String? password) async {
    if (password == null || password.isEmpty) return null;

    try {
      final key = await _getMasterKey();
      final iv = IV.fromSecureRandom(16); // 128-bit IV для GCM

      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      final encrypted = encrypter.encrypt(password, iv: iv);

      // Формат: IV:зашифрованные_данные:MAC
      final result = '${iv.base64}:${encrypted.base64}';

      print('🔒 Пароль зашифрован (длина: ${result.length})');
      return result;
    } catch (e) {
      print('❌ Ошибка шифрования: $e');
      return null;
    }
  }

  /// Расшифровать пароль
  Future<String?> decryptPassword(String? encryptedPassword) async {
    if (encryptedPassword == null || encryptedPassword.isEmpty) return null;

    try {
      // Парсим формат: IV:зашифрованные_данные
      final parts = encryptedPassword.split(':');
      if (parts.length != 2) {
        print('⚠️ Неверный формат зашифрованного пароля');
        return null;
      }

      final key = await _getMasterKey();
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);

      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      final decrypted = encrypter.decrypt(encrypted, iv: iv);

      print('🔓 Пароль расшифрован');
      return decrypted;
    } catch (e) {
      print('❌ Ошибка расшифровки: $e');
      return null;
    }
  }

  /// Проверить работоспособность шифрования
  Future<bool> testEncryption() async {
    try {
      const testPassword = 'test_password_123';
      final encrypted = await encryptPassword(testPassword);
      if (encrypted == null) return false;

      final decrypted = await decryptPassword(encrypted);
      final isValid = decrypted == testPassword;

      print(isValid ? '✅ Тест шифрования пройден' : '❌ Тест шифрования провален');
      return isValid;
    } catch (e) {
      print('❌ Ошибка теста шифрования: $e');
      return false;
    }
  }

  /// Сбросить мастер-ключ
  Future<void> resetMasterKey() async {
    await _secureStorage.delete(key: _keyStorageKey);
    _cachedKey = null;
    print('🗑️ Мастер-ключ удален');
  }
}