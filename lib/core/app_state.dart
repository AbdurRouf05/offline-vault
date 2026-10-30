import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_vault/core/database/database_service.dart';
import 'package:offline_vault/core/security/security_service.dart';
import 'package:offline_vault/features/backup/backup_service.dart';
import 'package:offline_vault/features/credentials/credential_item.dart';
import 'package:offline_vault/features/notes/note_item.dart';

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

class SessionKeyNotifier extends Notifier<SecretKey?> {
  @override
  SecretKey? build() => null;

  void setKey(SecretKey? key) {
    state = key;
  }
}

final sessionKeyProvider = NotifierProvider<SessionKeyNotifier, SecretKey?>(
  SessionKeyNotifier.new,
);

class CredentialsNotifier extends AsyncNotifier<List<CredentialItem>> {
  @override
  Future<List<CredentialItem>> build() async {
    final key = ref.watch(sessionKeyProvider);
    final db = ref.watch(databaseServiceProvider);
    if (key == null) return [];
    return await db.getAllCredentials(key);
  }

  Future<void> addOrUpdate(CredentialItem item) async {
    final key = ref.read(sessionKeyProvider);
    final db = ref.read(databaseServiceProvider);
    if (key == null) return;
    await db.saveCredential(item, key);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    final db = ref.read(databaseServiceProvider);
    await db.deleteCredential(id);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final credentialsProvider =
    AsyncNotifierProvider<CredentialsNotifier, List<CredentialItem>>(
      CredentialsNotifier.new,
    );

class NotesNotifier extends AsyncNotifier<List<NoteItem>> {
  @override
  Future<List<NoteItem>> build() async {
    final key = ref.watch(sessionKeyProvider);
    final db = ref.watch(databaseServiceProvider);
    if (key == null) return [];
    return await db.getAllNotes(key);
  }

  Future<void> addOrUpdate(NoteItem item) async {
    final key = ref.read(sessionKeyProvider);
    final db = ref.read(databaseServiceProvider);
    if (key == null) return;
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
