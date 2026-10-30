import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_vault/core/crypto/cipher_service.dart';
import 'package:offline_vault/features/credentials/credential_item.dart';
import 'package:offline_vault/features/notes/note_item.dart';

void main() {
  group('Backup & Migration Logic Tests', () {
    final cipher = CipherService();

    test('should serialize and encrypt envelope properly', () async {
      final now = DateTime.now();
      final cred = CredentialItem(
        id: 'c1',
        title: 'Google',
        username: 'user@gmail.com',
        password: 'super_secret_password',
        category: 'Email',
        createdAt: now,
        updatedAt: now,
      );

      final note = NoteItem(
        id: 'n1',
        title: 'Rencana Liburan',
        content: 'Beli tiket kereta dan sewa hotel.',
        category: 'Pribadi',
        createdAt: now,
        updatedAt: now,
      );

      final rawData = {
        'version': 1,
        'exported_at': now.millisecondsSinceEpoch,
        'credentials': [cred.toPlainMap()],
        'notes': [note.toPlainMap()],
      };

      const backupPassword = 'user_backup_password_123';
      final salt = cipher.generateRandomBytes(32);
      final backupKey =
          await cipher.deriveKeyFromPassword(backupPassword, salt);

      final encryptedPayload =
          await cipher.encryptText(jsonEncode(rawData), backupKey);

      final envelope = {
        'format': 'OFFLINE_VAULT_BACKUP',
        'version': 1,
        'salt': base64Encode(salt),
        'payload': encryptedPayload.toJson(),
      };

      final serializedEnvelope = jsonEncode(envelope);
      expect(serializedEnvelope.contains('super_secret_password'), isFalse);
      expect(serializedEnvelope.contains('OFFLINE_VAULT_BACKUP'), isTrue);

      // Decrypt on target simulated device
      final decodedEnvelope =
          jsonDecode(serializedEnvelope) as Map<String, dynamic>;
      final targetSalt = base64Decode(decodedEnvelope['salt'] as String);
      final targetPayload =
          EncryptedPayload.fromJson(decodedEnvelope['payload'] as Map<String, dynamic>);

      final targetKey =
          await cipher.deriveKeyFromPassword(backupPassword, targetSalt);
      final decryptedJson =
          await cipher.decryptText(targetPayload, targetKey);

      final restoredData = jsonDecode(decryptedJson) as Map<String, dynamic>;
      final restoredCreds = (restoredData['credentials'] as List<dynamic>)
          .map((e) => CredentialItem.fromPlainMap(e as Map<String, dynamic>))
          .toList();

      expect(restoredCreds.length, equals(1));
      expect(restoredCreds.first.title, equals('Google'));
      expect(restoredCreds.first.password, equals('super_secret_password'));
    });

    test('should reject decryption when wrong backup password is provided',
        () async {
      const backupPassword = 'correct_password';
      const wrongPassword = 'wrong_password';

      final salt = cipher.generateRandomBytes(32);
      final key = await cipher.deriveKeyFromPassword(backupPassword, salt);
      final payload = await cipher.encryptText('secret_payload', key);

      final wrongKey = await cipher.deriveKeyFromPassword(wrongPassword, salt);

      expect(
        () async => cipher.decryptText(payload, wrongKey),
        throwsA(isA<Exception>()),
      );
    });
  });
}

