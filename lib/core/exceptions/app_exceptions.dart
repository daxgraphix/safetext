/// Base class for all SafeText domain exceptions. Every exception carries a
/// human-readable [message] safe to surface directly in the UI, since none
/// of these ever include key material or plaintext secrets.
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Thrown when the selected carrier image cannot hold the requested
/// message at the chosen security mode.
class InsufficientCapacityException extends AppException {
  const InsufficientCapacityException([
    super.message = 'The selected image is too small to hold this message securely.',
  ]);
}

/// Thrown when an image does not contain a recognizable SafeText payload
/// (bad magic header / version mismatch).
class NoPayloadFoundException extends AppException {
  const NoPayloadFoundException([
    super.message = 'No hidden SafeText payload was found in this image.',
  ]);
}

/// Thrown when decryption fails — almost always an incorrect passphrase,
/// but may also indicate a corrupted or tampered payload since AES-GCM is
/// an authenticated cipher.
class DecryptionFailedException extends AppException {
  const DecryptionFailedException([
    super.message = 'Decryption failed. Check your passphrase and try again.',
  ]);
}

/// Thrown when an unsupported image format or corrupted file is supplied.
class InvalidImageException extends AppException {
  const InvalidImageException([
    super.message = 'This file could not be read as a valid image.',
  ]);
}

/// Thrown for generic local storage failures (Hive / secure storage).
class StorageException extends AppException {
  const StorageException([super.message = 'A local storage error occurred.']);
}

/// Thrown when a passphrase does not meet minimum strength requirements.
class WeakPassphraseException extends AppException {
  const WeakPassphraseException([
    super.message = 'Passphrase must be at least 8 characters.',
  ]);
}

/// Thrown when a security integrity check fails.
class SecurityException extends AppException {
  const SecurityException([super.message = 'A security integrity violation was detected.']);
}
