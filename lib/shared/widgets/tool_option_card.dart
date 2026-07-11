import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// A wide, tappable option row with icon + title + description + chevron.
/// Used by the Steganography Home screen to pick between "LSB on Text" and
/// "LSB with DES".
class ToolOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final List<String> tags;
  final VoidCallback onTap;

  const ToolOptionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
    this.tags = const [],
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: scheme.onSurface, width: 2.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: scheme.onSurface, width: 2.0),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags
                            .map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: scheme.surface,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(color: scheme.onSurface, width: 2.0),
                                  ),
                                  child: Text(
                                    tag.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'Roboto Mono',
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Icon(Icons.arrow_forward_rounded, color: scheme.onSurface, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
