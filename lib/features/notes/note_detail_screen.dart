import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_vault/core/app_state.dart';
import 'package:offline_vault/core/theme/app_theme.dart';
import 'package:offline_vault/features/notes/note_form_screen.dart';
import 'package:offline_vault/features/notes/note_item.dart';
import 'package:offline_vault/features/notes/note_tags.dart';

/// Read-only view of a note. Editing happens only after tapping "Ubah", so
/// long notes can be scrolled and copied without accidental changes.
/// When the content has `#tags`, chips let the reader show only the lines
/// with one tag.
class NoteDetailScreen extends ConsumerStatefulWidget {
  final NoteItem note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    // Show the latest saved version after returning from the edit screen.
    final notes = ref.watch(notesProvider).value;
    final current = notes?.where((n) => n.id == note.id).firstOrNull ?? note;
    final updated = current.updatedAt;
    final dateStr = '${updated.day}/${updated.month}/${updated.year}';
    final tags = extractTags(current.content);
    final selectedTag = tags.contains(_selectedTag) ? _selectedTag : null;
    final lines = selectedTag == null
        ? current.content.split('\n')
        : filterLinesByTag(current.content, selectedTag);

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
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              _TagFilterBar(
                tags: tags,
                counts: countTags(current.content),
                selected: selectedTag,
                onSelected: (tag) => setState(() => _selectedTag = tag),
              ),
            ],
            const SizedBox(height: 16),
            SelectableText.rich(
              _contentSpan(context, lines),
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

TextSpan _contentSpan(BuildContext context, List<String> lines) {
  final muted = Theme.of(context).colorScheme.onSurfaceVariant;
  final spans = <InlineSpan>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (i > 0) spans.add(const TextSpan(text: '\n'));
    if (isHeading(line)) {
      spans.add(
        TextSpan(
          text: headingText(line),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      );
      continue;
    }
    for (final part in splitTags(line)) {
      spans.add(
        TextSpan(
          text: part.text,
          style: part.isTag ? TextStyle(fontSize: 13, color: muted) : null,
        ),
      );
    }
  }
  return TextSpan(children: spans);
}

class _TagFilterBar extends StatelessWidget {
  final List<String> tags;
  final Map<String, int> counts;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _TagFilterBar({
    required this.tags,
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String? tag) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected == tag,
        selectedColor: AppColors.lightAccent.withValues(alpha: 0.2),
        checkmarkColor: AppColors.lightAccent,
        onSelected: (_) => onSelected(tag),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('Semua', null),
          for (final tag in tags) chip('#$tag (${counts[tag] ?? 0})', tag),
        ],
      ),
    );
  }
}
