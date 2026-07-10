import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:safetext/core/exceptions/app_exceptions.dart';
import 'package:safetext/core/security/caesar_cipher_service.dart';
import 'package:safetext/core/security/des_crypto_service.dart';
import 'package:safetext/core/security/lsb_steganography_service.dart';
import 'package:safetext/core/security/password_generator_service.dart';
import 'package:safetext/core/security/password_strength_analyzer.dart';

Uint8List _generateTestPng({int width = 200, int height = 200}) {
  final image = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final r = (x * 37 + y * 91) % 256;
      final g = (x * 53 + y * 17) % 256;
      final b = (x * 13 + y * 61) % 256;
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('LsbSteganographyService (plain, no encryption)', () {
    const service = LsbSteganographyService();

    test('embed -> extract round trip recovers the exact message', () async {
      final carrier = _generateTestPng();
      const message = 'Meet at the old bridge, 9pm.';

      final embedded = await service.embed(imageBytes: carrier, message: message);
      final extracted = await service.extract(embedded);

      expect(extracted, message);
    });

    test('extract throws NoPayloadFoundException on a clean carrier', () async {
      final carrier = _generateTestPng();
      expect(() => service.extract(carrier), throwsA(isA<NoPayloadFoundException>()));
    });

    test('embed throws InsufficientCapacityException on a too-small image', () async {
      final tiny = _generateTestPng(width: 4, height: 4);
      expect(
        () => service.embed(imageBytes: tiny, message: 'this message will not fit'),
        throwsA(isA<InsufficientCapacityException>()),
      );
    });
  });

  group('DesCryptoService', () {
    const des = DesCryptoService();

    test('encrypt -> decrypt round trip recovers the original plaintext', () async {
      const plainText = 'The vault code is 4482-XJ9.';
      const key = 'my-des-key';

      final encrypted = await des.encrypt(plainText, key);
      final decrypted = await des.decrypt(encrypted, key);

      expect(decrypted, plainText);
    });

    test('decrypt throws DecryptionFailedException on the wrong key', () async {
      final encrypted = await des.encrypt('classified', 'correct-key');
      expect(() => des.decrypt(encrypted, 'wrong-key'), throwsA(isA<DecryptionFailedException>()));
    });

    test('encrypt output includes an 8-byte IV prefix and is block-aligned', () async {
      final encrypted = await des.encrypt('hi', 'key');
      expect(encrypted.length % DesCryptoService.blockSizeBytes, 0);
      expect(encrypted.length, greaterThanOrEqualTo(DesCryptoService.blockSizeBytes * 2));
    });

    test('handles empty and long messages', () async {
      const des2 = DesCryptoService();
      final longMessage = 'A' * 500;
      final encrypted = await des2.encrypt(longMessage, 'k');
      final decrypted = await des2.decrypt(encrypted, 'k');
      expect(decrypted, longMessage);
    });
  });

  group('CaesarCipherService', () {
    const caesar = CaesarCipherService();

    test('encrypt -> decrypt round trip with a positive shift', () {
      const plain = 'Hello, World!';
      final cipher = caesar.encrypt(plain, 3);
      expect(cipher, 'Khoor, Zruog!');
      expect(caesar.decrypt(cipher, 3), plain);
    });

    test('preserves case and passes through non-letters unchanged', () {
      final cipher = caesar.encrypt('AbC 123!', 1);
      expect(cipher, 'BcD 123!');
    });

    test('wraps around the alphabet correctly', () {
      expect(caesar.encrypt('XYZ', 3), 'ABC');
      expect(caesar.encrypt('xyz', 3), 'abc');
    });

    test('shift of 0 is a no-op, shift of 26 is a no-op', () {
      const text = 'Test Value 42';
      expect(caesar.encrypt(text, 0), text);
      expect(caesar.encrypt(text, 26), text);
    });
  });

  group('PasswordGeneratorService + PasswordStrengthAnalyzer', () {
    const generator = PasswordGeneratorService();
    const analyzer = PasswordStrengthAnalyzer();

    test('generated password matches the requested length', () {
      final password = generator.generate(const PasswordOptions(length: 20));
      expect(password.length, 20);
    });

    test('generated password only uses selected character classes', () {
      final password = generator.generate(const PasswordOptions(
        length: 30,
        includeUppercase: false,
        includeLowercase: true,
        includeNumbers: false,
        includeSymbols: false,
      ));
      expect(RegExp(r'^[a-z]+$').hasMatch(password), isTrue);
    });

    test('throws WeakPassphraseException when no character class is selected', () {
      expect(
        () => generator.generate(const PasswordOptions(
          includeUppercase: false,
          includeLowercase: false,
          includeNumbers: false,
          includeSymbols: false,
        )),
        throwsA(isA<WeakPassphraseException>()),
      );
    });

    test('strength analyzer rates a short simple password as weak', () {
      expect(analyzer.analyze('abc'), PasswordStrength.weak);
    });

    test('strength analyzer rates a long random password as strong or better', () {
      final strong = generator.generate(const PasswordOptions(length: 24));
      final strength = analyzer.analyze(strong);
      expect(strength == PasswordStrength.strong || strength == PasswordStrength.veryStrong, isTrue);
    });
  });
}
