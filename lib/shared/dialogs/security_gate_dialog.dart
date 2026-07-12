import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../app/providers/settings_providers.dart';
import '../../app/theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/pin_input_field.dart';

class SecurityGateDialog extends ConsumerStatefulWidget {
  final String title;
  final String message;
  final bool allowBiometrics;

  const SecurityGateDialog({
    super.key,
    this.title = 'SECURITY GATE',
    this.message = 'AUTHENTICATION IS REQUIRED TO ACCESS THIS FEATURE.',
    this.allowBiometrics = true,
  });

  static Future<bool> show(BuildContext context, {String? title, String? message, bool allowBiometrics = true}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SecurityGateDialog(
        title: title ?? 'SECURITY GATE',
        message: message ?? 'AUTHENTICATION IS REQUIRED TO ACCESS THIS FEATURE.',
        allowBiometrics: allowBiometrics,
      ),
    );
    return result ?? false;
  }

  @override
  ConsumerState<SecurityGateDialog> createState() => _SecurityGateDialogState();
}

class _SecurityGateDialogState extends ConsumerState<SecurityGateDialog> {
  final _controller = TextEditingController();
  final _auth = LocalAuthentication();
  String? _error;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    if (widget.allowBiometrics) {
      _checkBiometrics();
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (canCheck && isSupported) {
        final availableBiometrics = await _auth.getAvailableBiometrics();
        if (availableBiometrics.isNotEmpty) {
          setState(() => _isBiometricAvailable = true);
          // Auto-trigger biometrics
          _authenticateWithBiometrics();
        }
      }
    } catch (e) {
      debugPrint('Biometric check error: $e');
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: widget.message,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (authenticated && mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(true);
      }
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: $e');
    }
  }

  void _verify() {
    final notifier = ref.read(settingsProvider.notifier);
    if (notifier.verifyPassword(_controller.text)) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = 'INVALID PIN/PASSWORD';
        _controller.clear();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: scheme.onSurface, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: scheme.onSurface, width: 2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: scheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.0,
                        fontFamily: 'Roboto Mono',
                      ),
                    ),
                  ),
                  if (_isBiometricAvailable)
                    IconButton(
                      icon: const Icon(Icons.fingerprint_rounded),
                      onPressed: _authenticateWithBiometrics,
                      tooltip: 'USE BIOMETRICS',
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.message.toUpperCase(),
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      letterSpacing: 0.5,
                      fontFamily: 'Roboto Mono',
                    ),
                  ),
                  const SizedBox(height: 24),
                  PinInputField(
                    controller: _controller,
                    labelText: 'ENTER APP PIN/PASSWORD',
                    errorText: _error,
                    onSubmitted: _verify,
                    autofocus: true,
                  ),
                ],
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.02),
                border: Border(top: BorderSide(color: scheme.onSurface, width: 2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'CANCEL',
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'UNLOCK',
                      onPressed: _verify,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
