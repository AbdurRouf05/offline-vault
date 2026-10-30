import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_vault/features/backup/backup_codec.dart';
import 'package:offline_vault/features/notes/note_item.dart';

void main() {
  final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
  final note = NoteItem(
    id: 'n1',
    title: 'Anime',
    content: '1.konosuba #isekai',
    category: 'Anime',
    isPinned: true,
    createdAt: now,
    updatedAt: now,
  );

  test('encode then decode returns the same notes', () {
    final content = encodeBackup([note]);

    final header = jsonDecode(content) as Map<String, dynamic>;
    expect(header['format'], backupFormat);
    expect(header['version'], 2);

    final notes = decodeBackup(content);
    expect(notes.single.toPlainMap(), note.toPlainMap());
  });

  test('non-backup files are rejected', () {
    for (final content in ['{"format":"other"}', 'not json', '[1, 2]']) {
      expect(() => decodeBackup(content), throwsFormatException);
    }
  });

  test('old version 1 files are rejected with a clear message', () {
    const v1 = '{"format":"OFFLINE_VAULT_BACKUP","version":1,"salt":"x"}';
    expect(
      () => decodeBackup(v1),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('tidak didukung'),
        ),
      ),
    );
  });

  test('a backup with a broken note is rejected as a whole', () {
    final content = jsonEncode({
      'format': backupFormat,
      'version': 2,
      'notes': [
        note.toPlainMap(),
        {'title': 'missing id'},
      ],
    });
    expect(() => decodeBackup(content), throwsFormatException);
  });
}
