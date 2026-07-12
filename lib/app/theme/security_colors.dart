import 'package:flutter/material.dart';
import 'app_colors.dart';

@immutable
class SecurityColors extends ThemeExtension<SecurityColors> {
  const SecurityColors({
    required this.success,
    required this.danger,
    required this.info,
    required this.warning,
  });

  final Color success;
  final Color danger;
  final Color info;
  final Color warning;

  @override
  SecurityColors copyWith({
    Color? success,
    Color? danger,
    Color? info,
    Color? warning,
  }) {
    return SecurityColors(
      success: success ?? this.success,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      warning: warning ?? this.warning,
    );
  }

  @override
  SecurityColors lerp(ThemeExtension<SecurityColors>? other, double t) {
    if (other is! SecurityColors) {
      return this;
    }
    return SecurityColors(
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }

  static const light = SecurityColors(
    success: AppColors.green,
    danger: AppColors.red,
    info: AppColors.blue,
    warning: Colors.orange,
  );

  static const dark = SecurityColors(
    success: AppColors.green,
    danger: AppColors.red,
    info: AppColors.blue,
    warning: Colors.orangeAccent,
  );
}

extension SecurityColorsExtension on ThemeData {
  SecurityColors get securityColors => extension<SecurityColors>() ?? SecurityColors.dark;
}
