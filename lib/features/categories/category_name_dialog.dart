import 'package:flutter/material.dart';
import 'package:offline_vault/core/theme/app_theme.dart';
import 'package:offline_vault/features/categories/category_list.dart';

/// Asks for a category name and runs [onSubmit] with it. Validation errors
/// ([CategoryNameException]) are shown inside the dialog. Returns the saved
/// name, or null if cancelled.
Future<String?> showCategoryNameDialog(
  BuildContext context, {
  required String title,
  required Future<void> Function(String name) onSubmit,
  String initial = '',
}) {
  final ctrl = TextEditingController(text: initial);
  String? errorText;

  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        Future<void> submit() async {
          try {
            await onSubmit(ctrl.text);
            if (context.mounted) Navigator.pop(context, ctrl.text.trim());
          } on CategoryNameException catch (e) {
            setDialogState(() => errorText = e.message);
          }
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (errorText != null) ...[
                Text(
                  errorText!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama kategori'),
                onSubmitted: (_) => submit(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(onPressed: submit, child: const Text('Simpan')),
          ],
        );
      },
    ),
  );
}
