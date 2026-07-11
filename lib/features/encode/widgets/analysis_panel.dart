import 'package:flutter/material.dart';
import 'package:safetext/app/theme/app_theme.dart';
import 'package:safetext/core/security/stego_service.dart' show ImageAnalysis;
import 'package:safetext/core/utils/formatters.dart';

class AnalysisPanel extends StatelessWidget {
  final bool analyzing;
  final ImageAnalysis? analysis;
  const AnalysisPanel({super.key, required this.analyzing, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (analyzing) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: scheme.onSurface, width: 2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(scheme.onSurface)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'PERFORMING DEEP IMAGE ANALYSIS...',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: scheme.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'CHECKING PIXEL DISTRIBUTION AND STATISTICAL ENTROPY',
              style: TextStyle(
                fontFamily: 'Roboto Mono',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.9),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (analysis == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: scheme.onSurface, width: 2),
        ),
        child: Center(
          child: Text(
            'SELECT AN IMAGE TO SEE ANALYSIS',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: scheme.onSurface.withValues(alpha: 0.85)),
          ),
        ),
      );
    }

    final scoreColor = Color(analysis!.healthColorValue);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.onSurface, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _MetricItem(
                label: 'CAPACITY',
                value: Formatters.bytes(analysis!.maxCapacityBytes),
                icon: Icons.storage_rounded,
                flex: 3,
                tooltip: 'Maximum data that can be hidden in this image with the current mode.',
              ),
              _MetricItem(
                label: 'HEALTH',
                value: analysis!.healthLabel.toUpperCase(),
                icon: Icons.favorite_rounded,
                valueColor: scoreColor,
                flex: 2,
                tooltip: 'Image suitability based on visual complexity and noise floor.',
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 2, thickness: 2, color: scheme.onSurface.withValues(alpha: 0.1)),
          ),
          Row(
            children: [
              _MetricItem(
                label: 'RESOLUTION',
                value: '${analysis!.width}×${analysis!.height}',
                icon: Icons.photo_size_select_actual_rounded,
                flex: 3,
              ),
              _MetricItem(
                label: 'SECURITY',
                value: '${analysis!.securityScore}%',
                icon: Icons.security_rounded,
                valueColor: scoreColor,
                flex: 2,
                tooltip: 'Estimated resistance to steganalytical detection.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final int flex;
  final String? tooltip;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    required this.flex,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (valueColor ?? scheme.onSurface).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: (valueColor ?? scheme.onSurface), width: 1),
          ),
          child: Icon(icon, size: 16, color: valueColor ?? scheme.onSurface),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface.withValues(alpha: 0.85),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Roboto Mono',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Expanded(
      flex: flex,
      child: tooltip != null
          ? Tooltip(
              message: tooltip!.toUpperCase(),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: scheme.onSurface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: scheme.surface, width: 2),
              ),
              textStyle: TextStyle(
                fontFamily: 'Roboto Mono',
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: scheme.surface,
              ),
              child: content,
            )
          : content,
    );
  }
}

