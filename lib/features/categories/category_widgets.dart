import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_vault/core/theme/app_theme.dart';
import 'package:offline_vault/features/categories/categories_provider.dart';
import 'package:offline_vault/features/categories/category_list.dart';
import 'package:offline_vault/features/categories/category_manager_screen.dart';
import 'package:offline_vault/features/categories/category_name_dialog.dart';

/// Value shown by [CategoryFilterBar] for "no filter".
const allCategories = 'Semua';

/// Horizontal filter chips ("Semua" + categories) with a button that opens
/// [CategoryManagerScreen].
class CategoryFilterBar extends ConsumerWidget {
  final CategoryScope scope;
  final String selected;
  final ValueChanged<String> onSelected;

  const CategoryFilterBar({
    super.key,
    required this.scope,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories =
        ref.watch(categoriesProviderFor(scope)).value ?? const <String>[];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          for (final cat in [allCategories, ...categories])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(cat),
                selected: selected == cat,
                selectedColor: AppColors.lightAccent.withValues(alpha: 0.2),
                checkmarkColor: AppColors.lightAccent,
                onSelected: (_) => onSelected(cat),
              ),
            ),
          ActionChip(
            avatar: const Icon(Icons.tune, size: 18),
            label: const Text('Kelola'),
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => CategoryManagerScreen(scope: scope),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Category dropdown for item forms, with an option to create a new
/// category on the spot.
class CategoryDropdown extends ConsumerStatefulWidget {
  final CategoryScope scope;
  final String value;
  final ValueChanged<String> onChanged;

  const CategoryDropdown({
    super.key,
    required this.scope,
    required this.value,
    required this.onChanged,
  });

  @override
  ConsumerState<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends ConsumerState<CategoryDropdown> {
  static const _newCategory = '__new_category__';

  // Bumped to rebuild the field so it shows widget.value again after the
  // "new category" dialog is cancelled.
  int _revision = 0;

  Future<void> _createCategory() async {
    final provider = categoriesProviderFor(widget.scope);
    final created = await showCategoryNameDialog(
      context,
      title: 'Kategori Baru',
      onSubmit: ref.read(provider.notifier).add,
    );
    if (created != null) widget.onChanged(created);
    if (mounted) setState(() => _revision++);
  }

  @override
  Widget build(BuildContext context) {
    final saved =
        ref.watch(categoriesProviderFor(widget.scope)).value ??
        widget.scope.defaults;
    final value = widget.value;
    final options = saved.contains(value) ? saved : [...saved, value];

    return DropdownButtonFormField<String>(
      key: ValueKey('$value#$_revision'),
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Kategori',
        prefixIcon: Icon(Icons.label_outline),
      ),
      items: [
        for (final cat in options)
          DropdownMenuItem(value: cat, child: Text(cat)),
        const DropdownMenuItem(
          value: _newCategory,
          child: Text(
            '+ Kategori baru',
            style: TextStyle(color: AppColors.lightAccent),
          ),
        ),
      ],
      onChanged: (val) {
        if (val == null) return;
        if (val == _newCategory) {
          _createCategory();
        } else {
          widget.onChanged(val);
        }
      },
    );
  }
}
