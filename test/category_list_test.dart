import 'package:flutter_test/flutter_test.dart';
import 'package:offline_vault/features/categories/category_list.dart';

void main() {
  group('mergeCategories', () {
    test('keeps saved order and appends unseen used categories sorted', () {
      final result = mergeCategories(
        ['Umum', 'Pribadi'],
        ['pribadi', 'Game', 'Anime', 'Umum', ''],
      );
      expect(result, ['Umum', 'Pribadi', 'Anime', 'Game']);
    });
  });

  group('addCategory', () {
    test('trims and appends', () {
      expect(addCategory(['Umum'], '  Game '), ['Umum', 'Game']);
    });

    test('rejects empty, duplicate (any case) and "Semua"', () {
      expect(
        () => addCategory(['Umum'], '   '),
        throwsA(isA<CategoryNameException>()),
      );
      expect(
        () => addCategory(['Umum'], 'umum'),
        throwsA(isA<CategoryNameException>()),
      );
      expect(
        () => addCategory(['Umum'], 'Semua'),
        throwsA(isA<CategoryNameException>()),
      );
    });
  });

  group('renameCategory', () {
    test('replaces in place', () {
      expect(renameCategory(['A', 'B', 'C'], 'B', 'Game'), ['A', 'Game', 'C']);
    });

    test('allows changing only the letter case', () {
      expect(renameCategory(['game'], 'game', 'Game'), ['Game']);
    });

    test('rejects a name used by another category', () {
      expect(
        () => renameCategory(['A', 'B'], 'B', 'a'),
        throwsA(isA<CategoryNameException>()),
      );
    });
  });

  group('removeCategory', () {
    test('removes and keeps the fallback available', () {
      expect(removeCategory(['Game', 'Email'], 'Game', 'Lainnya'), [
        'Email',
        'Lainnya',
      ]);
      expect(removeCategory(['Umum', 'Ide'], 'Ide', 'Umum'), ['Umum']);
    });
  });
}
