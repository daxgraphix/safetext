import 'dart:math' as math;

enum PasswordStrength { weak, fair, strong, veryStrong }

extension PasswordStrengthLabel on PasswordStrength {
  String get label => switch (this) {
        PasswordStrength.weak => 'Weak',
        PasswordStrength.fair => 'Fair',
        PasswordStrength.strong => 'Strong',
        PasswordStrength.veryStrong => 'Very Strong',
      };
}

/// Estimates password strength from character-class diversity and length —
/// a simple, transparent heuristic (not a full entropy/zxcvbn-style
/// dictionary-attack model), intentionally kept dependency-free and fully
/// offline.
class PasswordStrengthAnalyzer {
  const PasswordStrengthAnalyzer();

  /// Rough bits-of-entropy estimate: log2(poolSize) * length.
  double estimateEntropyBits(String password) {
    if (password.isEmpty) return 0;
    int poolSize = 0;
    if (RegExp(r'[A-Z]').hasMatch(password)) poolSize += 26;
    if (RegExp(r'[a-z]').hasMatch(password)) poolSize += 26;
    if (RegExp(r'[0-9]').hasMatch(password)) poolSize += 10;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) poolSize += 32;
    if (poolSize == 0) return 0;
    return password.length * (_log2(poolSize.toDouble()));
  }

  PasswordStrength analyze(String password) {
    if (password.isEmpty) return PasswordStrength.weak;

    final entropy = estimateEntropyBits(password);
    final hasRepeats = RegExp(r'(.)\1{2,}').hasMatch(password); // aaa, 111, etc.
    final isSequential = _hasSequentialRun(password);

    double score = entropy;
    if (hasRepeats) score -= 12;
    if (isSequential) score -= 12;
    if (password.length < 8) score -= 20;

    if (score < 28) return PasswordStrength.weak;
    if (score < 50) return PasswordStrength.fair;
    if (score < 75) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  bool _hasSequentialRun(String password) {
    const runLength = 3;
    for (int i = 0; i <= password.length - runLength; i++) {
      final a = password.codeUnitAt(i);
      final b = password.codeUnitAt(i + 1);
      final c = password.codeUnitAt(i + 2);
      if (b == a + 1 && c == b + 1) return true; // ascending, e.g. "abc", "123"
      if (b == a - 1 && c == b - 1) return true; // descending, e.g. "cba", "321"
    }
    return false;
  }

  double _log2(double value) => value <= 0 ? 0 : (math.log(value) / math.log(2));
}
