import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class ToolTile extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const ToolTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  State<ToolTile> createState() => _ToolTileState();
}

class _ToolTileState extends State<ToolTile> {
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
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _pressed ? scheme.onSurface.withValues(alpha: 0.05) : scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: scheme.onSurface,
              width: 2.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: scheme.onSurface, width: 2.0),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                  height: 1.1,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
