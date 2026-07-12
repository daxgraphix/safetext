import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'security_settings.g.dart';

@HiveType(typeId: 4)
class SecuritySettings {
  @HiveField(0)
  final bool darkMode;
  @HiveField(1)
  final String languageCode;
  @HiveField(2)
  final bool autoClearClipboard;
  @HiveField(3)
  final bool hideAppPreviews;
  @HiveField(4)
  final bool blockScreenshots;

  // --- Steganography defaults ---
  @HiveField(5)
  final StegoMode defaultStegoMode;
  @HiveField(6)
  final bool compressionWarningEnabled;

  // --- Password Generator defaults ---
  @HiveField(7)
  final int defaultPasswordLength;
  @HiveField(8)
  final bool passwordIncludeUppercase;
  @HiveField(9)
  final bool passwordIncludeLowercase;
  @HiveField(10)
  final bool passwordIncludeNumbers;
  @HiveField(11)
  final bool passwordIncludeSymbols;
  @HiveField(12)
  final bool passwordExcludeSimilar;
  @HiveField(13)
  final bool passwordExcludeAmbiguous;

  // --- Security Binding ---
  @HiveField(14)
  final String? deviceBindingId;

  // --- Anti-Forensic Panic ---
  @HiveField(15)
  final bool panicWipeEnabled;
  @HiveField(16)
  final int maxFailedAttempts;

  // --- Auto-Expiry ---
  @HiveField(17)
  final bool historyExpiryEnabled;
  @HiveField(18)
  final int historyExpiryDays;

  // --- App Password ---
  @HiveField(19)
  final String? appPassword; // Hashed password
  @HiveField(20)
  final bool isPasswordSet;

  const SecuritySettings({
    this.darkMode = false,
    this.languageCode = 'en',
    this.autoClearClipboard = true,
    this.hideAppPreviews = false,
    this.blockScreenshots = false,
    this.defaultStegoMode = StegoMode.ghost,
    this.compressionWarningEnabled = true,
    this.defaultPasswordLength = 16,
    this.passwordIncludeUppercase = true,
    this.passwordIncludeLowercase = true,
    this.passwordIncludeNumbers = true,
    this.passwordIncludeSymbols = true,
    this.passwordExcludeSimilar = false,
    this.passwordExcludeAmbiguous = false,
    this.deviceBindingId,
    this.panicWipeEnabled = false,
    this.maxFailedAttempts = 5,
    this.historyExpiryEnabled = false,
    this.historyExpiryDays = 30,
    this.appPassword,
    this.isPasswordSet = false,
  });

  SecuritySettings copyWith({
    bool? darkMode,
    String? languageCode,
    bool? autoClearClipboard,
    bool? hideAppPreviews,
    bool? blockScreenshots,
    StegoMode? defaultStegoMode,
    bool? compressionWarningEnabled,
    int? defaultPasswordLength,
    bool? passwordIncludeUppercase,
    bool? passwordIncludeLowercase,
    bool? passwordIncludeNumbers,
    bool? passwordIncludeSymbols,
    bool? passwordExcludeSimilar,
    bool? passwordExcludeAmbiguous,
    String? deviceBindingId,
    bool? panicWipeEnabled,
    int? maxFailedAttempts,
    bool? historyExpiryEnabled,
    int? historyExpiryDays,
    String? appPassword,
    bool? isPasswordSet,
  }) {
    return SecuritySettings(
      darkMode: darkMode ?? this.darkMode,
      languageCode: languageCode ?? this.languageCode,
      autoClearClipboard: autoClearClipboard ?? this.autoClearClipboard,
      hideAppPreviews: hideAppPreviews ?? this.hideAppPreviews,
      blockScreenshots: blockScreenshots ?? this.blockScreenshots,
      defaultStegoMode: defaultStegoMode ?? this.defaultStegoMode,
      compressionWarningEnabled: compressionWarningEnabled ?? this.compressionWarningEnabled,
      defaultPasswordLength: defaultPasswordLength ?? this.defaultPasswordLength,
      passwordIncludeUppercase: passwordIncludeUppercase ?? this.passwordIncludeUppercase,
      passwordIncludeLowercase: passwordIncludeLowercase ?? this.passwordIncludeLowercase,
      passwordIncludeNumbers: passwordIncludeNumbers ?? this.passwordIncludeNumbers,
      passwordIncludeSymbols: passwordIncludeSymbols ?? this.passwordIncludeSymbols,
      passwordExcludeSimilar: passwordExcludeSimilar ?? this.passwordExcludeSimilar,
      passwordExcludeAmbiguous: passwordExcludeAmbiguous ?? this.passwordExcludeAmbiguous,
      deviceBindingId: deviceBindingId ?? this.deviceBindingId,
      panicWipeEnabled: panicWipeEnabled ?? this.panicWipeEnabled,
      maxFailedAttempts: maxFailedAttempts ?? this.maxFailedAttempts,
      historyExpiryEnabled: historyExpiryEnabled ?? this.historyExpiryEnabled,
      historyExpiryDays: historyExpiryDays ?? this.historyExpiryDays,
      appPassword: appPassword ?? this.appPassword,
      isPasswordSet: isPasswordSet ?? this.isPasswordSet,
    );
  }
}
