import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../exceptions/app_exceptions.dart';

/// A from-scratch, textbook-standard DES (Data Encryption Standard)
/// implementation used exclusively by the **LSB with DES** steganography
/// mode.
///
/// ### DEPRECATED — EDUCATIONAL USE ONLY
/// DES is a legacy 56-bit-key cipher and is **not** cryptographically
/// strong by modern standards (56 bits is brute-forceable with commodity
/// hardware). It is included as a distinct, clearly-labeled "classic
/// cipher" workflow for interoperability/education purposes, exactly like
/// the Caesar Cipher module — **not** as a recommended way to protect real
/// secrets. SafeText's core encoder (`CryptoService`) uses AES-256-GCM with
/// an Argon2id-derived key and remains the only mode recommended for
/// anything sensitive; the UI for this module says so explicitly.
///
/// ### Mode of operation
/// CBC with PKCS7 padding and a random 8-byte IV (CSPRNG), prepended to the
/// ciphertext on output — a minimal, standard construction for a block
/// cipher operating on arbitrary-length text.
class DesCryptoService {
  const DesCryptoService();

  static const int blockSizeBytes = 8;

  // ---------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------

  /// Encrypts [plainText] with a key derived from [keyText]. Returns
  /// `IV (8 bytes) || ciphertext`.
  Future<Uint8List> encrypt(String plainText, String keyText) async {
    final key = await _deriveKeyBytes(keyText);
    final subkeys = _generateSubkeys(key);
    final iv = _randomBytes(blockSizeBytes);

    final padded = _pkcs7Pad(Uint8List.fromList(utf8.encode(plainText)));

    final output = BytesBuilder();
    output.add(iv);

    Uint8List previous = iv;
    for (int offset = 0; offset < padded.length; offset += blockSizeBytes) {
      final block = padded.sublist(offset, offset + blockSizeBytes);
      final xored = _xorBytes(block, previous);
      final cipherBlock = _desBlock(xored, subkeys, encrypt: true);
      output.add(cipherBlock);
      previous = cipherBlock;
    }

    return output.toBytes();
  }

  /// Decrypts `IV (8 bytes) || ciphertext` produced by [encrypt].
  Future<String> decrypt(Uint8List ivAndCipherText, String keyText) async {
    if (ivAndCipherText.length < blockSizeBytes * 2 || ivAndCipherText.length % blockSizeBytes != 0) {
      throw const DecryptionFailedException('Corrupted DES payload.');
    }

    final key = await _deriveKeyBytes(keyText);
    final subkeys = _generateSubkeys(key);
    final iv = ivAndCipherText.sublist(0, blockSizeBytes);
    final cipherText = ivAndCipherText.sublist(blockSizeBytes);

    final output = BytesBuilder();
    Uint8List previous = iv;
    for (int offset = 0; offset < cipherText.length; offset += blockSizeBytes) {
      final block = cipherText.sublist(offset, offset + blockSizeBytes);
      final decryptedBlock = _desBlock(block, subkeys, encrypt: false);
      final plainBlock = _xorBytes(decryptedBlock, previous);
      output.add(plainBlock);
      previous = block;
    }

    try {
      final unpadded = _pkcs7Unpad(output.toBytes());
      return utf8.decode(unpadded);
    } catch (_) {
      // Wrong key -> garbage bytes -> invalid padding almost every time.
      throw const DecryptionFailedException('Incorrect DES key or corrupted payload.');
    }
  }

  // ---------------------------------------------------------------------
  // Key derivation: arbitrary-length key text -> exactly 8 key bytes
  // ---------------------------------------------------------------------

