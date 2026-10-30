import 'dart:convert';
import 'package:offline_vault/features/notes/note_item.dart';

/// Pure (no Flutter) encoding of the `.vault` backup format, shared by the
/// app and `tool/make_seed_vault.dart`. Version 2 is plain JSON without a
/// password (ADR 0002); version 1 files are not supported.
const backupFormat = 'OFFLINE_VAULT_BACKUP';
const backupVersion = 2;

/// Returns the `.vault` file content for [notes].
String encodeBackup(List<NoteItem> notes, {DateTime? exportedAt}) {
  return const JsonEncoder.withIndent('  ').convert({
    'format': backupFormat,
    'version': backupVersion,
    'exported_at': (exportedAt ?? DateTime.now()).millisecondsSinceEpoch,
    'notes': notes.map((e) => e.toPlainMap()).toList(),
  });
}

/// Reads `.vault` file [content]. Throws [FormatException] for anything
/// that is not a complete version 2 backup, so nothing is imported from a
/// broken or foreign file.
List<NoteItem> decodeBackup(String content) {
  final Object? decoded;
  try {
    decoded = jsonDecode(content);
  } on FormatException {
    throw const FormatException('File ini bukan cadangan Offline Vault.');
  }
  if (decoded is! Map<String, dynamic> || decoded['format'] != backupFormat) {
    throw const FormatException('File ini bukan cadangan Offline Vault.');
  }
  if (decoded['version'] != backupVersion) {
    throw const FormatException(
      'Versi file cadangan ini tidak didukung. Ekspor ulang dari aplikasi '
      'versi terbaru.',
    );
  }

  try {
    return [
      for (final raw in decoded['notes'] as List<dynamic>)
        NoteItem.fromPlainMap(raw as Map<String, dynamic>),
    ];
  } on TypeError {
    throw const FormatException('Isi file cadangan rusak.');
  }
}
