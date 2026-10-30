import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_vault/core/app_state.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _exportBackup() async {
    setState(() => _busy = true);
    try {
      final dataKey = await ref.read(dataKeyProvider.future);
      final file = await ref
          .read(backupServiceProvider)
          .exportBackup(dataKey: dataKey);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Cadangan catatan'),
      );
    } catch (e) {
      _showMessage('Gagal mengekspor: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importBackup() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty || files.first.path == null || !mounted) return;
    final picked = files.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Impor catatan?'),
        content: Text(
          'Catatan dari ${picked.name} akan ditambahkan. Catatan yang sama '
          'dari impor sebelumnya akan diganti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Impor'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final dataKey = await ref.read(dataKeyProvider.future);
      final summary = await ref
          .read(backupServiceProvider)
          .importBackup(backupFile: File(picked.path!), dataKey: dataKey);
      await ref.read(notesProvider.notifier).refresh();
      _showMessage('${summary.noteCount} catatan diimpor.');
    } on FormatException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Gagal mengimpor: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Pindah ke HP lain',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  enabled: !_busy,
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('Ekspor catatan'),
                  subtitle: const Text(
                    'Buat satu file .vault berisi semua catatan, lalu kirim '
                    'ke HP baru.',
                  ),
                  onTap: _exportBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  enabled: !_busy,
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Impor catatan'),
                  subtitle: const Text(
                    'Pilih file .vault di HP ini. Biasanya ada di folder '
                    'Download.',
                  ),
                  onTap: _importBackup,
                ),
              ],
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 12),
          Text(
            'File cadangan tidak memakai password. Siapa pun yang memegang '
            'file itu bisa membaca isinya, jadi hapus file setelah '
            'dipindahkan. Aplikasi ini tidak memakai internet.',
            style: TextStyle(fontSize: 13, color: muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
