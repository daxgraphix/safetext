import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../data/models/history_entry.dart';
import '../../shared/widgets/grid_painter.dart';
import '../../shared/widgets/safetext_app_bar.dart';
import '../../shared/widgets/step_header.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/result_sheet.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

const _uuid = Uuid();

class CaesarCipherScreen extends ConsumerStatefulWidget {
  const CaesarCipherScreen({super.key});

  @override
  ConsumerState<CaesarCipherScreen> createState() => _CaesarCipherScreenState();
}

class _CaesarCipherScreenState extends ConsumerState<CaesarCipherScreen> {
  final _plainController = TextEditingController();
  final _cipherController = TextEditingController();
  double _shift = 3;
  String _encryptOutput = '';
  String _decryptOutput = '';

  @override
  void initState() {
    super.initState();
    _plainController.addListener(_onPlaintextChanged);
    _cipherController.addListener(_onCiphertextChanged);
  }

  @override
  void dispose() {
    _plainController.removeListener(_onPlaintextChanged);
    _cipherController.removeListener(_onCiphertextChanged);
    _plainController.dispose();
    _cipherController.dispose();
    super.dispose();
  }

  void _onPlaintextChanged() {
    if (_plainController.text.isEmpty) {
      setState(() => _encryptOutput = '');
      return;
    }
    _updateEncryption();
  }

  void _onCiphertextChanged() {
    if (_cipherController.text.isEmpty) {
      setState(() => _decryptOutput = '');
      return;
    }
    _updateDecryption();
  }

  void _updateEncryption() {
    final service = ref.read(caesarCipherServiceProvider);
    final result = service.encrypt(_plainController.text, _shift.round());
    setState(() => _encryptOutput = result);
  }

