import 'package:flutter_test/flutter_test.dart';
import 'package:offline_vault/core/crypto/cipher_service.dart';

void main() {
  group('CipherService Tests', () {
    final cipher = CipherService();

    test('should encrypt and decrypt string accurately with AES-256-GCM',
        () async {
      final salt = cipher.generateRandomBytes(32);
      final key = await cipher.deriveKeyFromPassword('my_secret_master_pin_123456', salt);

      const secretText = 'P@ssw0rdRahasiaSuperKuat!';
      final encrypted = await cipher.encryptText(secretText, key);

      // Ensure ciphertext is serialized and not plain
      expect(encrypted.cipherTextBase64.isNotEmpty, isTrue);
      expect(encrypted.cipherTextBase64, isNot(equals(secretText)));

      final decrypted = await cipher.decryptText(encrypted, key);
      expect(decrypted, equals(secretText));
    });

    test('should fail decryption if wrong password key is used', () async {
      final salt = cipher.generateRandomBytes(32);
      final key1 = await cipher.deriveKeyFromPassword('correct_pin', salt);
      final key2 = await cipher.deriveKeyFromPassword('wrong_pin', salt);

      const secretText = 'Data Rahasia';
      final encrypted = await cipher.encryptText(secretText, key1);

      expect(
        () async => cipher.decryptText(encrypted, key2),
        throwsA(isA<Exception>()),
      );
    });

    test('should generate password according to constraints', () {
      final pwd = cipher.generatePassword(length: 20);
      expect(pwd.length, equals(20));
    });
  });
}

