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
      final r = (x * 37 + y * 91) % 256;
      final g = (x * 53 + y * 17) % 256;
      final b = (x * 13 + y * 61) % 256;
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('CryptoService failure paths', () {
    final crypto = CryptoService();

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

    test('decrypt throws DecryptionFailedException on tampered ciphertext', () async {
      final result = await crypto.encrypt('secret payload', 'right-passphrase');
      final tampered = Uint8List.fromList(result.cipherText);
      tampered[0] ^= 0xFF;

      expect(
        () => crypto.decrypt(
          salt: result.salt,
          nonce: result.nonce,
          cipherText: tampered,
          mac: result.mac,
          passphrase: 'right-passphrase',
        ),
        throwsA(isA<DecryptionFailedException>()),
      );
    });

    test('decrypt throws DecryptionFailedException on tampered mac', () async {
      final result = await crypto.encrypt('secret payload', 'right-passphrase');
      final tamperedMac = Uint8List.fromList(result.mac);
      tamperedMac[0] ^= 0xFF;

      expect(
        () => crypto.decrypt(
          salt: result.salt,
          nonce: result.nonce,
          cipherText: result.cipherText,
          mac: tamperedMac,
          passphrase: 'right-passphrase',
        ),
        throwsA(isA<DecryptionFailedException>()),
      );
    });
  });

  group('StegoService failure paths', () {
    const stego = StegoService();
    final crypto = CryptoService();
    const codec = PayloadCodec();

    test('extract throws NoPayloadFoundException on plain image', () async {
      final carrier = _generateTestPng();
      expect(() => stego.extract(carrier), throwsA(isA<NoPayloadFoundException>()));
    });

    test('extract throws NoPayloadFoundException on tiny image', () async {
      final tiny = _generateTestPng(width: 4, height: 4);
      expect(() => stego.extract(tiny), throwsA(isA<NoPayloadFoundException>()));
    });

    test('embed throws InsufficientCapacityException when message exceeds capacity', () async {
      final carrier = _generateTestPng(width: 10, height: 10);
      final hugeMessage = 'x' * 10000;
      final encryptionResult = await crypto.encrypt(hugeMessage, 'passphrase');
      final body = codec.buildBody(
        timestamp: DateTime.now(),
        salt: encryptionResult.salt,
        nonce: encryptionResult.nonce,
        cipherText: encryptionResult.cipherText,
        mac: encryptionResult.mac,
      );

      expect(
        () => stego.embed(
          imageBytes: carrier,
          bodyBytes: body,
          mode: StegoMode.ghost,
          seed: 42,
        ),
        throwsA(isA<InsufficientCapacityException>()),
      );
    });

    test('round-trip fails after tampering with one LSB bit', () async {
      const message = 'Tamper resistance test.';
      const passphrase = 'test-passphrase';
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

      final tampered = Uint8List.fromList(embedded);
      // We flip a bit in a region likely to contain the payload
      tampered[tampered.length - 20] ^= 0x01;

      expect(() => stego.extract(tampered), throwsA(anything));
    });
  });
}
