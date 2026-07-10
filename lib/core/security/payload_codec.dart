import 'dart:typed_data';

import '../constants/app_constants.dart';
import 'crypto_service.dart';

/// Binary layout of the data hidden inside a carrier image.
///
/// ```
/// HEADER (18 bytes, always sequential / first bits of the image):
///   magic        4 bytes  0x53545854 ("STXT")
///   version      1 byte
///   mode         1 byte   0 = ghost, 1 = armor
///   seed         8 bytes  PRNG seed for Ghost Mode pixel selection
///   bodyLength   4 bytes  length in bytes of BODY below
///
/// BODY (bodyLength bytes, sequential for Armor / seeded-random for Ghost):
///   timestamp    8 bytes  epoch millis
///   salt         16 bytes Argon2id salt
///   nonce        12 bytes AES-GCM nonce
///   cipherLen    4 bytes
///   cipherText   cipherLen bytes
///   mac          16 bytes AES-GCM authentication tag
///   checksum     4 bytes  CRC32 of everything above in BODY
/// ```
class SafeTextPayload {
  final int mode; // 0 ghost, 1 armor
  final int seed;
  final DateTime timestamp;
  final Uint8List salt;
  final Uint8List nonce;
  final Uint8List cipherText;
  final Uint8List mac;

  const SafeTextPayload({
    required this.mode,
    required this.seed,
    required this.timestamp,
    required this.salt,
    required this.nonce,
    required this.cipherText,
    required this.mac,
  });

  bool get isGhost => mode == 0;
}

class HeaderInfo {
  final int version;
  final int mode;
  final int seed;
  final int bodyLength;
  const HeaderInfo({
    required this.version,
    required this.mode,
    required this.seed,
    required this.bodyLength,
  });
}

/// Serializes / deserializes [SafeTextPayload] to/from raw bytes, and
/// computes the CRC32 integrity checksum embedded in every payload.
class PayloadCodec {
  const PayloadCodec();

  static const int headerLengthBytes = 4 + 1 + 1 + 8 + 4; // 18

  Uint8List buildHeader({required int mode, required int seed, required int bodyLength}) {
    final buffer = ByteData(headerLengthBytes);
    buffer.setUint32(0, AppConstants.magicHeader, Endian.big);
    buffer.setUint8(4, AppConstants.formatVersion);
    buffer.setUint8(5, mode);
    buffer.setInt64(6, seed, Endian.big);
    buffer.setUint32(14, bodyLength, Endian.big);
    return buffer.buffer.asUint8List();
  }

  HeaderInfo parseHeader(Uint8List headerBytes) {
    final buffer = ByteData.sublistView(headerBytes);
    final magic = buffer.getUint32(0, Endian.big);
    if (magic != AppConstants.magicHeader) {
      throw const FormatException('Invalid SafeText magic header');
    }
    final version = buffer.getUint8(4);
    final mode = buffer.getUint8(5);
    final seed = buffer.getInt64(6, Endian.big);
    final bodyLength = buffer.getUint32(14, Endian.big);
    return HeaderInfo(version: version, mode: mode, seed: seed, bodyLength: bodyLength);
  }

  Uint8List buildBody({
    required DateTime timestamp,
    required Uint8List salt,
    required Uint8List nonce,
    required Uint8List cipherText,
    required Uint8List mac,
  }) {
    final builder = BytesBuilder();
    final tsBuffer = ByteData(8)..setInt64(0, timestamp.millisecondsSinceEpoch, Endian.big);
    builder.add(tsBuffer.buffer.asUint8List());
    builder.add(salt);
    builder.add(nonce);
    final lenBuffer = ByteData(4)..setUint32(0, cipherText.length, Endian.big);
    builder.add(lenBuffer.buffer.asUint8List());
    builder.add(cipherText);
    builder.add(mac);

    final withoutChecksum = builder.toBytes();
    final checksum = crc32(withoutChecksum);
    final checksumBuffer = ByteData(4)..setUint32(0, checksum, Endian.big);

    final full = BytesBuilder();
    full.add(withoutChecksum);
    full.add(checksumBuffer.buffer.asUint8List());
    return full.toBytes();
  }

  SafeTextPayload parseBody(Uint8List body, {required int mode, required int seed}) {
    if (body.length < 8 + CryptoService.saltLength + CryptoService.nonceLength + 4 + 16 + 4) {
      throw const FormatException('Payload body too short');
    }
    final buffer = ByteData.sublistView(body);
    final tsMillis = buffer.getInt64(0, Endian.big);
    int offset = 8;

    final salt = body.sublist(offset, offset + CryptoService.saltLength);
    offset += CryptoService.saltLength;

    final nonce = body.sublist(offset, offset + CryptoService.nonceLength);
    offset += CryptoService.nonceLength;

    final cipherLen = buffer.getUint32(offset, Endian.big);
    offset += 4;

    if (offset + cipherLen + 16 + 4 > body.length) {
      throw const FormatException('Corrupted payload: length mismatch');
    }

    final cipherText = body.sublist(offset, offset + cipherLen);
    offset += cipherLen;

    final mac = body.sublist(offset, offset + 16);
    offset += 16;

    final storedChecksum = buffer.getUint32(offset, Endian.big);
    final computed = crc32(body.sublist(0, offset));
    if (storedChecksum != computed) {
      throw const FormatException('Checksum mismatch: payload corrupted or tampered');
    }

    return SafeTextPayload(
      mode: mode,
      seed: seed,
      timestamp: DateTime.fromMillisecondsSinceEpoch(tsMillis),
      salt: salt,
      nonce: nonce,
      cipherText: cipherText,
      mac: mac,
    );
  }

  /// Minimal, dependency-free CRC32 (IEEE 802.3 polynomial) implementation
  /// used purely as a fast tamper/corruption check layered underneath the
  /// cryptographic GCM auth tag (which remains the real integrity
  /// guarantee).
  int crc32(Uint8List data) {
    const int poly = 0xEDB88320;
    int crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        final mask = -(crc & 1);
        crc = (crc >> 1) ^ (poly & mask);
      }
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}
