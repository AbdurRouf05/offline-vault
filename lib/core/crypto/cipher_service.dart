import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class EncryptedPayload {
  final String cipherTextBase64;
  final String nonceBase64;
  final String macBase64;

  const EncryptedPayload({
    required this.cipherTextBase64,
    required this.nonceBase64,
    required this.macBase64,
  });

  Map<String, dynamic> toJson() => {
    'c': cipherTextBase64,
    'n': nonceBase64,
    'm': macBase64,
  };

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) =>
      EncryptedPayload(
        cipherTextBase64: json['c'] as String,
        nonceBase64: json['n'] as String,
        macBase64: json['m'] as String,
      );

  String serialize() => jsonEncode(toJson());

  static EncryptedPayload deserialize(String serialized) =>
      EncryptedPayload.fromJson(jsonDecode(serialized) as Map<String, dynamic>);
}

class CipherService {
  final AesGcm _aesGcm = AesGcm.with256bits();
  final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  /// Derive 256-bit SecretKey from password and salt
  Future<SecretKey> deriveKeyFromPassword(
    String password,
    List<int> salt,
  ) async {
    final secretKey = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return secretKey;
  }

  /// Encrypt plaintext with SecretKey using AES-256-GCM
  Future<EncryptedPayload> encryptText(String plainText, SecretKey key) async {
    final bytes = utf8.encode(plainText);
    final secretBox = await _aesGcm.encrypt(bytes, secretKey: key);

    return EncryptedPayload(
      cipherTextBase64: base64Encode(secretBox.cipherText),
      nonceBase64: base64Encode(secretBox.nonce),
      macBase64: base64Encode(secretBox.mac.bytes),
    );
  }

  /// Decrypt EncryptedPayload back to plaintext string
  Future<String> decryptText(EncryptedPayload payload, SecretKey key) async {
    final cipherText = base64Decode(payload.cipherTextBase64);
    final nonce = base64Decode(payload.nonceBase64);
    final macBytes = base64Decode(payload.macBase64);

    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));

    final decryptedBytes = await _aesGcm.decrypt(secretBox, secretKey: key);

    return utf8.decode(decryptedBytes);
  }

  /// Generate cryptographically secure random bytes
  Uint8List generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// Generate a strong password
  String generatePassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
  }) {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()-_=+[]{}|;:,.<>?';

    var charset = '';
    final requiredChars = <String>[];
    final random = Random.secure();

    if (includeUppercase) {
      charset += uppercase;
      requiredChars.add(uppercase[random.nextInt(uppercase.length)]);
    }
    if (includeLowercase) {
      charset += lowercase;
      requiredChars.add(lowercase[random.nextInt(lowercase.length)]);
    }
    if (includeNumbers) {
      charset += numbers;
      requiredChars.add(numbers[random.nextInt(numbers.length)]);
    }
    if (includeSymbols) {
      charset += symbols;
      requiredChars.add(symbols[random.nextInt(symbols.length)]);
    }

    if (charset.isEmpty) {
      charset = lowercase + numbers;
    }

    final remainingLength = length - requiredChars.length;
    final buffer = StringBuffer();

    for (var i = 0; i < remainingLength; i++) {
      buffer.write(charset[random.nextInt(charset.length)]);
    }

    final allChars = [...requiredChars, ...buffer.toString().split('')]
      ..shuffle(random);

    return allChars.join();
  }
}
