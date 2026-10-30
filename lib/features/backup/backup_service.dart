import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:offline_vault/core/crypto/cipher_service.dart';
import 'package:offline_vault/core/database/database_service.dart';
import 'package:offline_vault/features/credentials/credential_item.dart';
import 'package:offline_vault/features/notes/note_item.dart';

class ImportSummary {
  final int credentialCount;
  final int noteCount;

  const ImportSummary({
    required this.credentialCount,
    required this.noteCount,
  });
}

class BackupService {
  final CipherService _cipherService;
  final DatabaseService _databaseService;

  BackupService({
    CipherService? cipherService,
    DatabaseService? databaseService,
  })  : _cipherService = cipherService ?? CipherService(),
        _databaseService = databaseService ?? DatabaseService();

  /// Export all credentials and notes to an encrypted .vault file
  Future<File> exportEncryptedBackup({
    required SecretKey activeSessionKey,
    required String backupPassword,
  }) async {
    final credentials =
        await _databaseService.getAllCredentials(activeSessionKey);
    final notes = await _databaseService.getAllNotes(activeSessionKey);

    final rawData = {
      'version': 1,
      'exported_at': DateTime.now().millisecondsSinceEpoch,
      'credentials': credentials.map((e) => e.toPlainMap()).toList(),
      'notes': notes.map((e) => e.toPlainMap()).toList(),
    };

    final rawJson = jsonEncode(rawData);

    // Derive independent backup key using PBKDF2 and a fresh 32-byte salt
    final salt = _cipherService.generateRandomBytes(32);
    final backupKey =
        await _cipherService.deriveKeyFromPassword(backupPassword, salt);

    final encryptedPayload =
        await _cipherService.encryptText(rawJson, backupKey);

    final envelope = {
      'format': 'OFFLINE_VAULT_BACKUP',
      'version': 1,
      'salt': base64Encode(salt),
      'payload': encryptedPayload.toJson(),
    };

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File(p.join(tempDir.path, 'vault_backup_$timestamp.vault'));

    await file.writeAsString(jsonEncode(envelope));
    return file;
  }

  /// Import and decrypt a .vault backup file into the local database
  Future<ImportSummary> importEncryptedBackup({
    required File backupFile,
    required String backupPassword,
    required SecretKey targetSessionKey,
  }) async {
    final content = await backupFile.readAsString();
    final dynamic decoded = jsonDecode(content);

    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != 'OFFLINE_VAULT_BACKUP') {
      throw const FormatException('Format file bukan cadangan Offline Vault yang sah.');
    }

    final salt = base64Decode(decoded['salt'] as String);
    final payloadJson = decoded['payload'] as Map<String, dynamic>;
    final payload = EncryptedPayload.fromJson(payloadJson);

    final backupKey =
        await _cipherService.deriveKeyFromPassword(backupPassword, salt);

    // If password is incorrect, AES-256-GCM authentication tag check fails here
    final rawJson = await _cipherService.decryptText(payload, backupKey);
    final data = jsonDecode(rawJson) as Map<String, dynamic>;

    final rawCredentials = (data['credentials'] as List<dynamic>?) ?? [];
    final rawNotes = (data['notes'] as List<dynamic>?) ?? [];

    var credCount = 0;
    for (final raw in rawCredentials) {
      final item = CredentialItem.fromPlainMap(raw as Map<String, dynamic>);
      await _databaseService.saveCredential(item, targetSessionKey);
      credCount++;
    }

    var noteCount = 0;
    for (final raw in rawNotes) {
      final item = NoteItem.fromPlainMap(raw as Map<String, dynamic>);
      await _databaseService.saveNote(item, targetSessionKey);
      noteCount++;
    }

    return ImportSummary(
      credentialCount: credCount,
      noteCount: noteCount,
    );
  }
}

