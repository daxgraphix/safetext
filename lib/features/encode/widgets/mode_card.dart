import 'package:flutter/material.dart';
import 'package:safetext/app/theme/app_theme.dart';
import 'package:safetext/core/utils/formatters.dart';

class ModeCard extends StatefulWidget {
  final String title;
  final String description;
  final int capacity;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const ModeCard({
    super.key,
    required this.title,
    required this.description,
    required this.capacity,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<ModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.selected ? scheme.onSurface : scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: scheme.onSurface,
              width: 2.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.selected ? scheme.surface : scheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: widget.selected ? scheme.surface : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.selected ? scheme.onSurface : scheme.onSurface,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: widget.selected ? scheme.surface : scheme.onSurface,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Roboto Mono',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: widget.selected 
                            ? scheme.surface.withValues(alpha: 0.9) 
                            : scheme.onSurface.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                    if (widget.capacity > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.selected ? scheme.surface.withValues(alpha: 0.2) : scheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'MAX CAPACITY: ${Formatters.bytes(widget.capacity)}',
                          style: TextStyle(
                            fontFamily: 'Roboto Mono',
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: widget.selected ? scheme.surface : scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (widget.selected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    color: scheme.surface,
                  ),
                  child: Icon(Icons.check_rounded, size: 16, color: scheme.onSurface),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

