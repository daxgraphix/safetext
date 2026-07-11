import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../shared/dialogs/confirm_dialog.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/visual_diff_viewer.dart';
import '../../shared/widgets/safetext_app_bar.dart';
import '../../shared/widgets/grid_painter.dart';
import 'widgets/particle_burst.dart';
import 'providers/encode_provider.dart';

class EncodeResultScreen extends ConsumerWidget {
  const EncodeResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(encodeProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: const SafeTextAppBar(),
      body: GridBackground(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
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
                              child: Icon(Icons.verified_rounded, color: scheme.tertiary, size: 48),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'DATA SUCCESSFULLY EMBEDDED',
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'YOUR MESSAGE IS NOW CRYPTOGRAPHICALLY SECURED AND HIDDEN WITHIN THE IMAGE PIXELS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        label: 'Output Size',
                        value: Formatters.bytes(state.resultBytes?.length ?? 0),
                        icon: Icons.compress_rounded,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _InfoTile(
                        label: 'Security Mode',
                        value: state.mode == StegoMode.armor ? 'ARMOR' : 'GHOST',
                        icon: Icons.security_rounded,
                        color: scheme.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (state.resultBytes != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.base),
                          border: Border.all(color: scheme.onSurface, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.base - 2),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(state.resultBytes!, fit: BoxFit.cover),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                bottom: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: scheme.tertiary,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.lock_rounded, size: 14, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'ENCODED',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (state.isExpansionSuspicious)
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: scheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.base),
                            border: Border.all(color: scheme.error, width: 2),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: scheme.error, size: 24),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'THE RESULTING IMAGE IS ${state.expansionRatio.toStringAsFixed(1)}X LARGER. HIGH RISK OF FORENSIC DETECTION.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: scheme.error,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      SecondaryButton(
                        label: 'Visual Inspection',
                        icon: Icons.compare_arrows_rounded,
                        onPressed: () => _showVisualDiff(context, state.imageBytes!, state.resultBytes!),
                      ),
                    ],
                  ),
                const SizedBox(height: 40),
                PrimaryButton(
                  label: 'Save Secure Image',
                  icon: Icons.file_download_rounded,
                  onPressed: state.resultBytes != null
                      ? () async {
                          HapticFeedback.mediumImpact();
                          try {
                            final storage = ref.read(storageServiceProvider);
                            await storage.saveToGallery(
                              state.resultBytes!,
                              fileName: 'safetext_encoded_${DateTime.now().millisecondsSinceEpoch}.png',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('IMAGE SAVED TO GALLERY'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('FAILED TO SAVE: $e')),
                              );
                            }
                          }
                        }
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Share',
                        icon: Icons.ios_share_rounded,
                        onPressed: state.savedFile != null
                            ? () => _shareWithOptionalWarning(context, settings.compressionWarningEnabled, state.savedFile!.path)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          ref.read(encodeProvider.notifier).reset();
                          context.go(AppRoutes.home);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.base),
                            border: Border.all(color: scheme.onSurface, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              'FINISH',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w900,
                                color: scheme.onSurface,
                                fontSize: 13,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      ref.read(encodeProvider.notifier).reset();
                      context.pop();
                      context.pop();
                      context.push(AppRoutes.encode);
                    },
                    icon: Icon(Icons.add_rounded, size: 18, color: scheme.onSurface),
                    label: Text(
                      'START NEW SESSION',
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
          ],
        ),
      ),
    );
  }

  void _showVisualDiff(BuildContext context, Uint8List original, Uint8List encoded) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white, width: 2)),
        ),
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('VISUAL INSPECTION', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontFamily: 'Inter')),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: VisualDiffViewer(originalBytes: original, encodedBytes: encoded),
            ),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'SLIDE TO COMPARE THE ORIGINAL CARRIER WITH THE SECURED IMAGE. ANY VISUAL ARTIFACTS OR PIXEL SHIFTS INDICATE HIGHER RISK OF FORENSIC DETECTION.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Inter', height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareWithOptionalWarning(BuildContext context, bool warningEnabled, String path) async {
    if (warningEnabled) {
      final proceed = await showConfirmDialog(
        context,
        title: 'COMPRESSION WARNING',
        message:
            'SOME MESSAGING AND SOCIAL APPS RECOMPRESS IMAGES BEFORE SENDING, WHICH CAN DESTROY THE HIDDEN DATA. '
            'PREFER "SEND AS DOCUMENT/FILE" OPTIONS WHEN AVAILABLE.',
        confirmLabel: 'SHARE ANYWAY',
      );
      if (!proceed) return;
    }
    if (context.mounted) {
      await Share.shareXFiles([XFile(path)]);
    }
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _InfoTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: scheme.onSurface, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(label.toUpperCase(),
              style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w900, color: scheme.onSurfaceVariant, letterSpacing: 0.6)),
          const SizedBox(height: 4),
          Text(value.toUpperCase(), style: TextStyle(fontFamily: 'Roboto Mono', fontSize: 16, fontWeight: FontWeight.w900, color: scheme.onSurface)),
        ],
      ),
    );
  }
}

