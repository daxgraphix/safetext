import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_buttons.dart';
import '../../app/theme/app_theme.dart';
import '../../app/providers.dart';

class ResultSheet extends ConsumerWidget {
  final String title;
  final String description;
  final Widget? content;
  final String? sharePath;
  final String? shareText;
  final Uint8List? imageBytes;
  final String? imageName;
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
    this.imageBytes,
    this.imageName,
    required this.onDone,
    this.icon = Icons.check_circle_rounded,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
        border: Border(top: BorderSide(color: scheme.onSurface, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor ?? scheme.secondary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
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
              if (imageBytes != null)
                Expanded(
                  child: SecondaryButton(
                    label: 'SAVE TO GALLERY',
                    icon: Icons.save_alt_rounded,
                    onPressed: () async {
                      try {
                        final storage = ref.read(storageServiceProvider);
                        await storage.saveToGallery(imageBytes!, fileName: imageName);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('SAVED TO GALLERY'),
                              action: SnackBarAction(
                                label: 'OPEN',
                                onPressed: () => storage.openGallery(),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('FAILED TO SAVE: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
              if (sharePath != null || shareText != null) ...[
                if (imageBytes != null) const SizedBox(width: 12),
                Expanded(
                  child: SecondaryButton(
                    label: imageBytes != null ? 'SHARE' : 'SHARE / COPY',
                    icon: Icons.share_rounded,
                    onPressed: () {
                      if (sharePath != null) {
                        Share.shareXFiles([XFile(sharePath!)], text: shareText);
                      } else if (shareText != null) {
                        if (imageBytes == null) {
                          // For text results, also copy to clipboard
                          ref.read(clipboardServiceProvider).copyToClipboard(shareText!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('COPIED TO CLIPBOARD (AUTO-CLEAR ACTIVE)')),
                          );
                        }
                        Share.share(shareText!);
                      }
                    },
                  ),
                ),
              ],
              const SizedBox(width: 12),
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
