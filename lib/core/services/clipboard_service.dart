import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers/settings_providers.dart';

class ClipboardService {
  final Ref _ref;
  Timer? _clearTimer;

  ClipboardService(this._ref);

  Future<void> copyToClipboard(String text, {Duration? overrideTimeout}) async {
    await Clipboard.setData(ClipboardData(text: text));
    
    final settings = _ref.read(settingsProvider);
    if (settings.autoClearClipboard) {
      _startAutoClearTimer(overrideTimeout ?? const Duration(minutes: 1));
    }
  }

  void _startAutoClearTimer(Duration timeout) {
    _clearTimer?.cancel();
    _clearTimer = Timer(timeout, () async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  void dispose() {
    _clearTimer?.cancel();
  }
}

final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  final service = ClipboardService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
