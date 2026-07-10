import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../exceptions/app_exceptions.dart';

/// Result of an encryption operation: everything needed to later decrypt,
/// ready to be laid out into the steganographic payload structure.
class EncryptionResult {
  final Uint8List salt;
  final Uint8List nonce;
  final Uint8List cipherText;
  final Uint8List mac; // authentication tag (16 bytes, AES-GCM)

  const EncryptionResult({
    required this.salt,
    required this.nonce,
    required this.cipherText,
    required this.mac,
  });
}

/// Handles all cryptographic operations for SafeText:
///
/// - **Argon2id** for passphrase -> key derivation (resists GPU/ASIC and
///   dictionary attacks far better than PBKDF2/SHA).
/// - **AES-256-GCM** for authenticated encryption of the secret message.
/// - A CSPRNG for salts, nonces, and (via [randomBytes]) embedding-location
///   seeds used by the steganography engine.
///
/// This class never logs, persists, or otherwise leaks plaintext, keys, or
/// passphrases — everything lives only in local memory for the duration of
/// a single encode/decode operation.
class CryptoService {
  CryptoService();

  static const int saltLength = 16;
  static const int nonceLength = 12; // 96-bit GCM nonce
  static const int keyLength = 32; // AES-256

  static final Random _secureRandom = Random.secure();
  static final RegExp _hasUpper = RegExp(r'[A-Z]');
  static final RegExp _hasLower = RegExp(r'[a-z]');
  static final RegExp _hasDigit = RegExp(r'[0-9]');
  static final RegExp _hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\[\]/\\+=~`]');

  final Argon2id _argon2 = Argon2id(
    memory: 19456, // ~19 MB, OWASP-recommended minimum for Argon2id
    iterations: 2,
    parallelism: 1,
    hashLength: keyLength,
  );

  /// Derives a 256-bit key from [passphrase] and [salt] using Argon2id.
  Future<SecretKey> _deriveKey(String passphrase, Uint8List salt) async {
    final newSecretKey = await _argon2.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
    return newSecretKey;
  }

  /// Generates cryptographically secure random bytes (CSPRNG, backed by the
  /// platform's `/dev/urandom` via `dart:math`'s `Random.secure()`). Used
  /// for salts, nonces, and by [StegoService] for randomized pixel-region
  /// selection in Ghost Mode.
  Uint8List randomBytes(int length) {
    return Uint8List.fromList(List<int>.generate(length, (_) => _secureRandom.nextInt(256)));
  }

  /// Encrypts [plainText] with a key derived from [passphrase]. Returns the
  /// salt, nonce, ciphertext and auth tag needed to reverse the operation.
  Future<EncryptionResult> encrypt(String plainText, String passphrase) async {
    final salt = randomBytes(saltLength);
    final key = await _deriveKey(passphrase, salt);
    final algorithm = AesGcm.with256bits(nonceLength: nonceLength);

    final secretBox = await algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: key,
    );

    return EncryptionResult(
      salt: salt,
      nonce: Uint8List.fromList(secretBox.nonce),
      cipherText: Uint8List.fromList(secretBox.cipherText),
      mac: Uint8List.fromList(secretBox.mac.bytes),
    );
  }

  /// Decrypts a payload previously produced by [encrypt]. Throws
  /// [DecryptionFailedException] if the passphrase is wrong or the payload
  /// has been tampered with (GCM authentication failure).
  Future<String> decrypt({
    required Uint8List salt,
    required Uint8List nonce,
    required Uint8List cipherText,
    required Uint8List mac,
    required String passphrase,
  }) async {
    try {
      final key = await _deriveKey(passphrase, salt);
      final algorithm = AesGcm.with256bits(nonceLength: nonceLength);

      final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
      final clearBytes = await algorithm.decrypt(secretBox, secretKey: key);
      return utf8.decode(clearBytes);
    } catch (_) {
      throw const DecryptionFailedException();
    }
  }

  /// Rough 0-4 passphrase strength scoring used to drive the strength meter
  /// on the Encode screen. Not a substitute for the KDF's own hardness —
  /// purely a UX signal.
  int passphraseStrengthScore(String passphrase) {
    if (passphrase.isEmpty) return 0;
    int score = 0;
    if (passphrase.length >= 8) score++;
    if (passphrase.length >= 12) score++;
    if (_hasUpper.hasMatch(passphrase) && _hasLower.hasMatch(passphrase)) score++;
    if (_hasDigit.hasMatch(passphrase)) score++;
    if (_hasSpecial.hasMatch(passphrase)) score++;
    return score.clamp(0, 4);
  }

  String passphraseStrengthLabel(int score) {
    switch (score) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
      case 3:
        return 'Moderate';
      default:
        return 'Strong';
    }
  }
}
