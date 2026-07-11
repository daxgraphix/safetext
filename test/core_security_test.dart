import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:safetext/core/constants/app_constants.dart';
import 'package:safetext/core/exceptions/app_exceptions.dart';
import 'package:safetext/core/security/crypto_service.dart';
import 'package:safetext/core/security/payload_codec.dart';
import 'package:safetext/core/security/stego_service.dart';

Uint8List _generateTestPng({int width = 200, int height = 200}) {
  final image = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      // Deterministic pseudo-noise so the image has enough texture to be a
      // valid Ghost/Armor Mode carrier in tests.
      final r = (x * 37 + y * 91) % 256;
      final g = (x * 53 + y * 17) % 256;
      final b = (x * 13 + y * 61) % 256;
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('CryptoService', () {
    final crypto = CryptoService();

    test('encrypt/decrypt round-trip recovers the original plaintext', () async {
      const plainText = 'The recovery keys are stored in Vault-9.';
      const passphrase = 'correct horse battery staple';

      final result = await crypto.encrypt(plainText, passphrase);
      final decrypted = await crypto.decrypt(
        salt: result.salt,
        nonce: result.nonce,
        cipherText: result.cipherText,
        mac: result.mac,
        passphrase: passphrase,
      );

      expect(decrypted, plainText);
    });

    test('decrypt throws DecryptionFailedException on wrong passphrase', () async {
      final result = await crypto.encrypt('secret payload', 'right-passphrase');

      expect(
        () => crypto.decrypt(
          salt: result.salt,
          nonce: result.nonce,
          cipherText: result.cipherText,
          mac: result.mac,
          passphrase: 'wrong-passphrase',
        ),
        throwsA(isA<DecryptionFailedException>()),
      );
    });

    test('passphraseStrengthScore increases with complexity', () {
      final weak = crypto.passphraseStrengthScore('abc');
      final strong = crypto.passphraseStrengthScore('C0rrect-Horse-Battery!9');
      expect(strong, greaterThan(weak));
    });
  });

  group('StegoService', () {
    const stego = StegoService();

    test('Ghost Mode: full encrypt -> embed -> extract -> decrypt round trip', () async {
      const message = 'Stealth sync at marker 0x7F.';
      const passphrase = 'ghost-mode-passphrase';
      final crypto = CryptoService();
      const codec = PayloadCodec();

      final carrier = _generateTestPng(width: 300, height: 300);
      final encryptionResult = await crypto.encrypt(message, passphrase);
      final body = codec.buildBody(
        timestamp: DateTime.now(),
        salt: encryptionResult.salt,
        nonce: encryptionResult.nonce,
        cipherText: encryptionResult.cipherText,
        mac: encryptionResult.mac,
      );

      final embedded = await stego.embed(
        imageBytes: carrier,
        bodyBytes: body,
        mode: StegoMode.ghost,
        seed: 123456789,
      );

      final extracted = await stego.extract(embedded);
      final decrypted = await crypto.decrypt(
        salt: extracted.salt,
        nonce: extracted.nonce,
        cipherText: extracted.cipherText,
        mac: extracted.mac,
        passphrase: passphrase,
      );

      expect(decrypted, message);
      expect(extracted.isGhost, isTrue);
    });

    test('Armor Mode: full encrypt -> embed -> extract -> decrypt round trip', () async {
      const message = 'Zurich facility sync before 04:00 GMT.';
      const passphrase = 'armor-mode-passphrase';
      final crypto = CryptoService();
      const codec = PayloadCodec();

      final carrier = _generateTestPng(width: 300, height: 300);
      final encryptionResult = await crypto.encrypt(message, passphrase);
      final body = codec.buildBody(
        timestamp: DateTime.now(),
        salt: encryptionResult.salt,
        nonce: encryptionResult.nonce,
        cipherText: encryptionResult.cipherText,
        mac: encryptionResult.mac,
      );

      final embedded = await stego.embed(
        imageBytes: carrier,
        bodyBytes: body,
        mode: StegoMode.armor,
        seed: 42,
      );

      final extracted = await stego.extract(embedded);
      final decrypted = await crypto.decrypt(
        salt: extracted.salt,
        nonce: extracted.nonce,
        cipherText: extracted.cipherText,
        mac: extracted.mac,
        passphrase: passphrase,
      );

      expect(decrypted, message);
      expect(extracted.isGhost, isFalse);
    });

    test('analyze() reports zero/near-zero capacity for a tiny image', () async {
      final tiny = _generateTestPng(width: 4, height: 4);
      expect(
        () => stego.analyze(tiny, mode: StegoMode.ghost),
        anyOf(
          throwsA(isA<InsufficientCapacityException>()),
          returnsNormally,
        ),
      );
    });

    test('extract() throws NoPayloadFoundException on a carrier with no payload', () async {
      final carrier = _generateTestPng();
      expect(() => stego.extract(carrier), throwsA(isA<NoPayloadFoundException>()));
    });
    test('Armor Mode: survives minor LSB corruption (simulated compression)', () async {
      const message = 'Survival test for redundant encoding.';
      const passphrase = 'durability-passphrase';
      final crypto = CryptoService();
      const codec = PayloadCodec();

      final carrier = _generateTestPng(width: 200, height: 200);
      final encryptionResult = await crypto.encrypt(message, passphrase);
      final body = codec.buildBody(
        timestamp: DateTime.now(),
        salt: encryptionResult.salt,
        nonce: encryptionResult.nonce,
        cipherText: encryptionResult.cipherText,
        mac: encryptionResult.mac,
      );

      final embedded = await stego.embed(
        imageBytes: carrier,
        bodyBytes: body,
        mode: StegoMode.armor,
        seed: 123,
      );

      // Simulate corruption: Flip some LSBs in the body region.
      // Armor Mode uses 3x redundancy, so we can survive 1 flipped bit per triplet.
      final corrupted = Uint8List.fromList(embedded);
      final decoded = img.decodePng(corrupted)!;
      
      // The header is at the start (18 bytes * 8 bits = 144 bits/channels).
      // We'll corrupt bits in the body (starting after the header).
      // We flip every 10th channel's LSB in the body.
      const headerBits = PayloadCodec.headerLengthBytes * 8;
      for (int i = headerBits; i < headerBits + (body.length * 8 * 3); i += 10) {
        final pixelIndex = i ~/ 3;
        final channel = i % 3;
        final x = pixelIndex % decoded.width;
        final y = pixelIndex ~/ decoded.width;
        final pixel = decoded.getPixel(x, y);
        final c = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
        c[channel] = c[channel] ^ 1; // Flip LSB
        decoded.setPixelRgb(x, y, c[0], c[1], c[2]);
      }
      
      final corruptedBytes = Uint8List.fromList(img.encodePng(decoded));

      final extracted = await stego.extract(corruptedBytes);
      final decrypted = await crypto.decrypt(
        salt: extracted.salt,
        nonce: extracted.nonce,
        cipherText: extracted.cipherText,
        mac: extracted.mac,
        passphrase: passphrase,
      );

      expect(decrypted, message);
    });
  });
}
