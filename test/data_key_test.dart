import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_vault/core/crypto/cipher_service.dart';
import 'package:offline_vault/core/security/data_key_service.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('creates a 256-bit key once and returns the same key later', () async {
    final first = await DataKeyService().loadOrCreateKey();
    final second = await DataKeyService().loadOrCreateKey();

    final bytes = await first.extractBytes();
    expect(bytes, hasLength(32));
    expect(await second.extractBytes(), bytes);
  });

  test('data encrypted with the key stays readable after restart', () async {
    final cipher = CipherService();
    final key = await DataKeyService().loadOrCreateKey();
    final stored = await cipher.encryptText('catatan', key);

    final reloaded = await DataKeyService().loadOrCreateKey();
    expect(await cipher.decryptText(stored, reloaded), 'catatan');
  });
}
