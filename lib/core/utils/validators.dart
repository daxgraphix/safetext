import '../constants/app_constants.dart';

class Validators {
  Validators._();

  static String? passphrase(String? value) {
    if (value == null || value.isEmpty) return 'Passphrase is required';
    if (value.length < AppConstants.minPassphraseLength) {
      return 'Minimum ${AppConstants.minPassphraseLength} characters required';
    }
    return null;
  }

  static String? secretMessage(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a message to hide';
    if (value.length > AppConstants.maxMessageChars) {
      return 'Message exceeds ${AppConstants.maxMessageChars} character limit';
    }
    return null;
  }

  static bool isSupportedImage(String path) {
    final ext = path.split('.').last.toLowerCase();
    return AppConstants.supportedImageExtensions.contains(ext);
  }
}
