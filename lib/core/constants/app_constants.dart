/// Global, static constants used across SafeText.
///
/// Keeping these centralized avoids magic numbers/strings scattered across
/// the feature layer and makes tuning (e.g. capacity thresholds) trivial.
class AppConstants {
  AppConstants._();

  static const String appName = 'SafeText';
  static const String appTagline = 'Private Messages Hidden in Plain Sight';
  static const String appVersion = '2.4.1';
  static const String appBuild = '4022';

  // Steganography
  static const int magicHeader = 0x53545854; // "STXT"
  static const int formatVersion = 1;
  static const int maxMessageChars = 2000;
  static const int minPassphraseLength = 8;

  /// Bits of the carrier image reserved per channel for LSB embedding.
  static const int bitsPerChannel = 1;

  /// Recommended safe-usage ceiling (% of theoretical max capacity) to keep
  /// statistical detectability low.
  static const double recommendedCapacityRatio = 0.35;

  // Hive box names
  static const String historyBoxName = 'safetext_history';
  static const String settingsBoxName = 'safetext_settings';

  // Onboarding
  static const String prefsOnboardingCompleteKey = 'onboarding_complete';

  // Supported image types
  static const List<String> supportedImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const int maxImageSizeBytes = 20 * 1024 * 1024; // 20MB
}

enum StegoMode { ghost, armor }

extension StegoModeX on StegoMode {
  String get label => this == StegoMode.ghost ? 'Ghost Mode' : 'Armor Mode';
  String get id => this == StegoMode.ghost ? 'ghost' : 'armor';
  int get modeCode => this == StegoMode.ghost ? 0 : 1;

  static StegoMode fromId(String id) {
    return id == 'armor' ? StegoMode.armor : StegoMode.ghost;
  }
}
