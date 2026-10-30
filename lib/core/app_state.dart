import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_vault/core/database/database_service.dart';
import 'package:offline_vault/core/security/data_key_service.dart';
import 'package:offline_vault/features/backup/backup_service.dart';
import 'package:offline_vault/features/notes/note_item.dart';

final dataKeyServiceProvider = Provider<DataKeyService>((ref) {
  return DataKeyService();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(databaseService: ref.watch(databaseServiceProvider));
});

/// Key that encrypts notes at rest, loaded (or created) once at startup.
final dataKeyProvider = FutureProvider<SecretKey>((ref) {
  return ref.watch(dataKeyServiceProvider).loadOrCreateKey();
});

class NotesNotifier extends AsyncNotifier<List<NoteItem>> {
  @override
  Future<List<NoteItem>> build() async {
    final key = await ref.watch(dataKeyProvider.future);
    final db = ref.watch(databaseServiceProvider);
    return await db.getAllNotes(key);
  }

  Future<void> addOrUpdate(NoteItem item) async {
    final key = await ref.read(dataKeyProvider.future);
    final db = ref.read(databaseServiceProvider);
    await db.saveNote(item, key);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    final db = ref.read(databaseServiceProvider);
    await db.deleteNote(id);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<NoteItem>>(
  NotesNotifier.new,
);
