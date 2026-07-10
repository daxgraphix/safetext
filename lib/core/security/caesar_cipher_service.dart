/// The Caesar Cipher — the oldest substitution cipher on record (Julius
/// Caesar reportedly used a shift of 3 for military correspondence).
///
/// Included purely as an **educational** module: it has zero
/// cryptographic strength (26 possible keys, trivially brute-forced) and
/// is never used to protect anything elsewhere in SafeText. The UI frames
/// it explicitly as a learning tool, distinct from the app's real
/// encryption (AES-256-GCM) and legacy-but-real (DES) ciphers.
class CaesarCipherService {
  const CaesarCipherService();

  static const int alphabetSize = 26;

  /// Shifts each letter of [plainText] forward by [shift] (0-25),
  /// preserving case and passing non-letters through unchanged.
  String encrypt(String plainText, int shift) => _shift(plainText, shift);

  /// Reverses [encrypt] with the same [shift].
  String decrypt(String cipherText, int shift) => _shift(cipherText, -shift);

  String _shift(String text, int shift) {
    final normalizedShift = ((shift % alphabetSize) + alphabetSize) % alphabetSize;
    final buffer = StringBuffer();

    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final code = rune;

      if (code >= 65 && code <= 90) {
        // Uppercase A-Z
        buffer.writeCharCode(((code - 65 + normalizedShift) % alphabetSize) + 65);
      } else if (code >= 97 && code <= 122) {
        // Lowercase a-z
        buffer.writeCharCode(((code - 97 + normalizedShift) % alphabetSize) + 97);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  /// Per-character shift breakdown used to drive the "Character Shift
  /// Visualization" — e.g. `[('H','K'), ('i','l')]` for shift 3.
  List<(String original, String shifted)> visualizeShift(String text, int shift) {
    final normalizedShift = ((shift % alphabetSize) + alphabetSize) % alphabetSize;
    final result = <(String, String)>[];

    for (final rune in text.runes) {
      final code = rune;
      String shiftedChar;
      if (code >= 65 && code <= 90) {
        shiftedChar = String.fromCharCode(((code - 65 + normalizedShift) % alphabetSize) + 65);
      } else if (code >= 97 && code <= 122) {
        shiftedChar = String.fromCharCode(((code - 97 + normalizedShift) % alphabetSize) + 97);
      } else {
        shiftedChar = String.fromCharCode(code);
      }
      result.add((String.fromCharCode(code), shiftedChar));
    }
    return result;
  }
}
