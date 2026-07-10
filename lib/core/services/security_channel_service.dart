import 'package:flutter/services.dart';

/// Bridges to the small native surface exposed by `MainActivity.kt`:
/// toggling `FLAG_SECURE` (screenshot / recent-apps-preview blocking) and a
/// best-effort root check for the Security Center.
///
/// All calls are best-effort and fail silently on platforms where the
/// channel isn't implemented (e.g. running the widget tree in a non-Android
/// host during development), since none of these are core to the app's
/// cryptographic guarantees — they're defense-in-depth UX affordances.
class SecurityChannelService {
  const SecurityChannelService();

  static const MethodChannel _channel = MethodChannel('com.safetext.app/security');

  Future<void> setSecureFlag(bool enabled) async {
    try {
      await _channel.invokeMethod('setSecureFlag', {'enabled': enabled});
    } on MissingPluginException {
      // No-op outside Android (e.g. desktop dev runs).
    } on PlatformException {
      // Best-effort; ignore.
    }
  }

  Future<bool> isDeviceLikelyRooted() async {
    try {
      final result = await _channel.invokeMethod<bool>('isRooted');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