  void _updateDecryption() {
    final service = ref.read(caesarCipherServiceProvider);
    final result = service.decrypt(_cipherController.text, _shift.round());
    setState(() => _decryptOutput = result);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: SafeTextAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'CLEAR ALL',
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              _plainController.clear();
              _cipherController.clear();
              _encryptOutput = '';
              _decryptOutput = '';
            });
          },
        ),
      ),
      body: GridBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.margin,
            AppSpacing.margin,
            AppSpacing.margin,
            160,
          ),
          children: [
            _SecurityNoticeCard(),
            const SizedBox(height: AppSpacing.xl),
            StepHeader(
              number: 1,
              title: 'CONFIGURATION',
              isDone: _shift != 0,
            ),
            const SizedBox(height: AppSpacing.lg),
            _CircularDial(
              value: _shift,
              onChanged: (v) {
                setState(() {
                  _shift = v;
                  _updateEncryption();
                  _updateDecryption();
                });
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            StepHeader(
              number: 2,
              title: 'TRANSFORMATION',
              isDone: _encryptOutput.isNotEmpty || _decryptOutput.isNotEmpty,
            ),
            const SizedBox(height: AppSpacing.lg),
            _TransformSection(
              title: 'ENCRYPTION',
              color: scheme.onSurface,
              controller: _plainController,
              hint: 'ENTER PLAINTEXT...',
              output: _encryptOutput,
              onAction: () {
                HapticFeedback.mediumImpact();
                final entry = HistoryEntry(
                  id: _uuid.v4(),
                  operation: HistoryOperation.encoded,
                  imageName: 'Shift ${_shift.round()}',
                  mode: 'caesar',
                  timestamp: DateTime.now(),
                  status: HistoryStatus.success,
                  cipherAlgorithm: 'Caesar Cipher',
                  toolId: HistoryTool.caesarEncrypt,
                );
                ref.read(historyProvider.notifier).add(entry);

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ResultSheet(
                    title: 'TEXT ENCRYPTED',
                    description: 'THE PLAINTEXT HAS BEEN TRANSFORMED USING CAESAR SHIFT ${_shift.round()}.',
                    shareText: _encryptOutput,
                    onDone: () {},
                    content: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: scheme.onSurface, width: 2),
                      ),
                      child: Text(
                        _encryptOutput,
                        style: const TextStyle(
                          fontFamily: 'Roboto Mono',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _TransformSection(
              title: 'DECRYPTION',
              color: AppColors.red,
              controller: _cipherController,
              hint: 'ENTER CIPHERTEXT...',
              output: _decryptOutput,
              onAction: () {
                HapticFeedback.mediumImpact();
                final entry = HistoryEntry(
                  id: _uuid.v4(),
                  operation: HistoryOperation.decoded,
                  imageName: 'Shift ${_shift.round()}',
                  mode: 'caesar',
                  timestamp: DateTime.now(),
                  status: HistoryStatus.success,
                  cipherAlgorithm: 'Caesar Cipher',
                  toolId: HistoryTool.caesarDecrypt,
                );
                ref.read(historyProvider.notifier).add(entry);

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ResultSheet(
                    title: 'TEXT DECRYPTED',
                    description: 'THE CIPHERTEXT HAS BEEN REVERSED USING CAESAR SHIFT ${_shift.round()}.',
                    shareText: _decryptOutput,
                    onDone: () {},
                    content: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: scheme.onSurface, width: 2),
                      ),
                      child: Text(
                        _decryptOutput,
                        style: const TextStyle(
                          fontFamily: 'Roboto Mono',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularDial extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _CircularDial({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final size = (screenWidth * 0.55).clamp(200.0, 320.0);

    return Center(
      child: Column(
        children: [
          Text(
            'SHIFT OFFSET',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onPanUpdate: (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final center = box.size.center(Offset.zero);
              final pos = details.localPosition;
              final angle = math.atan2(pos.dy - center.dy, pos.dx - center.dx);
              var normalizedAngle = (angle + math.pi / 2) % (2 * math.pi);
              if (normalizedAngle < 0) normalizedAngle += 2 * math.pi;
              final newValue = (normalizedAngle / (2 * math.pi) * 26).clamp(0.0, 25.0);
              if ((newValue - value).abs() > 0.1) {
                HapticFeedback.selectionClick();
                onChanged(newValue);
              }
            },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.black,
                border: Border.all(color: scheme.outline, width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(size, size),
                    painter: _DialPainter(
                      value: value,
                      primaryColor: AppColors.red,
                      outlineColor: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  Container(
                    width: size * 0.7,
                    height: size * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.black,
                      border: Border.all(color: scheme.outline, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          value.round().toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontFamily: 'Roboto Mono',
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'STEPS',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white54,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DialControl(
                icon: Icons.remove,
                onTap: () => onChanged((value - 1).clamp(0, 25)),
              ),
              const SizedBox(width: 16),
              Container(
                width: 120,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outline, width: 2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    activeTrackColor: AppColors.red,
                    inactiveTrackColor: scheme.outline.withValues(alpha: 0.1),
                    thumbColor: AppColors.red,
                    overlayColor: AppColors.red.withValues(alpha: 0.1),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 0),
                    trackShape: const RectangularSliderTrackShape(),
                  ),
                  child: Slider(
                    value: value,
                    min: 0,
                    max: 25,
                    divisions: 25,
                    onChanged: onChanged,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _DialControl(
                icon: Icons.add,
                onTap: () => onChanged((value + 1).clamp(0, 25)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _DialControl({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline, width: 2),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double value;
  final Color primaryColor;
  final Color outlineColor;

  _DialPainter({
    required this.value,
    required this.primaryColor,
    required this.outlineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // Ticks
    final tickPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3;
    for (int i = 0; i < 26; i++) {
      final angle = (i / 26) * 2 * math.pi - math.pi / 2;
      final isSelected = i == value.round();
      tickPaint.color = isSelected ? primaryColor : outlineColor.withValues(alpha: 0.3);
      
      final innerR = radius - (isSelected ? 20 : 12);
      final outerR = radius - 4;
      
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * innerR, center.dy + math.sin(angle) * innerR),
        Offset(center.dx + math.cos(angle) * outerR, center.dy + math.sin(angle) * outerR),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) => oldDelegate.value != value;
}

class _TransformSection extends StatelessWidget {
  final String title;
  final Color color;
  final TextEditingController controller;
  final String hint;
  final String output;
  final VoidCallback onAction;

  const _TransformSection({
    required this.title,
    required this.color,
    required this.controller,
    required this.hint,
    required this.output,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.outline, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.05),
              border: Border(bottom: BorderSide(color: scheme.outline, width: 2)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sm - 2)),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal_rounded, size: 16, color: color),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: controller,
            maxLines: 4,
            style: TextStyle(
              fontFamily: 'Roboto Mono',
              fontSize: 14,
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: hint.toUpperCase(),
              hintStyle: TextStyle(
                fontFamily: 'Roboto Mono',
                color: scheme.onSurface.withValues(alpha: 0.3),
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.margin),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
          if (output.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.margin),
              decoration: BoxDecoration(
                color: AppColors.black,
                border: Border(
                  top: BorderSide(color: scheme.outline, width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'RESULT_LOG',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white54,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _ActionIcon(
                            icon: Icons.copy_rounded,
                            color: Colors.white,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Clipboard.setData(ClipboardData(text: output));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.black,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    side: const BorderSide(color: Colors.white, width: 2.0),
                                  ),
                                  content: const Text(
                                    'COPIED TO CLIPBOARD',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _ActionIcon(
                            icon: Icons.share_rounded,
                            color: Colors.white,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              Share.share(output);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _TypingText(text: output, color: Colors.white),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outline, width: 2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: PrimaryButton(
                  label: 'SAVE TO LOG',
                  icon: Icons.history_edu_rounded,
                  onPressed: onAction,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}


class _TypingText extends StatefulWidget {
  final String text;
  final Color color;

  const _TypingText({required this.text, required this.color});

  @override
  State<_TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<_TypingText> with SingleTickerProviderStateMixin {
  late String _displayText;
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _displayText = '';
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animateText();
  }

  @override
  void didUpdateWidget(_TypingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _animateText();
    }
  }

  void _animateText() {
    _displayText = '';
    if (widget.text.isEmpty) {
      setState(() {});
      return;
    }
    
    int charIndex = 0;
    _controller.repeat();
    
    Future.doWhile(() async {
      if (!mounted) return false;
      if (charIndex >= widget.text.length) {
        _controller.stop();
        return false;
      }
      
      setState(() {
        _displayText = widget.text.substring(0, charIndex + 1);
        charIndex++;
      });
      
      await Future.delayed(const Duration(milliseconds: 15));
      return true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: TextStyle(
        fontFamily: 'Roboto Mono',
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: widget.color,
        height: 1.4,
      ),
    );
  }
}

class _SecurityNoticeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.margin),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: Colors.white, width: 2.0),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EDUCATIONAL TOOL',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'THE CAESAR CIPHER IS AN ANCIENT SUBSTITUTION METHOD. IT IS INTENDED FOR EDUCATIONAL ANALYSIS OR BASIC OBFUSCATION ONLY.',
                  style: TextStyle(
                    fontFamily: 'Roboto Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