  Future<Uint8List> _deriveKeyBytes(String keyText) async {
    final digest = await Sha256().hash(utf8.encode(keyText));
    return Uint8List.fromList(digest.bytes.sublist(0, 8));
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => random.nextInt(256)));
  }

  // ---------------------------------------------------------------------
  // PKCS7 padding
  // ---------------------------------------------------------------------

  Uint8List _pkcs7Pad(Uint8List data) {
    final padLength = blockSizeBytes - (data.length % blockSizeBytes);
    final padded = Uint8List(data.length + padLength);
    padded.setRange(0, data.length, data);
    for (int i = data.length; i < padded.length; i++) {
      padded[i] = padLength;
    }
    return padded;
  }

  Uint8List _pkcs7Unpad(Uint8List data) {
    if (data.isEmpty) throw const FormatException('Empty payload');
    final padLength = data.last;
    if (padLength < 1 || padLength > blockSizeBytes || padLength > data.length) {
      throw const FormatException('Invalid PKCS7 padding');
    }
    for (int i = data.length - padLength; i < data.length; i++) {
      if (data[i] != padLength) throw const FormatException('Invalid PKCS7 padding');
    }
    return data.sublist(0, data.length - padLength);
  }

  Uint8List _xorBytes(Uint8List a, Uint8List b) {
    final out = Uint8List(a.length);
    for (int i = 0; i < a.length; i++) {
      out[i] = a[i] ^ b[i];
    }
    return out;
  }

  // ---------------------------------------------------------------------
  // Core DES block cipher (textbook algorithm, bit-array implementation)
  // ---------------------------------------------------------------------

  Uint8List _desBlock(Uint8List block8Bytes, List<List<int>> subkeys, {required bool encrypt}) {
    var bits = _bytesToBits(block8Bytes);
    bits = _permute(bits, _ip);

    var left = bits.sublist(0, 32);
    var right = bits.sublist(32, 64);

    final orderedKeys = encrypt ? subkeys : subkeys.reversed.toList();

    for (int round = 0; round < 16; round++) {
      final newRight = _xorBits(left, _feistel(right, orderedKeys[round]));
      left = right;
      right = newRight;
    }

    final combined = [...right, ...left]; // final swap
    final output = _permute(combined, _fp);
    return _bitsToBytes(output);
  }

  List<int> _feistel(List<int> right32, List<int> subkey48) {
    final expanded = _permute(right32, _e); // 32 -> 48
    final xored = _xorBits(expanded, subkey48);

    final sboxOutput = <int>[];
    for (int i = 0; i < 8; i++) {
      final chunk = xored.sublist(i * 6, i * 6 + 6);
      final row = (chunk[0] << 1) | chunk[5];
      final col = (chunk[1] << 3) | (chunk[2] << 2) | (chunk[3] << 1) | chunk[4];
      final value = _sBoxes[i][row * 16 + col];
      sboxOutput.addAll(_intToBits(value, 4));
    }

    return _permute(sboxOutput, _p); // 32 -> 32
  }

  List<List<int>> _generateSubkeys(Uint8List key8Bytes) {
    final keyBits = _bytesToBits(key8Bytes);
    final permuted = _permute(keyBits, _pc1); // 64 -> 56

    var c = permuted.sublist(0, 28);
    var d = permuted.sublist(28, 56);

    final subkeys = <List<int>>[];
    for (int round = 0; round < 16; round++) {
      c = _rotateLeft(c, _shiftSchedule[round]);
      d = _rotateLeft(d, _shiftSchedule[round]);
      final combined = [...c, ...d];
      subkeys.add(_permute(combined, _pc2)); // 56 -> 48
    }
    return subkeys;
  }

  // ---------------------------------------------------------------------
  // Bit-level helpers
  // ---------------------------------------------------------------------

  List<int> _bytesToBits(Uint8List bytes) {
    final bits = <int>[];
    for (final byte in bytes) {
      for (int i = 7; i >= 0; i--) {
        bits.add((byte >> i) & 1);
      }
    }
    return bits;
  }

  Uint8List _bitsToBytes(List<int> bits) {
    final bytes = Uint8List(bits.length ~/ 8);
    for (int i = 0; i < bytes.length; i++) {
      int value = 0;
      for (int b = 0; b < 8; b++) {
        value = (value << 1) | bits[i * 8 + b];
      }
      bytes[i] = value;
    }
    return bytes;
  }

  List<int> _intToBits(int value, int width) {
    return List<int>.generate(width, (i) => (value >> (width - 1 - i)) & 1);
  }

  List<int> _permute(List<int> input, List<int> table) {
    return List<int>.generate(table.length, (i) => input[table[i]]);
  }

  List<int> _xorBits(List<int> a, List<int> b) {
    return List<int>.generate(a.length, (i) => a[i] ^ b[i]);
  }

  List<int> _rotateLeft(List<int> bits, int n) {
    return [...bits.sublist(n), ...bits.sublist(0, n)];
  }

  // ---------------------------------------------------------------------
  // Standard DES tables (0-indexed; classic textbook definitions).
  // ---------------------------------------------------------------------

  static const List<int> _ip = [
    57, 49, 41, 33, 25, 17, 9, 1, 59, 51, 43, 35, 27, 19, 11, 3,
    61, 53, 45, 37, 29, 21, 13, 5, 63, 55, 47, 39, 31, 23, 15, 7,
    56, 48, 40, 32, 24, 16, 8, 0, 58, 50, 42, 34, 26, 18, 10, 2,
    60, 52, 44, 36, 28, 20, 12, 4, 62, 54, 46, 38, 30, 22, 14, 6,
  ];

  static const List<int> _fp = [
    39, 7, 47, 15, 55, 23, 63, 31, 38, 6, 46, 14, 54, 22, 62, 30,
    37, 5, 45, 13, 53, 21, 61, 29, 36, 4, 44, 12, 52, 20, 60, 28,
    35, 3, 43, 11, 51, 19, 59, 27, 34, 2, 42, 10, 50, 18, 58, 26,
    33, 1, 41, 9, 49, 17, 57, 25, 32, 0, 40, 8, 48, 16, 56, 24,
  ];

  static const List<int> _e = [
    31, 0, 1, 2, 3, 4, 3, 4, 5, 6, 7, 8, 7, 8, 9, 10,
    11, 12, 11, 12, 13, 14, 15, 16, 15, 16, 17, 18, 19, 20, 19, 20,
    21, 22, 23, 24, 23, 24, 25, 26, 27, 28, 27, 28, 29, 30, 31, 0,
  ];

  static const List<int> _p = [
    15, 6, 19, 20, 28, 11, 27, 16, 0, 14, 22, 25, 4, 17, 30, 9,
    1, 7, 23, 13, 31, 26, 2, 8, 18, 12, 29, 5, 21, 10, 3, 24,
  ];

  static const List<int> _pc1 = [
    56, 48, 40, 32, 24, 16, 8, 0, 57, 49, 41, 33, 25, 17,
    9, 1, 58, 50, 42, 34, 26, 18, 10, 2, 59, 51, 43, 35,
    62, 54, 46, 38, 30, 22, 14, 6, 61, 53, 45, 37, 29, 21,
    13, 5, 60, 52, 44, 36, 28, 20, 12, 4, 27, 19, 11, 3,
  ];

  static const List<int> _pc2 = [
    13, 16, 10, 23, 0, 4, 2, 27, 14, 5, 20, 9,
    22, 18, 11, 3, 25, 7, 15, 6, 26, 19, 12, 1,
    40, 51, 30, 36, 46, 54, 29, 39, 50, 44, 32, 47,
    43, 48, 38, 55, 33, 52, 45, 41, 49, 35, 28, 31,
  ];

  static const List<int> _shiftSchedule = [1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1];

  static const List<List<int>> _sBoxes = [
    [
      14, 4, 13, 1, 2, 15, 11, 8, 3, 10, 6, 12, 5, 9, 0, 7,
      0, 15, 7, 4, 14, 2, 13, 1, 10, 6, 12, 11, 9, 5, 3, 8,
      4, 1, 14, 8, 13, 6, 2, 11, 15, 12, 9, 7, 3, 10, 5, 0,
      15, 12, 8, 2, 4, 9, 1, 7, 5, 11, 3, 14, 10, 0, 6, 13,
    ],
    [
      15, 1, 8, 14, 6, 11, 3, 4, 9, 7, 2, 13, 12, 0, 5, 10,
      3, 13, 4, 7, 15, 2, 8, 14, 12, 0, 1, 10, 6, 9, 11, 5,
      0, 14, 7, 11, 10, 4, 13, 1, 5, 8, 12, 6, 9, 3, 2, 15,
      13, 8, 10, 1, 3, 15, 4, 2, 11, 6, 7, 12, 0, 5, 14, 9,
    ],
    [
      10, 0, 9, 14, 6, 3, 15, 5, 1, 13, 12, 7, 11, 4, 2, 8,
      13, 7, 0, 9, 3, 4, 6, 10, 2, 8, 5, 14, 12, 11, 15, 1,
      13, 6, 4, 9, 8, 15, 3, 0, 11, 1, 2, 12, 5, 10, 14, 7,
      1, 10, 13, 0, 6, 9, 8, 7, 4, 15, 14, 3, 11, 5, 2, 12,
    ],
    [
      7, 13, 14, 3, 0, 6, 9, 10, 1, 2, 8, 5, 11, 12, 4, 15,
      13, 8, 11, 5, 6, 15, 0, 3, 4, 7, 2, 12, 1, 10, 14, 9,
      10, 6, 9, 0, 12, 11, 7, 13, 15, 1, 3, 14, 5, 2, 8, 4,
      3, 15, 0, 6, 10, 1, 13, 8, 9, 4, 5, 11, 12, 7, 2, 14,
    ],
    [
      2, 12, 4, 1, 7, 10, 11, 6, 8, 5, 3, 15, 13, 0, 14, 9,
      14, 11, 2, 12, 4, 7, 13, 1, 5, 0, 15, 10, 3, 9, 8, 6,
      4, 2, 1, 11, 10, 13, 7, 8, 15, 9, 12, 5, 6, 3, 0, 14,
      11, 8, 12, 7, 1, 14, 2, 13, 6, 15, 0, 9, 10, 4, 5, 3,
    ],
    [
      12, 1, 10, 15, 9, 2, 6, 8, 0, 13, 3, 4, 14, 7, 5, 11,
      10, 15, 4, 2, 7, 12, 9, 5, 6, 1, 13, 14, 0, 11, 3, 8,
      9, 14, 15, 5, 2, 8, 12, 3, 7, 0, 4, 10, 1, 13, 11, 6,
      4, 3, 2, 12, 9, 5, 15, 10, 11, 14, 1, 7, 6, 0, 8, 13,
    ],
    [
      4, 11, 2, 14, 15, 0, 8, 13, 3, 12, 9, 7, 5, 10, 6, 1,
      13, 0, 11, 7, 4, 9, 1, 10, 14, 3, 5, 12, 2, 15, 8, 6,
      1, 4, 11, 13, 12, 3, 7, 14, 10, 15, 6, 8, 0, 5, 9, 2,
      6, 11, 13, 8, 1, 4, 10, 7, 9, 5, 0, 15, 14, 2, 3, 12,
    ],
    [
      13, 2, 8, 4, 6, 15, 11, 1, 10, 9, 3, 14, 5, 0, 12, 7,
      1, 15, 13, 8, 10, 3, 7, 4, 12, 5, 6, 11, 0, 14, 9, 2,
      7, 11, 4, 1, 9, 12, 14, 2, 0, 6, 10, 13, 15, 3, 5, 8,
      2, 1, 14, 7, 4, 10, 8, 13, 15, 12, 9, 0, 3, 5, 6, 11,
    ],
  ];
}
