import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:offline_vault/core/crypto/cipher_service.dart';

class SecurityService {
  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;
  final CipherService _cipherService;

  static const String _keyMasterPinSalt = 'vault_master_pin_salt';
  static const String _keyMasterPinHash = 'vault_master_pin_hash';
  static const String _keyBiometricEnabled = 'vault_biometric_enabled';
  static const String _keyBiometricPin = 'vault_biometric_pin';

  SecurityService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
    CipherService? cipherService,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _localAuth = localAuth ?? LocalAuthentication(),
       _cipherService = cipherService ?? CipherService();

  /// Check if Master PIN has already been initialized
  Future<bool> isMasterPinSet() async {
    final hash = await _storage.read(key: _keyMasterPinHash);
    return hash != null && hash.isNotEmpty;
  }

  /// Initial setup of Master PIN
  Future<SecretKey> setupMasterPin(String pin) async {
    final salt = _cipherService.generateRandomBytes(32);
    final key = await _cipherService.deriveKeyFromPassword(pin, salt);
    await _persistMasterPin(pin, salt, key);
    return key;
  }

  Future<void> _persistMasterPin(
    String pin,
    List<int> salt,
    SecretKey key,
  ) async {
    final keyBytes = await key.extractBytes();

    await _storage.write(key: _keyMasterPinSalt, value: base64Encode(salt));
    await _storage.write(key: _keyMasterPinHash, value: base64Encode(keyBytes));

    // If biometric was previously enabled, update cached pin
    if (await isBiometricEnabled()) {
      await _storage.write(key: _keyBiometricPin, value: pin);
    }
  }

  /// Verify entered Master PIN against stored hash and return derived SecretKey
  Future<SecretKey?> verifyAndDeriveKey(String pin) async {
    final saltBase64 = await _storage.read(key: _keyMasterPinSalt);
    final hashBase64 = await _storage.read(key: _keyMasterPinHash);

    if (saltBase64 == null || hashBase64 == null) return null;

    final salt = base64Decode(saltBase64);
    final storedHash = base64Decode(hashBase64);

    final key = await _cipherService.deriveKeyFromPassword(pin, salt);
    final keyBytes = await key.extractBytes();

    if (keyBytes.length != storedHash.length) return null;

    // Constant-time comparison
    var result = 0;
    for (var i = 0; i < keyBytes.length; i++) {
      result |= keyBytes[i] ^ storedHash[i];
    }

    if (result == 0) {
      return key;
    }
    return null;
  }

  /// Change Master PIN. Stored data is encrypted with the PIN-derived key, so
  /// [reEncrypt] must move all data from the old key to the new key. The new
  /// PIN is only persisted after [reEncrypt] completes; if it throws, the old
  /// PIN stays valid.
  Future<SecretKey?> changeMasterPin(
    String oldPin,
    String newPin, {
    required Future<void> Function(SecretKey oldKey, SecretKey newKey)
    reEncrypt,
  }) async {
    final oldKey = await verifyAndDeriveKey(oldPin);
    if (oldKey == null) return null;

    final salt = _cipherService.generateRandomBytes(32);
    final newKey = await _cipherService.deriveKeyFromPassword(newPin, salt);

    await reEncrypt(oldKey, newKey);
    await _persistMasterPin(newPin, salt, newKey);
    return newKey;
  }

  /// Check device biometric capability
  Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (_) {
      return false;
    }
  }

  /// Check if user has opted in for Biometric unlock
  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  /// Enable biometric authentication with current valid PIN
  Future<void> enableBiometricWithPin(String pin) async {
    await _storage.write(key: _keyBiometricPin, value: pin);
    await _storage.write(key: _keyBiometricEnabled, value: 'true');
  }

  /// Disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    if (!enabled) {
      await _storage.delete(key: _keyBiometricPin);
      await _storage.write(key: _keyBiometricEnabled, value: 'false');
    } else {
      await _storage.write(key: _keyBiometricEnabled, value: 'true');
    }
  }

  /// Unlock directly using biometrics if enabled
  Future<SecretKey?> unlockWithBiometric() async {
    try {
      final available = await isBiometricAvailable();
      final enabled = await isBiometricEnabled();
      if (!available || !enabled) return null;

      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Buka brankas Offline Vault',
        biometricOnly: true,
      );

      if (!didAuth) return null;

      final cachedPin = await _storage.read(key: _keyBiometricPin);
      if (cachedPin == null) return null;

      return await verifyAndDeriveKey(cachedPin);
    } catch (_) {
      return null;
    }
  }
}
