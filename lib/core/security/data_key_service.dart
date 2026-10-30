import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:offline_vault/core/crypto/cipher_service.dart';

/// Holds the key that encrypts notes at rest. It is random, created on the
/// first launch and kept in secure storage; the user never sees it
/// (ADR 0002: no PIN).
class DataKeyService {
  final FlutterSecureStorage _storage;
  final CipherService _cipherService;

  static const String _keyDataKey = 'vault_data_key';

  DataKeyService({FlutterSecureStorage? storage, CipherService? cipherService})
    : _storage = storage ?? const FlutterSecureStorage(),
      _cipherService = cipherService ?? CipherService();

  /// Returns the stored key, creating and saving a new one on first use.
  Future<SecretKey> loadOrCreateKey() async {
    final stored = await _storage.read(key: _keyDataKey);
    if (stored != null && stored.isNotEmpty) {
      return SecretKey(base64Decode(stored));
    }

    final bytes = _cipherService.generateRandomBytes(32);
    await _storage.write(key: _keyDataKey, value: base64Encode(bytes));
    return SecretKey(bytes);
  }
}
