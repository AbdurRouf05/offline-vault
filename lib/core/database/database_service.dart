import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:offline_vault/core/crypto/cipher_service.dart';
import 'package:offline_vault/features/notes/note_item.dart';

class DatabaseService {
  Database? _db;
  final CipherService _cipherService;

  DatabaseService({CipherService? cipherService})
    : _cipherService = cipherService ?? CipherService();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'offline_vault.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            category TEXT DEFAULT 'general',
            is_pinned INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE app_metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // --- NOTES CRUD ---

  Future<void> saveNote(NoteItem item, SecretKey key) async {
    final db = await database;

    final encContent = await _cipherService.encryptText(item.content, key);

    await db.insert('notes', {
      'id': item.id,
      'title': item.title,
      'content': encContent.serialize(),
      'category': item.category,
      'is_pinned': item.isPinned ? 1 : 0,
      'created_at': item.createdAt.millisecondsSinceEpoch,
      'updated_at': item.updatedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<NoteItem>> getAllNotes(SecretKey key) async {
    final db = await database;
    final rows = await db.query(
      'notes',
      orderBy: 'is_pinned DESC, updated_at DESC',
    );

    final results = <NoteItem>[];
    for (final row in rows) {
      try {
        final encContent = EncryptedPayload.deserialize(
          row['content'] as String,
        );
        final content = await _cipherService.decryptText(encContent, key);

        results.add(
          NoteItem(
            id: row['id'] as String,
            title: row['title'] as String,
            content: content,
            category: (row['category'] as String?) ?? 'general',
            isPinned: (row['is_pinned'] as int? ?? 0) == 1,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row['created_at'] as int,
            ),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              row['updated_at'] as int,
            ),
          ),
        );
      } catch (_) {
        // Skip corrupted item
      }
    }
    return results;
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // --- METADATA ---

  Future<String?> getMetadata(String key) async {
    final db = await database;
    final rows = await db.query(
      'app_metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setMetadata(String key, String value) async {
    final db = await database;
    await db.insert('app_metadata', {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Move every row in [table] from category [from] to [to].
  /// [table] must be one of the app's own table names, never user input.
  Future<void> moveCategory(String table, String from, String to) async {
    assert(table == 'notes');
    final db = await database;
    await db.update(
      table,
      {'category': to},
      where: 'category = ?',
      whereArgs: [from],
    );
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('notes');
  }
}
