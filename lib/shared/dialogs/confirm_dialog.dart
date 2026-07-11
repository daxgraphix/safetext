import 'package:flutter/material.dart';
import '../widgets/app_buttons.dart';
import '../../app/theme/app_theme.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'CONFIRM',
  bool danger = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: scheme.onSurface, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: scheme.onSurface, width: 2)),
              ),
              child: Row(
                children: [
                  Icon(
                    danger ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                    color: danger ? scheme.error : scheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.0,
                        fontFamily: 'Roboto Mono',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Text(
                message.toUpperCase(),
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: 0.5,
                  fontFamily: 'Roboto Mono',
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.02),
                border: Border(top: BorderSide(color: scheme.onSurface, width: 2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'CANCEL',
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: danger
                        ? DangerButton(
                            label: confirmLabel,
                            onPressed: () => Navigator.of(context).pop(true),
                          )
                        : PrimaryButton(
                            label: confirmLabel,
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

