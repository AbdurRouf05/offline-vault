import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_vault/core/app_state.dart';
import 'package:offline_vault/core/theme/app_theme.dart';
import 'package:offline_vault/features/notes/note_item.dart';
import 'package:uuid/uuid.dart';

class NoteFormScreen extends ConsumerStatefulWidget {
  final NoteItem? existingNote;

  const NoteFormScreen({super.key, this.existingNote});

  @override
  ConsumerState<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends ConsumerState<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String _selectedCategory = 'Umum';
  bool _isPinned = false;

  final List<String> _categories = [
    'Umum',
    'Pribadi',
    'Pekerjaan',
    'Ide',
    'Keuangan',
    'Penting',
  ];

  @override
  void initState() {
    super.initState();
    final note = widget.existingNote;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _isPinned = note?.isPinned ?? false;
    if (note != null && _categories.contains(note.category)) {
      _selectedCategory = note.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final note = NoteItem(
      id: widget.existingNote?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      category: _selectedCategory,
      isPinned: _isPinned,
      createdAt: widget.existingNote?.createdAt ?? now,
      updatedAt: now,
    );

    ref.read(notesProvider.notifier).addOrUpdate(note);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingNote != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Ubah Catatan' : 'Catatan Baru'),
        actions: [
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? AppColors.lightAccent : null,
            ),
            tooltip: _isPinned ? 'Lepas Sematan' : 'Sematkan Catatan',
            onPressed: () {
              setState(() => _isPinned = !_isPinned);
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Simpan',
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  labelText: 'Judul Catatan *',
                  hintText: 'Misal: Rencana Mingguan, Ide Proyek',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul catatan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _contentController,
                // Grow with the content so long lists scroll with the page
                // instead of inside a fixed-height box.
                minLines: 12,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  labelText: 'Isi Catatan *',
                  hintText: 'Tulis memo atau catatan rahasia di sini...',
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Isi catatan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: Text(isEditing ? 'Perbarui Catatan' : 'Simpan Catatan'),
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
