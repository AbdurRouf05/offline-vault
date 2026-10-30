import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_vault/core/app_state.dart';
import 'package:offline_vault/features/credentials/credential_item.dart';
import 'package:offline_vault/features/credentials/password_generator_dialog.dart';
import 'package:uuid/uuid.dart';

class CredentialFormScreen extends ConsumerStatefulWidget {
  final CredentialItem? existingItem;

  const CredentialFormScreen({super.key, this.existingItem});

  @override
  ConsumerState<CredentialFormScreen> createState() =>
      _CredentialFormScreenState();
}

class _CredentialFormScreenState extends ConsumerState<CredentialFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _urlController;
  late TextEditingController _notesController;
  String _selectedCategory = 'Akun Web';
  bool _obscurePassword = true;

  final List<String> _categories = [
    'Akun Web',
    'Perbankan',
    'Email',
    'Medsos',
    'Kerja',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _titleController = TextEditingController(text: item?.title ?? '');
    _usernameController = TextEditingController(text: item?.username ?? '');
    _passwordController = TextEditingController(text: item?.password ?? '');
    _urlController = TextEditingController(text: item?.url ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    if (item != null && _categories.contains(item.category)) {
      _selectedCategory = item.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final item = CredentialItem(
      id: widget.existingItem?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      url: _urlController.text.trim(),
      category: _selectedCategory,
      notes: _notesController.text.trim(),
      createdAt: widget.existingItem?.createdAt ?? now,
      updatedAt: now,
    );

    ref.read(credentialsProvider.notifier).addOrUpdate(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Ubah Kredensial' : 'Tambah Kredensial'),
        actions: [
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
                decoration: const InputDecoration(
                  labelText: 'Nama Layanan / Judul *',
                  hintText: 'Misal: Google, BCA, GitHub',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul layanan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
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
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username / Email *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Username wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: 'Password *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.vpn_key_outlined),
                        tooltip: 'Generator Password',
                        onPressed: () async {
                          final generated =
                              await showDialog<String>(
                            context: context,
                            builder: (context) => const PasswordGeneratorDialog(),
                          );
                          if (generated != null && generated.isNotEmpty) {
                            setState(() {
                              _passwordController.text = generated;
                              _obscurePassword = false;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Password wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL / Alamat Situs (Opsional)',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Catatan Rahasia (Opsional)',
                  hintText: 'Pertanyaan keamanan, PIN sekunder, dsb.',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: Text(isEditing ? 'Perbarui Kredensial' : 'Simpan Kredensial'),
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
