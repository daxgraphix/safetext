import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

class VisualDiffViewer extends StatefulWidget {
  final Uint8List originalBytes;
  final Uint8List encodedBytes;

  const VisualDiffViewer({
    super.key,
    required this.originalBytes,
    required this.encodedBytes,
  });

  @override
  State<VisualDiffViewer> createState() => _VisualDiffViewerState();
}

class _VisualDiffViewerState extends State<VisualDiffViewer> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: scheme.onSurface,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm - 2),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.memory(
                      widget.originalBytes,
                      fit: BoxFit.cover,
                    ),
                  ),
                  ClipRect(
                    clipper: _LeftClipper(_sliderValue),
                    child: Image.memory(
                      widget.encodedBytes,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final xPos = constraints.maxWidth * _sliderValue;
                        return Stack(
                          children: [
                            Positioned(
                              left: xPos - 1,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 2,
                                color: AppColors.red,
                              ),
                            ),
                            Positioned(
                              left: xPos - 20,
                              top: constraints.maxHeight / 2 - 20,
                              child: GestureDetector(
                                onHorizontalDragUpdate: (details) {
                                  setState(() {
                                    _sliderValue = (xPos + details.delta.dx) / constraints.maxWidth;
                                    _sliderValue = _sliderValue.clamp(0.0, 1.0);
                                  });
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.unfold_more_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  // Labels
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _LabelBadge(
                      label: 'ENCODED',
                      opacity: _sliderValue > 0.1 ? 1.0 : 0.0,
                      color: AppColors.red,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _LabelBadge(
                      label: 'ORIGINAL',
                      opacity: _sliderValue < 0.9 ? 1.0 : 0.0,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ORIGINAL',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontFamily: 'Roboto Mono',
                    ),
                  ),
                  const Text(
                    'COMPARE PIXELS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Text(
                    'ENCODED',
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontFamily: 'Roboto Mono',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.red,
                  inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.1),
                  thumbColor: AppColors.red,
                  overlayColor: AppColors.red.withValues(alpha: 0.1),
                  trackHeight: 2,
                  thumbShape: const RectangularSliderThumbShape(
                    enabledThumbRadius: 10,
                  ),
                ),
                child: Slider(
                  value: _sliderValue,
                  onChanged: (value) => setState(() => _sliderValue = value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabelBadge extends StatelessWidget {
  final String label;
  final double opacity;
  final Color color;
  const _LabelBadge({required this.label, required this.opacity, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontFamily: 'Roboto Mono',
          ),
        ),
      ),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  final double fraction;
  _LeftClipper(this.fraction);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * fraction, size.height);
  }

  @override
  bool shouldReclip(_LeftClipper oldClipper) => oldClipper.fraction != fraction;
}

class RectangularSliderThumbShape extends SliderComponentShape {
  final double enabledThumbRadius;

  const RectangularSliderThumbShape({
    this.enabledThumbRadius = 10.0,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.red
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCenter(center: center, width: 20, height: 20);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.sm)), paint);
    
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.sm)), borderPaint);
  }
}
