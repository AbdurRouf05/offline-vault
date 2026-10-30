import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_vault/core/app_state.dart';
import 'package:offline_vault/core/theme/app_theme.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _isLoading = true;
  bool _isPinSet = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialState() async {
    final security = ref.read(securityServiceProvider);
    final isSet = await security.isMasterPinSet();
    final bioAvailable = await security.isBiometricAvailable();
    final bioEnabled = await security.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _isPinSet = isSet;
        _biometricAvailable = bioAvailable;
        _biometricEnabled = bioEnabled;
        _isLoading = false;
      });

      if (isSet && bioAvailable && bioEnabled) {
        await _tryBiometricUnlock();
      }
    }
  }

  Future<void> _tryBiometricUnlock() async {
    final security = ref.read(securityServiceProvider);
    final key = await security.unlockWithBiometric();
    if (key != null && mounted) {
      ref.read(sessionKeyProvider.notifier).setKey(key);
    }
  }

  Future<void> _setupPin() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (pin.length < 6) {
      setState(() => _errorMessage = 'Master PIN minimal 6 digit/karakter.');
      return;
    }
    if (pin != confirm) {
      setState(() => _errorMessage = 'Konfirmasi PIN tidak cocok.');
      return;
    }

    setState(() => _isLoading = true);
    final security = ref.read(securityServiceProvider);
    final key = await security.setupMasterPin(pin);

    // Offer to enable biometrics if hardware supports it
    if (_biometricAvailable && mounted) {
      final enableBio = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Aktifkan Biometrik?'),
          content: const Text(
            'Buka brankas lebih cepat menggunakan sidik jari atau Face Unlock.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Nanti Saja'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Aktifkan'),
            ),
          ],
        ),
      );

      if (enableBio == true) {
        await security.enableBiometricWithPin(pin);
      }
    }

    if (mounted) {
      ref.read(sessionKeyProvider.notifier).setKey(key);
    }
  }

  Future<void> _unlockWithPin() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _errorMessage = 'Masukkan PIN brankas Anda.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final security = ref.read(securityServiceProvider);
    final key = await security.verifyAndDeriveKey(pin);

    if (key == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'PIN salah. Silakan coba lagi.';
      });
      return;
    }

    if (mounted) {
      ref.read(sessionKeyProvider.notifier).setKey(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.lightAccent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 38,
                    color: AppColors.lightAccent,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isPinSet ? 'Buka Offline Vault' : 'Buat Master PIN',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isPinSet
                      ? 'Masukkan PIN untuk mendekripsi brankas offline'
                      : 'Kunci utama untuk mengenkripsi seluruh kredensial dan catatan Anda secara lokal.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 28),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: '••••••',
                    labelText: 'Master PIN',
                  ),
                  onSubmitted: (_) {
                    if (_isPinSet) {
                      _unlockWithPin();
                    }
                  },
                ),
                if (!_isPinSet) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _confirmPinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: '••••••',
                      labelText: 'Konfirmasi Master PIN',
                    ),
                    onSubmitted: (_) => _setupPin(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _setupPin,
                    child: const Text('Buat Brankas'),
                  ),
                ] else ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _unlockWithPin,
                    child: const Text('Buka Brankas'),
                  ),
                  if (_biometricAvailable && _biometricEnabled) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Buka dengan Biometrik'),
                      onPressed: _tryBiometricUnlock,
                    ),
                  ],
                ],
                const SizedBox(height: 32),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      'AES-256-GCM • Nol Akses Internet',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
