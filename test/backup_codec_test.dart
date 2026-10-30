import 'package:flutter_test/flutter_test.dart';
import 'package:offline_vault/features/backup/backup_codec.dart';
import 'package:offline_vault/features/credentials/credential_item.dart';
import 'package:offline_vault/features/notes/note_item.dart';

void main() {
  final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
  final cred = CredentialItem(
    id: 'c1',
    title: 'Steam',
    username: 'player',
    password: 'hunter2-secret',
    category: 'Game',
    createdAt: now,
    updatedAt: now,
  );
  final note = NoteItem(
    id: 'n1',
    title: 'Anime',
    content: '1.konosuba #isekai',
    category: 'Anime',
    isPinned: true,
    createdAt: now,
    updatedAt: now,
  );

  test('encode then decode returns the same items', () async {
    final content = await encodeBackup(
      credentials: [cred],
      notes: [note],
      password: 'pw-123',
    );
    expect(content.contains('hunter2-secret'), isFalse);

    final backup = await decodeBackup(content, password: 'pw-123');
    expect(backup.credentials.single.toPlainMap(), cred.toPlainMap());
    expect(backup.notes.single.toPlainMap(), note.toPlainMap());
  });

  test('wrong password fails to decode', () async {
    final content = await encodeBackup(
      credentials: [cred],
      notes: const [],
      password: 'right',
    );
    expect(decodeBackup(content, password: 'wrong'), throwsA(anything));
  });

  test('non-backup file is rejected', () async {
    expect(
      decodeBackup('{"format":"other"}', password: 'x'),
      throwsA(isA<FormatException>()),
    );
  });
}
