/// Which item type a category list belongs to.
enum CategoryScope {
  notes(
    table: 'notes',
    metadataKey: 'categories_notes',
    fallback: 'Umum',
    defaults: ['Umum', 'Pribadi', 'Pekerjaan', 'Ide', 'Keuangan', 'Penting'],
  );

  const CategoryScope({
    required this.table,
    required this.metadataKey,
    required this.fallback,
    required this.defaults,
  });

  final String table;
  final String metadataKey;

  /// Category that items move to when their category is deleted.
  final String fallback;
  final List<String> defaults;
}

/// Thrown when a category name is empty or already taken.
class CategoryNameException implements Exception {
  final String message;
  const CategoryNameException(this.message);

  @override
  String toString() => message;
}

/// Saved categories first (in user order), then any category used by items
/// but not saved yet (e.g. from an imported backup), sorted.
List<String> mergeCategories(List<String> saved, Iterable<String> used) {
  final result = [...saved];
  final extra =
      used
          .where((c) => c.trim().isNotEmpty && !_contains(result, c))
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return result..addAll(extra);
}

List<String> addCategory(List<String> list, String name) {
  final clean = _validate(list, name);
  return [...list, clean];
}

List<String> renameCategory(List<String> list, String from, String to) {
  final others = list.where((c) => c != from).toList();
  final clean = _validate(others, to);
  return list.map((c) => c == from ? clean : c).toList();
}

/// Removes [name]; makes sure [fallback] exists since items move there.
List<String> removeCategory(List<String> list, String name, String fallback) {
  final result = list.where((c) => c != name).toList();
  if (!result.contains(fallback)) result.add(fallback);
  return result;
}

String _validate(List<String> existing, String name) {
  final clean = name.trim();
  if (clean.isEmpty) {
    throw const CategoryNameException('Nama kategori tidak boleh kosong.');
  }
  if (clean.toLowerCase() == 'semua') {
    throw const CategoryNameException('Nama "Semua" dipakai untuk filter.');
  }
  if (_contains(existing, clean)) {
    throw CategoryNameException('Kategori "$clean" sudah ada.');
  }
  return clean;
}

bool _contains(List<String> list, String name) =>
    list.any((c) => c.toLowerCase() == name.trim().toLowerCase());
