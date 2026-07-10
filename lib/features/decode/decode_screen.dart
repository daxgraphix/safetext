import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/step_header.dart';
import '../../shared/widgets/safetext_app_bar.dart';
import '../../shared/widgets/grid_painter.dart';
import 'providers/decode_provider.dart';
import 'widgets/decode_image_picker.dart';
import 'widgets/decode_timeline.dart';

class DecodeScreen extends ConsumerStatefulWidget {
  const DecodeScreen({super.key});

  @override
  ConsumerState<DecodeScreen> createState() => _DecodeScreenState();
}

class _DecodeScreenState extends ConsumerState<DecodeScreen> {
  final _passphraseController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    await HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    await ref.read(decodeProvider.notifier).setImage(Uint8List.fromList(bytes), picked.name);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(decodeProvider);
    final notifier = ref.read(decodeProvider.notifier);

    ref.listen(decodeProvider, (previous, next) {
      if (next.stage == DecodeStage.success) {
        context.push(AppRoutes.decodeResult);
      }
    });

    final isProcessing = state.stage == DecodeStage.decrypting || state.stage == DecodeStage.verifying;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: SafeTextAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: GridBackground(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.margin, AppSpacing.lg, AppSpacing.margin, 150),
              children: [
                StepHeader(
                  number: 1,
                  title: 'CARRIER SOURCE',
                  isDone: state.hasImage,
                ),
                const SizedBox(height: AppSpacing.md),
                DecodeImagePicker(
                  hasImage: state.hasImage,
                  imageBytes: state.imageBytes,
                  onTap: _pickImage,
                  isScanning: state.stage == DecodeStage.scanning,
                ),
                const SizedBox(height: AppSpacing.xl),
                StepHeader(
                  number: 2,
                  title: 'ANALYSIS & DETECTION',
                  isDone: state.payloadDetected,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.base),
                    border: Border.all(color: scheme.onSurface, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SYSTEM STATUS',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: scheme.onSurface,
                              letterSpacing: 0.5,
                            ),
                          ),
                          _StatusBadge(stage: state.stage),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (state.stage == DecodeStage.scanning)
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                backgroundColor: scheme.primary.withValues(alpha: 0.1),
                                color: scheme.primary,
                                minHeight: 4,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ),
                      Text(
                        _getStatusDescription(state).toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Roboto Mono',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                StepHeader(
                  number: 3,
                  title: 'DECRYPTION KEY',
                  isDone: state.passphrase.isNotEmpty,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _passphraseController,
                  obscureText: _obscure,
                  enabled: state.payloadDetected,
                  onChanged: notifier.setPassphrase,
                  style: TextStyle(fontFamily: 'Roboto Mono', color: scheme.onSurface, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'ENTER SECURE PASSPHRASE...',
                    prefixIcon: Icon(
                      _passphraseController.text.isNotEmpty ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                      size: 20,
                      color: state.payloadDetected ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                if (state.errorMessage != null && state.stage == DecodeStage.error) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppRadius.base),
                      border: Border.all(color: scheme.error, width: 2),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: scheme.error, size: 24),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                state.errorMessage!.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: scheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Divider(height: 1, color: scheme.error.withValues(alpha: 0.2)),
                        const SizedBox(height: AppSpacing.md),
                        _ActionSuggestion(
                          icon: Icons.vpn_key_outlined,
                          text: 'VERIFY PASSPHRASE PRECISION (CASE-SENSITIVE)',
                          color: scheme.error,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _ActionSuggestion(
                          icon: Icons.image_search_rounded,
                          text: 'ENSURE THIS IS THE ORIGINAL ENCODED FILE',
                          color: scheme.error,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: scheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'DECRYPTION IS PERFORMED LOCALLY. YOUR KEYS AND DATA ARE NEVER TRANSMITTED.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.surface.withValues(alpha: 0), scheme.surface],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: PrimaryButton(
                  label: 'Extract Secret',
                  icon: Icons.lock_open_rounded,
                  loading: isProcessing,
                  onPressed: state.payloadDetected && state.passphrase.isNotEmpty ? () => notifier.decode() : null,
                ),
              ),
            ),
            if (isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: DecodeTimeline(stage: state.stage),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusDescription(DecodeState state) {
    switch (state.stage) {
      case DecodeStage.idle:
        return 'Awaiting carrier selection for structural analysis...';
      case DecodeStage.scanning:
        return 'Analyzing bitstream for SafeText signatures...';
      case DecodeStage.notFound:
        return 'Analysis complete. No hidden SafeText payload detected in this image.';
      case DecodeStage.found:
        return 'Payload detected — ${state.mode} Mode. Authentication required to proceed.';
      case DecodeStage.decrypting:
      case DecodeStage.verifying:
        return 'Structural integrity verified. Finalizing decryption...';
      case DecodeStage.success:
        return 'Payload extracted successfully.';
      case DecodeStage.error:
        return 'Authentication failed or payload corrupted.';
    }
  }
}

class _ActionSuggestion extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _ActionSuggestion({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DecodeStage stage;
  const _StatusBadge({required this.stage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    final (label, color) = switch (stage) {
      DecodeStage.idle => ('AWAITING', scheme.onSurfaceVariant.withValues(alpha: 0.1)),
      DecodeStage.scanning => ('SCANNING', scheme.primary.withValues(alpha: 0.1)),
      DecodeStage.found => ('DETECTED', scheme.tertiary.withValues(alpha: 0.1)),
      DecodeStage.notFound => ('NOT FOUND', scheme.error.withValues(alpha: 0.1)),
      DecodeStage.decrypting || DecodeStage.verifying => ('DECRYPTING', scheme.primary.withValues(alpha: 0.1)),
      DecodeStage.success => ('VERIFIED', scheme.tertiary.withValues(alpha: 0.1)),
      DecodeStage.error => ('FAILED', scheme.error.withValues(alpha: 0.1)),
    };

    final textColor = switch (stage) {
      DecodeStage.idle => scheme.onSurfaceVariant,
      DecodeStage.scanning => scheme.primary,
      DecodeStage.found => scheme.tertiary,
      DecodeStage.notFound => scheme.error,
      DecodeStage.decrypting || DecodeStage.verifying => scheme.primary,
      DecodeStage.success => scheme.tertiary,
      DecodeStage.error => scheme.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: textColor, width: 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: textColor,
        ),
      ),
    );
  }
}

