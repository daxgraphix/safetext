import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../shared/dialogs/confirm_dialog.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/grid_painter.dart';
import '../encode/widgets/particle_burst.dart';
import 'providers/decode_provider.dart';
import 'widgets/typing_text.dart';

class DecodeResultScreen extends ConsumerWidget {
  const DecodeResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(decodeProvider);
    final message = state.decryptedMessage ?? '';

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        shape: const Border(bottom: BorderSide(color: Colors.white, width: 2)),
        title: const Text(
          'DECRYPTION COMPLETE',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
            onPressed: () => _showDecodingGuide(context),
            tooltip: 'Security Guide',
          ),
        ],
      ),
      body: GridBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ParticleBurst(color: scheme.tertiary),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(AppRadius.base),
                            border: Border.all(
                              color: scheme.tertiary,
                              width: 2,
                            ),
                          ),
                          child: Icon(Icons.verified_user_rounded, color: scheme.tertiary, size: 48),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'SECURE PAYLOAD EXTRACTED',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: scheme.tertiary, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, size: 14, color: scheme.tertiary),
                    const SizedBox(width: 8),
                    Text(
                      'INTEGRITY VERIFIED',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: scheme.tertiary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: scheme.outline, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.terminal_rounded, size: 14, color: AppColors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'SECURE CONTENT PAYLOAD',
                        style: TextStyle(
                          fontFamily: 'Roboto Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: AppColors.green,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'AES-256-GCM',
                        style: TextStyle(
                          fontFamily: 'Roboto Mono',
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: Colors.white24),
                  ),
                  TypingText(
                    text: message,
                    style: const TextStyle(
                      fontFamily: 'Roboto Mono',
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 6),
                      Text(
                        'END-TO-END ENCRYPTED SESSION ACTIVE',
                        style: TextStyle(
                          fontFamily: 'Roboto Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _DetailTile(
                    icon: Icons.fingerprint_rounded,
                    label: 'Security Mode',
                    value: '${state.mode} Mode',
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _DetailTile(
                    icon: Icons.enhanced_encryption_rounded,
                    label: 'Cipher Spec',
                    value: 'Argon2id + GCM',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _CopyButton(text: message),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'SHARE CONTENT',
                    icon: Icons.share_rounded,
                    onPressed: () => Share.share(message),
                  ),
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.delete_sweep_rounded,
                  color: scheme.error,
                  onPressed: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: 'PURGE DATA?',
                      message: 'THIS WILL CLEAR THE DECRYPTED TEXT FROM MEMORY.',
                      confirmLabel: 'PURGE',
                      danger: true,
                    );
                    if (confirmed && context.mounted) {
                      ref.read(decodeProvider.notifier).reset();
                      context.pop();
                      context.pop();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  ref.read(decodeProvider.notifier).reset();
                  context.go(AppRoutes.home);
                },
                icon: Icon(Icons.home_filled, size: 18, color: scheme.onSurface),
                label: Text(
                  'BACK TO DASHBOARD',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDecodingGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Security Best Practices', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontFamily: 'Inter')),
              const SizedBox(height: 12),
              const Text('• Never store sensitive passphrases in plain text.\n• Purge decrypted results as soon as they are no longer needed.\n• Ensure your device environment is secure before viewing payloads.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.5)),
              const SizedBox(height: 20),
              PrimaryButton(label: 'I Understand', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String text;
  const _CopyButton({required this.text});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  void _handleCopy() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: _copied ? 'Copied to Clipboard' : 'Copy Message',
      icon: _copied ? Icons.check_circle_rounded : Icons.copy_all_rounded,
      onPressed: _handleCopy,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const _ActionButton({required this.icon, required this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (color ?? scheme.onSurface).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (color ?? scheme.outlineVariant).withValues(alpha: 0.2)),
          ),
          child: Icon(icon, size: 22, color: color ?? scheme.onSurface),
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
