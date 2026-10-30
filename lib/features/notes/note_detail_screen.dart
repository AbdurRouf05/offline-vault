import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_vault/core/app_state.dart';
import 'package:offline_vault/core/theme/app_theme.dart';
import 'package:offline_vault/features/notes/note_form_screen.dart';
import 'package:offline_vault/features/notes/note_item.dart';

/// Read-only view of a note. Editing happens only after tapping "Ubah", so
/// long notes can be scrolled and copied without accidental changes.
class NoteDetailScreen extends ConsumerWidget {
  final NoteItem note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show the latest saved version after returning from the edit screen.
    final notes = ref.watch(notesProvider).value;
    final current = notes?.where((n) => n.id == note.id).firstOrNull ?? note;
    final updated = current.updatedAt;
    final dateStr = '${updated.day}/${updated.month}/${updated.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Salin Isi',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: current.content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Isi catatan disalin')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Ubah',
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => NoteFormScreen(existingNote: current),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (current.isPinned) ...[
                  const Icon(
                    Icons.push_pin,
                    size: 18,
                    color: AppColors.lightAccent,
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    current.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${current.category} · Diubah $dateStr',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SelectableText(
              current.content,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
