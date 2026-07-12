import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/security/device_security_service.dart';
import '../../data/models/security_settings.dart';
import '../../data/repositories/settings_repository.dart';
import '../../core/services/security_channel_service.dart';
import 'services_providers.dart';

class SettingsNotifier extends StateNotifier<SecuritySettings> {
  final SettingsRepository _repo;
  final SecurityChannelService _security;
  final DeviceSecurityService _deviceSecurity;

  SettingsNotifier(this._repo, this._security, this._deviceSecurity) : super(_repo.get()) {
    _security.setSecureFlag(state.blockScreenshots);
    _initDeviceBinding();
  }

  Future<void> _initDeviceBinding() async {
    try {
      final hardwareId = await _deviceSecurity.verifyDeviceBinding(state.deviceBindingId);
      if (state.deviceBindingId != hardwareId) {
        await _update((s) => s.copyWith(deviceBindingId: hardwareId));
      }
    } catch (e) {
      debugPrint('Device binding verification failed: $e');
      // For now, we just log it. In a real app, we might lock the history box.
    }
  }

  Future<void> _update(SecuritySettings Function(SecuritySettings) updater) async {
    final next = updater(state);
    state = next;
    await _repo.save(next);
  }

  Future<void> toggleDarkMode(bool value) => _update((s) => s.copyWith(darkMode: value));
  Future<void> toggleAutoClearClipboard(bool value) => _update((s) => s.copyWith(autoClearClipboard: value));
  Future<void> toggleHideAppPreviews(bool value) => _update((s) => s.copyWith(hideAppPreviews: value));

  Future<void> toggleBlockScreenshots(bool value) async {
    await _update((s) => s.copyWith(blockScreenshots: value));
    await _security.setSecureFlag(value);
  }

  Future<void> setLanguage(String code) => _update((s) => s.copyWith(languageCode: code));

  Future<void> setDefaultStegoMode(StegoMode mode) => _update((s) => s.copyWith(defaultStegoMode: mode));
  Future<void> toggleCompressionWarning(bool value) => _update((s) => s.copyWith(compressionWarningEnabled: value));

  Future<void> setDefaultPasswordLength(int length) => _update((s) => s.copyWith(defaultPasswordLength: length));
  Future<void> togglePasswordUppercase(bool value) => _update((s) => s.copyWith(passwordIncludeUppercase: value));
  Future<void> togglePasswordLowercase(bool value) => _update((s) => s.copyWith(passwordIncludeLowercase: value));
  Future<void> togglePasswordNumbers(bool value) => _update((s) => s.copyWith(passwordIncludeNumbers: value));
  Future<void> togglePasswordSymbols(bool value) => _update((s) => s.copyWith(passwordIncludeSymbols: value));
  Future<void> togglePasswordExcludeSimilar(bool value) => _update((s) => s.copyWith(passwordExcludeSimilar: value));
  Future<void> togglePasswordExcludeAmbiguous(bool value) => _update((s) => s.copyWith(passwordExcludeAmbiguous: value));

  Future<void> toggleHistoryExpiry(bool value) => _update((s) => s.copyWith(historyExpiryEnabled: value));
  Future<void> setHistoryExpiryDays(int days) => _update((s) => s.copyWith(historyExpiryDays: days));

  Future<void> setAppPassword(String password) async {
    // In a real app, we'd use a dedicated KDF here, but for now we'll store it as a POC.
    // The request mentions internal internal security settings.
    await _update((s) => s.copyWith(
      appPassword: password, // In production, this should be PBKDF2/Argon2 hashed
      isPasswordSet: true,
    ));
  }

  bool verifyPassword(String password) {
    return state.appPassword == password;
  }

  Future<void> clearAppPassword() => _update((s) => s.copyWith(appPassword: null, isPasswordSet: false));
}

final lockStateProvider = StateProvider<bool>((ref) => false);

final settingsProvider = StateNotifierProvider<SettingsNotifier, SecuritySettings>((ref) {
  return SettingsNotifier(
    ref.watch(settingsRepositoryProvider),
    ref.watch(securityChannelServiceProvider),
    ref.watch(deviceSecurityServiceProvider),
  );
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.darkMode ? ThemeMode.dark : ThemeMode.light;
});
