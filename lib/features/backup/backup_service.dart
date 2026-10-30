import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:offline_vault/core/crypto/cipher_service.dart';
import 'package:offline_vault/core/database/database_service.dart';
import 'package:offline_vault/features/backup/backup_codec.dart';

class ImportSummary {
  final int noteCount;

  const ImportSummary({required this.noteCount});
}

class BackupService {
  final CipherService _cipherService;
  final DatabaseService _databaseService;

  BackupService({
    CipherService? cipherService,
    DatabaseService? databaseService,
  }) : _cipherService = cipherService ?? CipherService(),
       _databaseService = databaseService ?? DatabaseService();

  /// Export all notes to an encrypted .vault file
  Future<File> exportEncryptedBackup({
    required SecretKey activeSessionKey,
    required String backupPassword,
  }) async {
    final content = await encodeBackup(
      notes: await _databaseService.getAllNotes(activeSessionKey),
      password: backupPassword,
      cipher: _cipherService,
    );

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File(p.join(tempDir.path, 'vault_backup_$timestamp.vault'));

    await file.writeAsString(content);
    return file;
  }

  /// Import and decrypt a .vault backup file into the local database
  Future<ImportSummary> importEncryptedBackup({
    required File backupFile,
    required String backupPassword,
    required SecretKey targetSessionKey,
  }) async {
    final notes = await decodeBackup(
      await backupFile.readAsString(),
      password: backupPassword,
      cipher: _cipherService,
    );

    for (final item in notes) {
      await _databaseService.saveNote(item, targetSessionKey);
    }

    return ImportSummary(noteCount: notes.length);
  }
}
