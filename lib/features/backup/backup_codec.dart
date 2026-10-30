import 'dart:convert';
import 'package:offline_vault/core/crypto/cipher_service.dart';
import 'package:offline_vault/features/credentials/credential_item.dart';
import 'package:offline_vault/features/notes/note_item.dart';

/// Pure (no Flutter) encoding of the `.vault` backup format, shared by the
/// app and `tool/make_seed_vault.dart`.
const backupFormat = 'OFFLINE_VAULT_BACKUP';

typedef BackupContents = ({
  List<CredentialItem> credentials,
  List<NoteItem> notes,
});

/// Encrypts [credentials] and [notes] with a key derived from [password]
/// and returns the `.vault` file content.
Future<String> encodeBackup({
  required List<CredentialItem> credentials,
  required List<NoteItem> notes,
  required String password,
  CipherService? cipher,
}) async {
  final cipherService = cipher ?? CipherService();
  final rawJson = jsonEncode({
    'version': 1,
    'exported_at': DateTime.now().millisecondsSinceEpoch,
    'credentials': credentials.map((e) => e.toPlainMap()).toList(),
    'notes': notes.map((e) => e.toPlainMap()).toList(),
  });

  // Independent backup key: PBKDF2 with a fresh 32-byte salt.
  final salt = cipherService.generateRandomBytes(32);
  final backupKey = await cipherService.deriveKeyFromPassword(password, salt);
  final payload = await cipherService.encryptText(rawJson, backupKey);

  return jsonEncode({
    'format': backupFormat,
    'version': 1,
    'salt': base64Encode(salt),
    'payload': payload.toJson(),
  });
}

/// Decrypts `.vault` file [content]. Throws [FormatException] for a file
/// that is not a backup, and a decryption error for a wrong [password].
Future<BackupContents> decodeBackup(
  String content, {
  required String password,
  CipherService? cipher,
}) async {
  final cipherService = cipher ?? CipherService();
  final dynamic decoded = jsonDecode(content);
  if (decoded is! Map<String, dynamic> || decoded['format'] != backupFormat) {
    throw const FormatException(
      'Format file bukan cadangan Offline Vault yang sah.',
    );
  }

  final salt = base64Decode(decoded['salt'] as String);
  final payload = EncryptedPayload.fromJson(
    decoded['payload'] as Map<String, dynamic>,
  );
  final backupKey = await cipherService.deriveKeyFromPassword(password, salt);

  // A wrong password fails the AES-256-GCM authentication check here.
  final rawJson = await cipherService.decryptText(payload, backupKey);
  final data = jsonDecode(rawJson) as Map<String, dynamic>;

  return (
    credentials: [
      for (final raw in (data['credentials'] as List<dynamic>?) ?? [])
        CredentialItem.fromPlainMap(raw as Map<String, dynamic>),
    ],
    notes: [
      for (final raw in (data['notes'] as List<dynamic>?) ?? [])
        NoteItem.fromPlainMap(raw as Map<String, dynamic>),
    ],
  );
}
