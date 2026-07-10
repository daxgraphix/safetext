import '../../core/constants/app_constants.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../datasources/hive_boxes.dart';
import '../models/security_settings.dart';

class SettingsRepository {
  const SettingsRepository();

  static const String _key = 'settings';

  SecuritySettings get() {
    try {
      final stored = HiveBoxes.settingsBox.get(_key);
      if (stored is SecuritySettings) return stored;
      return const SecuritySettings();
    } catch (_) {
      throw const StorageException('Unable to read settings.');
    }
  }

  Future<void> save(SecuritySettings settings) async {
    try {
      await HiveBoxes.settingsBox.put(_key, settings);
    } catch (_) {
      throw const StorageException('Unable to save settings.');
    }
  }

  bool get onboardingComplete =>
      HiveBoxes.settingsBox.get(AppConstants.prefsOnboardingCompleteKey, defaultValue: false) as bool;

  Future<void> setOnboardingComplete(bool value) async {
    await HiveBoxes.settingsBox.put(AppConstants.prefsOnboardingCompleteKey, value);
  }
}
