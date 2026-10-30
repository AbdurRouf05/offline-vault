import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_vault/core/app_state.dart';
import 'package:offline_vault/core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final security = ref.read(securityServiceProvider);
    final available = await security.isBiometricAvailable();
    final enabled = await security.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  void _toggleBiometric(bool val) async {
    final security = ref.read(securityServiceProvider);
    await security.setBiometricEnabled(val);
    setState(() => _biometricEnabled = val);
  }

  void _showChangePinDialog() {
    final oldPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: const Text('Ganti Master PIN'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorText != null) ...[
                      Text(
                        errorText!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: oldPinCtrl,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'PIN Lama',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPinCtrl,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'PIN Baru (Min. 6 Digit)',
                        prefixIcon: Icon(Icons.password_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPinCtrl,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Konfirmasi PIN Baru',
                        prefixIcon: Icon(Icons.check_circle_outline),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 40),
                  ),
                  onPressed: () async {
                    final oldPin = oldPinCtrl.text.trim();
                    final newPin = newPinCtrl.text.trim();
                    final confirm = confirmPinCtrl.text.trim();

                    if (newPin.length < 6) {
                      setDialogState(
                        () => errorText = 'PIN baru minimal harus 6 karakter.',
                      );
                      return;
                    }
                    if (newPin != confirm) {
                      setDialogState(
                        () => errorText = 'Konfirmasi PIN baru tidak cocok.',
                      );
                      return;
                    }

                    final security = ref.read(securityServiceProvider);
                    final db = ref.read(databaseServiceProvider);
                    final SecretKey? key;
                    try {
                      key = await security.changeMasterPin(
                        oldPin,
                        newPin,
                        reEncrypt: db.reEncryptAll,
                      );
                    } catch (_) {
                      setDialogState(
                        () => errorText =
                            'Gagal mengganti PIN. Data tidak diubah, PIN lama tetap berlaku.',
                      );
                      return;
                    }
                    if (key == null) {
                      setDialogState(
                        () => errorText = 'PIN lama yang dimasukkan salah.',
                      );
                      return;
                    }

                    ref.read(sessionKeyProvider.notifier).setKey(key);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Master PIN berhasil diperbarui'),
                        ),
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _exportBackup() {
    final passwordCtrl = TextEditingController();
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: const Text('Ekspor Cadangan Terenkripsi'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seluruh akun dan catatan akan dienkripsi dengan password cadangan ini (AES-256-GCM). Simpan password ini untuk memulihkan di HP baru.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  if (errorText != null) ...[
                    Text(
                      errorText!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password Cadangan *',
                      prefixIcon: Icon(Icons.key_outlined),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 40),
                  ),
                  onPressed: () async {
                    final pwd = passwordCtrl.text.trim();
                    if (pwd.length < 6) {
                      setDialogState(
                        () =>
                            errorText = 'Password cadangan minimal 6 karakter.',
                      );
                      return;
                    }

                    final key = ref.read(sessionKeyProvider);
                    if (key == null) return;

                    Navigator.pop(context);

                    try {
                      final backupService = ref.read(backupServiceProvider);
                      final file = await backupService.exportEncryptedBackup(
                        activeSessionKey: key,
                        backupPassword: pwd,
                      );

                      if (context.mounted) {
                        await SharePlus.instance.share(
                          ShareParams(
                            files: [XFile(file.path)],
                            text: 'File Cadangan Offline Vault Terenkripsi',
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal mengekspor cadangan: $e'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Buat File'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _importBackup() async {
    final files = await FilePicker.pickFiles();

    if (files.isEmpty || files.first.path == null) return;

    final filePath = files.first.path!;
    final file = File(filePath);

    if (!mounted) return;

    final passwordCtrl = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: const Text('Impor Cadangan (.vault)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File: ${files.first.name}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masukkan password yang digunakan saat mengekspor file cadangan ini:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  if (errorText != null) ...[
                    Text(
                      errorText!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password Cadangan *',
                      prefixIcon: Icon(Icons.key_outlined),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 40),
                  ),
                  onPressed: () async {
                    final pwd = passwordCtrl.text.trim();
                    if (pwd.isEmpty) {
                      setDialogState(
                        () =>
                            errorText = 'Password cadangan tidak boleh kosong.',
                      );
                      return;
                    }

                    final key = ref.read(sessionKeyProvider);
                    if (key == null) return;

                    final backupService = ref.read(backupServiceProvider);
                    try {
                      final summary = await backupService.importEncryptedBackup(
                        backupFile: file,
                        backupPassword: pwd,
                        targetSessionKey: key,
                      );

                      await ref.read(credentialsProvider.notifier).refresh();
                      await ref.read(notesProvider.notifier).refresh();

                      if (context.mounted) {
                        Navigator.pop(context);
                        await showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Impor Berhasil'),
                            content: Text(
                              'Dipulihkan:\n• ${summary.credentialCount} Akun Kredensial\n• ${summary.noteCount} Catatan',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Selesai'),
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (_) {
                      setDialogState(
                        () => errorText =
                            'Password salah atau file cadangan rusak / tidak valid.',
                      );
                    }
                  },
                  child: const Text('Pulihkan Data'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _lockVault() {
    ref.read(sessionKeyProvider.notifier).setKey(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan & Migrasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'KEAMANAN & AKSES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                if (_biometricAvailable) ...[
                  SwitchListTile(
                    title: const Text('Buka dengan Biometrik'),
                    subtitle: const Text('Fingerprint atau Face Unlock'),
                    value: _biometricEnabled,
                    activeThumbColor: AppColors.lightAccent,
                    onChanged: _toggleBiometric,
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  leading: const Icon(Icons.password_outlined),
                  title: const Text('Ganti Master PIN'),
                  subtitle: const Text('Ubah kode keamanan pembuka brankas'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showChangePinDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'MIGRASI DATA (OFFLINE)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.file_upload_outlined,
                    color: AppColors.lightAccent,
                  ),
                  title: const Text('Ekspor Cadangan (.vault)'),
                  subtitle: const Text(
                    'Simpan dan bagikan file terenkripsi untuk dipindah ke HP baru',
                  ),
                  onTap: _exportBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.file_download_outlined,
                    color: AppColors.lightAccent,
                  ),
                  title: const Text('Impor Cadangan (.vault)'),
                  subtitle: const Text(
                    'Pulihkan kredensial & catatan dari file ponsel lama',
                  ),
                  onTap: _importBackup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'STATUS PRIVASI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wifi_off, size: 20, color: AppColors.success),
                      SizedBox(width: 8),
                      Text(
                        '100% Offline Tanpa Izin Internet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aplikasi ini tidak memiliki izin akses jaringan. Seluruh data dienkripsi dengan standar AES-256-GCM langsung di penyimpanan internal perangkat Anda.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.lock),
            label: const Text('Kunci Brankas Sekarang'),
            onPressed: _lockVault,
          ),
        ],
      ),
    );
  }
}
