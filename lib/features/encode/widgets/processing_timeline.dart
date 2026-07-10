import 'package:flutter/material.dart';
import 'package:safetext/app/theme/app_theme.dart';
import '../providers/encode_provider.dart';

class ProcessingTimeline extends StatelessWidget {
  final EncodeStage stage;

  const ProcessingTimeline({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final steps = [
      const _TimelineStep(
        stage: EncodeStage.encrypting,
        label: 'ENCRYPTING PAYLOAD',
        description: 'AES-256 GCM ENCRYPTION',
        icon: Icons.lock_outline_rounded,
      ),
      const _TimelineStep(
        stage: EncodeStage.embedding,
        label: 'STEGANOGRAPHIC EMBEDDING',
        description: 'INJECTING BITS INTO CARRIER',
        icon: Icons.layers_outlined,
      ),
      const _TimelineStep(
        stage: EncodeStage.verifying,
        label: 'INTEGRITY VERIFICATION',
        description: 'VALIDATING BIT CONSISTENCY',
        icon: Icons.verified_user_outlined,
      ),
      const _TimelineStep(
        stage: EncodeStage.saving,
        label: 'FINALIZING FILE',
        description: 'OPTIMIZING PNG STRUCTURE',
        icon: Icons.save_alt_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: scheme.onSurface, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.onSurface),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'PROCESSING SECURELY',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isCompleted = _isCompleted(step.stage);
            final isActive = stage == step.stage;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? scheme.onSurface
                              : scheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: isCompleted || isActive ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_rounded : step.icon,
                          size: 14,
                          color: isCompleted
                              ? scheme.surface
                              : isActive
                                  ? scheme.onSurface
                                  : scheme.onSurface.withValues(alpha: 0.2),
                        ),
                      ),
                      if (index != steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: isCompleted
                                ? scheme.onSurface
                                : scheme.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive || isCompleted ? FontWeight.w900 : FontWeight.w700,
                              color: isActive || isCompleted
                                  ? scheme.onSurface
                                  : scheme.onSurface.withValues(alpha: 0.4),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.description,
                            style: TextStyle(
                              fontFamily: 'Roboto Mono',
                              fontSize: 10,
                              color: isActive
                                  ? scheme.onSurface.withValues(alpha: 0.7)
                                  : scheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _isCompleted(EncodeStage stepStage) {
    const order = [
      EncodeStage.encrypting,
      EncodeStage.embedding,
      EncodeStage.verifying,
      EncodeStage.saving,
      EncodeStage.done,
    ];
    return order.indexOf(stage) > order.indexOf(stepStage);
  }
}

class _TimelineStep {
  final EncodeStage stage;
  final String label;
  final String description;
  final IconData icon;

  const _TimelineStep({
    required this.stage,
    required this.label,
    required this.description,
    required this.icon,
  });
}
