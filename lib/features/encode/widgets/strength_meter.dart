import 'package:flutter/material.dart';
import 'package:safetext/app/theme/app_colors.dart';
import 'package:safetext/app/theme/app_theme.dart';

class StrengthMeter extends StatelessWidget {
  final int score;
  final String label;
  const StrengthMeter({super.key, required this.score, required this.label});

  Color _getColor(int score) {
    if (score <= 1) return AppColors.red;
    if (score == 2) return AppColors.red.withValues(alpha: 0.7);
    if (score == 3) return AppColors.green.withValues(alpha: 0.7);
    return AppColors.green;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = _getColor(score);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: scheme.onSurface, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.password_rounded, size: 16, color: scheme.onSurface),
                  const SizedBox(width: 8),
                  Text(
                    'PASSPHRASE STRENGTH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Roboto Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: activeColor,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(4, (index) {
              final isActive = index < score;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: 8,
                  margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : scheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: isActive ? activeColor : Colors.transparent,
                      width: 1,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _getHint(score).toUpperCase(),
            style: TextStyle(
              fontFamily: 'Roboto Mono',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _getHint(int score) {
    if (score <= 1) return 'Weak: Use symbols, numbers, and mixed case.';
    if (score == 2) return 'Fair: Add more characters for better security.';
    if (score == 3) return 'Good: Strong enough for most use cases.';
    return 'Excellent: Your data is mathematically highly secure.';
  }
}

