import 'package:flutter/material.dart';
import '../providers/decode_provider.dart';

class DecodeTimeline extends StatelessWidget {
  final DecodeStage stage;

  const DecodeTimeline({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final steps = [
      const _TimelineStep(
        stage: DecodeStage.decrypting,
        label: 'Decrypting Content',
        description: 'Deriving session keys via Argon2id',
        icon: Icons.vpn_key_outlined,
      ),
      const _TimelineStep(
        stage: DecodeStage.verifying,
        label: 'Integrity Check',
        description: 'Verifying AES-GCM authentication tag',
        icon: Icons.verified_user_outlined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Extracting Secure Data',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? scheme.primary
                              : isActive
                                  ? scheme.primaryContainer
                                  : scheme.surfaceContainerHighest,
                          border: isActive
                              ? Border.all(color: scheme.primary, width: 2)
                              : null,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_rounded : step.icon,
                          size: 18,
                          color: isCompleted
                              ? scheme.onPrimary
                              : isActive
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      if (index != steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            color: isCompleted
                                ? scheme.primary
                                : scheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.label,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: isActive || isCompleted ? FontWeight.w700 : FontWeight.w500,
                              color: isActive || isCompleted
                                  ? scheme.onSurface
                                  : scheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.description,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: isActive
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                              height: 1.4,
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

  bool _isCompleted(DecodeStage stepStage) {
    const order = [
      DecodeStage.decrypting,
      DecodeStage.verifying,
      DecodeStage.success,
    ];
    return order.indexOf(stage) > order.indexOf(stepStage);
  }
}

class _TimelineStep {
  final DecodeStage stage;
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
