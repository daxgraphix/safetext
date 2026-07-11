import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// The recurring "shield + SafeText wordmark ... lock icon" header seen on
/// nearly every screen in the design.
class SafeTextAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? trailing;
  final Widget? leading;
  final Widget? statusPill;
  final ScrollController? scrollController;

  const SafeTextAppBar({
    super.key,
    this.title,
    this.trailing,
    this.leading,
    this.statusPill,
    this.scrollController,
  });

  @override
  State<SafeTextAppBar> createState() => _SafeTextAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(68);
}

class _SafeTextAppBarState extends State<SafeTextAppBar> with SingleTickerProviderStateMixin {
  late AnimationController _shieldController;

  @override
  void initState() {
    super.initState();
    _shieldController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outline, width: 2.0)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              if (widget.leading != null) widget.leading! else const SizedBox.shrink(),
              if (widget.leading == null)
                AnimatedBuilder(
                  animation: _shieldController,
                  builder: (context, child) {
                    return Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: scheme.outline, width: 2.0),
                      ),
                      child: Icon(Icons.shield_rounded, color: scheme.primary, size: 20),
                    );
                  },
                ),
              if (widget.leading == null) const SizedBox(width: 12),
              Text(
                widget.title?.toUpperCase() ?? 'SAFETEXT',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              if (widget.statusPill != null) ...[widget.statusPill!, const SizedBox(width: 12)],
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: scheme.outline, width: 2.0),
                ),
                child: Center(child: widget.trailing ?? Icon(Icons.lock_rounded, color: scheme.onSurface, size: 20)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
