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

  test('encode then decode returns the same items', () async {
    final content = await encodeBackup(notes: [note], password: 'pw-123');
    expect(content.contains('konosuba'), isFalse);

    final notes = await decodeBackup(content, password: 'pw-123');
    expect(notes.single.toPlainMap(), note.toPlainMap());
  });

  test('wrong password fails to decode', () async {
    final content = await encodeBackup(notes: [note], password: 'right');
    expect(decodeBackup(content, password: 'wrong'), throwsA(anything));
  });

  test('non-backup file is rejected', () async {
    expect(
      decodeBackup('{"format":"other"}', password: 'x'),
      throwsA(isA<FormatException>()),
    );
  });
}
