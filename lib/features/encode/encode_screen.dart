import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/grid_painter.dart';
import '../../shared/widgets/safetext_app_bar.dart';
import '../../shared/widgets/step_header.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import 'providers/encode_provider.dart';
import 'widgets/analysis_panel.dart';
import 'widgets/image_picker_box.dart';
import 'widgets/mode_card.dart';
import 'widgets/processing_timeline.dart';
import 'widgets/strength_meter.dart';

class EncodeScreen extends ConsumerStatefulWidget {
  const EncodeScreen({super.key});

  @override
  ConsumerState<EncodeScreen> createState() => _EncodeScreenState();
}

class _EncodeScreenState extends ConsumerState<EncodeScreen> {
  final _messageController = TextEditingController();
  final _passphraseController = TextEditingController();
  bool _obscurePassphrase = true;

  @override
  void dispose() {
    _messageController.dispose();
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
    await ref.read(encodeProvider.notifier).setImage(Uint8List.fromList(bytes), picked.name);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(encodeProvider);
    final notifier = ref.read(encodeProvider.notifier);
    final crypto = ref.read(cryptoServiceProvider);

    ref.listen(encodeProvider, (previous, next) {
      if (next.stage == EncodeStage.done) {
        context.push(AppRoutes.encodeResult);
      }
      if (next.stage == EncodeStage.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final strength = crypto.passphraseStrengthScore(state.passphrase);
    final strengthLabel = crypto.passphraseStrengthLabel(strength);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: SafeTextAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
          tooltip: 'Back',
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
                  title: 'CARRIER SELECTION',
                  isDone: state.hasImage,
                ),
                const SizedBox(height: AppSpacing.md),
                ImagePickerBox(
                  hasImage: state.hasImage,
                  imageBytes: state.imageBytes,
                  analysis: state.analysis,
                  onTap: _pickImage,
                ),
                const SizedBox(height: AppSpacing.xl),
                StepHeader(
                  number: 2,
                  title: 'DEEP ANALYSIS',
                  isDone: state.analysis != null,
                ),
                const SizedBox(height: AppSpacing.md),
                AnalysisPanel(analyzing: state.stage == EncodeStage.analyzing, analysis: state.analysis),
                const SizedBox(height: AppSpacing.xl),
                StepHeader(
                  number: 3,
                  title: 'SECRET MESSAGE',
                  isDone: state.message.isNotEmpty,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.base),
                    border: Border.all(color: scheme.outline, width: 2.0),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _messageController,
                        maxLines: 6,
                        maxLength: AppConstants.maxMessageChars,
                        onChanged: notifier.setMessage,
                        style: TextStyle(
                          fontFamily: 'Roboto Mono',
                          fontSize: 14,
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ENTER THE MESSAGE YOU WISH TO HIDE...',
                          hintStyle: TextStyle(
                            fontFamily: 'Roboto Mono',
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.3),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          counterText: '',
                          contentPadding: const EdgeInsets.all(AppSpacing.md),
                          filled: false,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: scheme.onSurface.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  border: Border.all(color: scheme.outline, width: 1.5),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: state.message.length / AppConstants.maxMessageChars,
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      state.message.length > AppConstants.maxMessageChars * 0.9 ? AppColors.red : scheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              '${state.message.length} / ${AppConstants.maxMessageChars}',
                              style: TextStyle(
                                fontFamily: 'Roboto Mono',
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                StepHeader(
                  number: 4,
                  title: 'ENCRYPTION KEY',
                  isDone: state.passphrase.isNotEmpty,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _passphraseController,
                  obscureText: _obscurePassphrase,
                  onChanged: notifier.setPassphrase,
                  style: TextStyle(
                    fontFamily: 'Roboto Mono',
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ENCRYPTION PASSPHRASE',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: Icon(Icons.key_rounded, size: 20, color: scheme.onSurface),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassphrase ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassphrase = !_obscurePassphrase),
                    ),
                    filled: true,
                    fillColor: scheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.base),
                      borderSide: BorderSide(color: scheme.outline, width: 2.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: scheme.outline, width: 2.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: scheme.outline, width: 2.0),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                StrengthMeter(score: strength, label: strengthLabel),
                const SizedBox(height: AppSpacing.xl),
                const StepHeader(
                  number: 5,
                  title: 'STEGO SECURITY MODE',
                  isDone: true,
                ),
                const SizedBox(height: AppSpacing.md),
                ModeCard(
                  title: 'GHOST MODE',
                  description: 'LSB-REPLACEMENT WITH GAUSSIAN NOISE DISTRIBUTION. MAXIMUM STEALTH, LOWER DURABILITY.',
                  capacity: state.analysis?.maxCapacityBytes ?? 0,
                  icon: Icons.visibility_off_rounded,
                  selected: state.mode == StegoMode.ghost,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    notifier.setMode(StegoMode.ghost);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                ModeCard(
                  title: 'ARMOR MODE',
                  description: 'MULTI-BIT REDUNDANCY WITH PARITY CHECKING. HIGH DURABILITY AGAINST COMPRESSION.',
                  capacity: (state.analysis?.maxCapacityBytes ?? 0),
                  icon: Icons.shield_rounded,
                  selected: state.mode == StegoMode.armor,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    notifier.setMode(StegoMode.armor);
                  },
                ),
                if (state.errorMessage != null && state.stage == EncodeStage.error) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.red, width: 2.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.errorMessage!.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Roboto Mono',
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    colors: [
                      scheme.surface.withValues(alpha: 0),
                      scheme.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: PrimaryButton(
                  label: 'INITIALIZE ENCODING',
                  icon: Icons.auto_fix_high_rounded,
                  loading: state.isProcessing,
                  onPressed: notifier.canEncode ? () => notifier.encode() : null,
                ),
              ),
            ),
            if (state.isProcessing && state.stage != EncodeStage.analyzing)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: ProcessingTimeline(stage: state.stage),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
