import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

enum StatusTone { success, warning, danger, neutral, info }

/// Small high-contrast status pill, e.g. "SECURE", "Verified", "OFFLINE".
class StatusChip extends StatefulWidget {
  final String label;
  final StatusTone tone;
  final IconData? icon;
  final bool dot;

  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.success,
    this.icon,
    this.dot = false,
  });

  @override
  State<StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<StatusChip> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _color(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (widget.tone) {
      case StatusTone.success:
        return scheme.secondary;
      case StatusTone.warning:
        return scheme.tertiary;
      case StatusTone.danger:
        return scheme.error;
      case StatusTone.info:
        return scheme.primary;
      case StatusTone.neutral:
        return scheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final scheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.outline, width: 2.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.dot) ...[
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          if (widget.icon != null) ...[const Icon(Icons.check, size: 12, color: Colors.white), const SizedBox(width: 4)],
          Text(
            widget.label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

