import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_vault/core/app_state.dart';
import 'package:offline_vault/features/categories/category_list.dart';

/// User-editable category list for one [CategoryScope], persisted in
/// `app_metadata` and merged with categories already used by items.
class CategoriesNotifier extends AsyncNotifier<List<String>> {
  CategoriesNotifier(this.scope);

  final CategoryScope scope;

  @override
  Future<List<String>> build() async {
    final used = switch (scope) {
      CategoryScope.notes => (await ref.watch(
        notesProvider.future,
      )).map((n) => n.category),
    };
    return mergeCategories(await _loadSaved(), used);
  }

  /// Throws [CategoryNameException] if [name] is invalid.
  Future<void> add(String name) async {
    final updated = addCategory(await future, name);
    await _save(updated);
    state = AsyncData(updated);
  }

  /// Renames the category and moves every item that used it.
  Future<void> rename(String from, String to) async {
    final updated = renameCategory(await future, from, to);
    await ref
        .read(databaseServiceProvider)
        .moveCategory(scope.table, from, to.trim());
    await _save(updated);
    _refreshItems();
  }

  /// Deletes the category; its items move to [CategoryScope.fallback].
  Future<void> remove(String name) async {
    final updated = removeCategory(await future, name, scope.fallback);
    await ref
        .read(databaseServiceProvider)
        .moveCategory(scope.table, name, scope.fallback);
    await _save(updated);
    _refreshItems();
  }

  Future<List<String>> _loadSaved() async {
    final raw = await ref
        .read(databaseServiceProvider)
        .getMetadata(scope.metadataKey);
    if (raw == null) return scope.defaults;
    return (jsonDecode(raw) as List<dynamic>).cast<String>();
  }

  Future<void> _save(List<String> list) => ref
      .read(databaseServiceProvider)
      .setMetadata(scope.metadataKey, jsonEncode(list));

  void _refreshItems() {
    switch (scope) {
      case CategoryScope.notes:
        ref.invalidate(notesProvider);
    }
  }
}

final noteCategoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<String>>(
      () => CategoriesNotifier(CategoryScope.notes),
    );

AsyncNotifierProvider<CategoriesNotifier, List<String>> categoriesProviderFor(
  CategoryScope scope,
) => switch (scope) {
  CategoryScope.notes => noteCategoriesProvider,
};
