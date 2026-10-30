import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:offline_vault/core/database/database_service.dart';
import 'package:offline_vault/features/backup/backup_codec.dart';

class ImportSummary {
  final int noteCount;

  const ImportSummary({required this.noteCount});
}

class BackupService {
  final DatabaseService _databaseService;

  BackupService({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService();

  /// Writes all notes to a `.vault` file in the temp directory.
  Future<File> exportBackup({required SecretKey dataKey}) async {
    final content = encodeBackup(await _databaseService.getAllNotes(dataKey));

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File(p.join(tempDir.path, 'catatan_$timestamp.vault'));

    await file.writeAsString(content);
    return file;
  }

  /// Reads [backupFile] and saves its notes; a note with the same id is
  /// replaced. Throws [FormatException] before saving anything if the file
  /// is not a valid backup.
  Future<ImportSummary> importBackup({
    required File backupFile,
    required SecretKey dataKey,
  }) async {
    final notes = decodeBackup(await backupFile.readAsString());

    for (final item in notes) {
      await _databaseService.saveNote(item, dataKey);
    }

    return ImportSummary(noteCount: notes.length);
  }
}
