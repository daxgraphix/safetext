import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers/services_providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../shared/dialogs/confirm_dialog.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/grid_painter.dart';
import '../../shared/widgets/safetext_app_bar.dart';
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
      appBar: SafeTextAppBar(
        title: 'DECRYPTION COMPLETE',
        trailing: IconButton(
          icon: Icon(Icons.info_outline_rounded, color: scheme.onSurface, size: 20),
          onPressed: () => _showDecodingGuide(context),
          tooltip: 'Security Guide',
        ),
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
                            borderRadius: BorderRadius.circular(AppRadius.sm),
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
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const Border(top: BorderSide(color: AppColors.black, width: 2.0)),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SECURITY PROTOCOLS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: scheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              const _GuideItem(text: 'NEVER STORE SENSITIVE PASSPHRASES IN PLAIN TEXT.'),
              const _GuideItem(text: 'PURGE DECRYPTED RESULTS AS SOON AS THEY ARE NO LONGER NEEDED.'),
              const _GuideItem(text: 'ENSURE YOUR DEVICE ENVIRONMENT IS SECURE BEFORE VIEWING PAYLOADS.'),
              const SizedBox(height: 24),
              PrimaryButton(label: 'CONFIRM READ', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  final String text;
  const _GuideItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.w900)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.4,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends ConsumerStatefulWidget {
  final String text;
  const _CopyButton({required this.text});

  @override
  ConsumerState<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends ConsumerState<_CopyButton> {
  bool _copied = false;

  void _handleCopy() {
    HapticFeedback.lightImpact();
    ref.read(clipboardServiceProvider).copyToClipboard(widget.text);
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: _copied ? 'COPIED (AUTO-CLEAR ACTIVE)' : 'COPY MESSAGE',
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
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (color ?? scheme.onSurface).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: (color ?? scheme.outline).withValues(alpha: 0.2), width: 2.0),
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
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.outline, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
