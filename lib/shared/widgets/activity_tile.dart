import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import 'status_chip.dart';

class ActivityTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailingText;
  final String? statusLabel;
  final StatusTone statusTone;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetails;

  const ActivityTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailingText,
    this.statusLabel,
    this.statusTone = StatusTone.success,
    this.onTap,
    this.onViewDetails,
  });

  @override
  State<ActivityTile> createState() => _ActivityTileState();
}

class _ActivityTileState extends State<ActivityTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          transform: Matrix4.diagonal3Values(_pressed ? 0.99 : 1.0, _pressed ? 0.99 : 1.0, 1.0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            color: scheme.surface,
            border: Border.all(color: scheme.outline, width: 2.0),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.iconColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: scheme.outline, width: 2.0),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                        letterSpacing: 0.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.statusLabel != null)
                    StatusChip(label: widget.statusLabel!, tone: widget.statusTone),
                  const SizedBox(height: 4),
                  Text(
                    widget.trailingText.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: scheme.primary,
                      letterSpacing: 1.0,
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

