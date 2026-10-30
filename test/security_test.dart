import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_vault/core/crypto/cipher_service.dart';
import 'package:offline_vault/core/security/security_service.dart';

void main() {
  group('SecurityService.changeMasterPin', () {
    final cipher = CipherService();
    late SecurityService security;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      security = SecurityService(cipherService: cipher);
    });

    test(
      'hands old and new keys to reEncrypt so data stays readable',
      () async {
        final originalKey = await security.setupMasterPin('111111');
        var stored = await cipher.encryptText('secret data', originalKey);

        final newKey = await security.changeMasterPin(
          '111111',
          '222222',
          reEncrypt: (oldKey, newKey) async {
            final plain = await cipher.decryptText(stored, oldKey);
            stored = await cipher.encryptText(plain, newKey);
          },
        );

        expect(newKey, isNotNull);
        final unlocked = await security.verifyAndDeriveKey('222222');
        expect(unlocked, isNotNull);
        expect(await cipher.decryptText(stored, unlocked!), 'secret data');
        expect(await security.verifyAndDeriveKey('111111'), isNull);
      },
    );

    test('keeps the old PIN when reEncrypt fails', () async {
      await security.setupMasterPin('111111');

      await expectLater(
        security.changeMasterPin(
          '111111',
          '222222',
          reEncrypt: (_, _) async => throw StateError('disk full'),
        ),
        throwsStateError,
      );

      expect(await security.verifyAndDeriveKey('111111'), isNotNull);
      expect(await security.verifyAndDeriveKey('222222'), isNull);
    });

    test('rejects a wrong old PIN without calling reEncrypt', () async {
      await security.setupMasterPin('111111');
      var called = false;

      final result = await security.changeMasterPin(
        '999999',
        '222222',
        reEncrypt: (_, _) async => called = true,
      );

      expect(result, isNull);
      expect(called, isFalse);
    });
  });
}
