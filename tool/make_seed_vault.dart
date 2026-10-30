// Builds an encrypted `.vault` backup from seed JSON, to load data into the
// app through Pengaturan > Impor. Never commit seed data or the output.
//
// Usage (seed JSON on stdin, backup password in an env variable):
//   SEED_VAULT_PASSWORD=... dart run tool/make_seed_vault.dart build/seed.vault < seed.json
//
// Seed JSON:
//   {"notes": [{"title", "content", "category", "is_pinned"}]}
// Only "title" is required.
import 'dart:convert';
import 'dart:io';
import 'package:offline_vault/features/backup/backup_codec.dart';
import 'package:offline_vault/features/notes/note_item.dart';
import 'package:uuid/uuid.dart';

Future<void> main(List<String> args) async {
  final password = Platform.environment['SEED_VAULT_PASSWORD'] ?? '';
  if (args.length != 1 || password.isEmpty) {
    stderr.writeln(
      'Usage: SEED_VAULT_PASSWORD=... '
      'dart run tool/make_seed_vault.dart <out.vault> < seed.json',
    );
    exitCode = 64;
    return;
  }

  final seed =
      jsonDecode(await stdin.transform(utf8.decoder).join())
          as Map<String, dynamic>;
  final now = DateTime.now();
  String str(Map<String, dynamic> m, String key, [String fallback = '']) =>
      (m[key] as String?) ?? fallback;

  final notes = [
    for (final raw in (seed['notes'] as List<dynamic>?) ?? [])
      if (raw case final Map<String, dynamic> m)
        NoteItem(
          id: const Uuid().v4(),
          title: str(m, 'title'),
          content: str(m, 'content'),
          category: str(m, 'category', 'Umum'),
          isPinned: m['is_pinned'] == true,
          createdAt: now,
          updatedAt: now,
        ),
  ];

  final content = await encodeBackup(notes: notes, password: password);
  await File(args.single).writeAsString(content);
  stdout.writeln('Wrote ${args.single}: ${notes.length} notes.');
}
