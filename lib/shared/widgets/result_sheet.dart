import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/app_buttons.dart';
import '../../app/theme/app_theme.dart';

class ResultSheet extends StatelessWidget {
  final String title;
  final String description;
  final Widget? content;
  final String? sharePath;
  final String? shareText;
  final VoidCallback onDone;
  final IconData icon;
  final Color? iconColor;

  const ResultSheet({
    super.key,
    required this.title,
    required this.description,
    this.content,
    this.sharePath,
    this.shareText,
    required this.onDone,
    this.icon = Icons.check_circle_rounded,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
        border: Border(top: BorderSide(color: scheme.onSurface, width: 4)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 6,
            decoration: BoxDecoration(
              color: scheme.onSurface,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor ?? scheme.secondary,
              borderRadius: BorderRadius.circular(AppRadius.base),
              border: Border.all(color: scheme.onSurface, width: 2),
            ),
            child: Icon(icon, color: scheme.surface, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto Mono',
              fontSize: 11,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (content != null) ...[
            const SizedBox(height: 24),
            content!,
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              if (sharePath != null || shareText != null)
                Expanded(
                  child: SecondaryButton(
                    label: 'SHARE / SAVE',
                    icon: Icons.share_rounded,
                    onPressed: () {
                      if (sharePath != null) {
                        Share.shareXFiles([XFile(sharePath!)], text: shareText);
                      } else if (shareText != null) {
                        Share.share(shareText!);
                      }
                    },
                  ),
                ),
              if (sharePath != null || shareText != null) const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'DONE',
                  onPressed: () {
                    Navigator.pop(context);
                    onDone();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
