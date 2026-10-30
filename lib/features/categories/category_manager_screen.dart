import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_vault/core/theme/app_theme.dart';
import 'package:offline_vault/features/categories/categories_provider.dart';
import 'package:offline_vault/features/categories/category_list.dart';
import 'package:offline_vault/features/categories/category_name_dialog.dart';

/// Add, rename and delete the categories of one [CategoryScope].
class CategoryManagerScreen extends ConsumerWidget {
  final CategoryScope scope;

  const CategoryManagerScreen({super.key, required this.scope});

  Future<void> _confirmDelete(
    BuildContext context,
    CategoriesNotifier notifier,
    String name,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus kategori "$name"?'),
        content: Text(
          'Item di kategori ini tidak dihapus, tapi dipindah ke "${scope.fallback}".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) await notifier.remove(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = categoriesProviderFor(scope);
    final categories = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kategori')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
        onPressed: () => showCategoryNameDialog(
          context,
          title: 'Kategori Baru',
          onSubmit: notifier.add,
        ),
      ),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat kategori: $err')),
        data: (list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final name = list[index];
            final isFallback = name == scope.fallback;
            return ListTile(
              title: Text(name),
              subtitle: isFallback
                  ? const Text('Kategori cadangan, tidak bisa dihapus')
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Ganti nama',
                    onPressed: () => showCategoryNameDialog(
                      context,
                      title: 'Ganti Nama Kategori',
                      initial: name,
                      onSubmit: (to) => notifier.rename(name, to),
                    ),
                  ),
                  if (!isFallback)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Hapus',
                      onPressed: () => _confirmDelete(context, notifier, name),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
