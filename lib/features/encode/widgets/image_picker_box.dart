import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:safetext/app/theme/app_theme.dart';
import '../../../core/security/stego_service.dart' show ImageAnalysis;

class ImagePickerBox extends StatefulWidget {
  final bool hasImage;
  final Uint8List? imageBytes;
  final ImageAnalysis? analysis;
  final VoidCallback onTap;
  const ImagePickerBox({super.key, required this.hasImage, required this.imageBytes, this.analysis, required this.onTap});

  @override
  State<ImagePickerBox> createState() => _ImagePickerBoxState();
}

class _ImagePickerBoxState extends State<ImagePickerBox> with SingleTickerProviderStateMixin {
  late AnimationController _borderController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final analysis = widget.analysis;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: widget.hasImage ? 240 : 180,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.base),
            color: scheme.surface,
            border: Border.all(color: scheme.onSurface, width: 2),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!widget.hasImage)
                AnimatedBuilder(
                  animation: _borderController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _DashedBorderPainter(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                        phase: _borderController.value,
                      ),
                    );
                  },
                ),
              if (widget.hasImage && widget.imageBytes != null) ...[
                Image.memory(widget.imageBytes!, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                if (analysis != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _AnalysisBadge(analysis: analysis),
                  ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: scheme.onSurface, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.refresh_rounded, size: 16, color: scheme.onSurface),
                        const SizedBox(width: 8),
                        Text(
                          'CHANGE IMAGE',
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: scheme.onSurface, width: 2),
                      ),
                      child: Icon(Icons.add_photo_alternate_rounded, size: 32, color: scheme.onSurface),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'CHOOSE CARRIER IMAGE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DRAG & DROP OR TAP TO BROWSE',
                      style: TextStyle(
                        fontFamily: 'Roboto Mono',
                        fontSize: 10,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisBadge extends StatelessWidget {
  final ImageAnalysis analysis;
  const _AnalysisBadge({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final color = Color(analysis.healthColorValue);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.onSurface, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, size: 12, color: scheme.surface),
          const SizedBox(width: 8),
          Text(
            '${analysis.healthLabel.toUpperCase()} CARRIER',
            style: TextStyle(
              color: scheme.surface,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double phase;
  _DashedBorderPainter({required this.color, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(AppRadius.base)));

    const dashWidth = 12.0;
    const dashSpace = 8.0;
    
    final Path dashPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = metric.length * phase;
      while (distance < metric.length + (metric.length * phase)) {
        final double currentDistance = distance % metric.length;
        dashPath.addPath(
          metric.extractPath(currentDistance, math.min(currentDistance + dashWidth, metric.length)),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => oldDelegate.phase != phase;
}
