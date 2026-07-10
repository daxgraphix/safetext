import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/security/password_generator_service.dart';
import '../../core/security/password_strength_analyzer.dart';
import '../../data/models/history_entry.dart';
import '../../shared/widgets/grid_painter.dart';
import '../../shared/widgets/safetext_app_bar.dart';
import '../../shared/widgets/step_header.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/result_sheet.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

// ignore: prefer_const_constructors
final _uuid = Uuid();

class PasswordGeneratorScreen extends ConsumerStatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  ConsumerState<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends ConsumerState<PasswordGeneratorScreen> with SingleTickerProviderStateMixin {
  late double _length;
  late bool _uppercase;
  late bool _lowercase;
  late bool _numbers;
  late bool _symbols;
  bool _excludeSimilar = false;
  bool _excludeAmbiguous = false;
  String _password = '';
  String? _error;
  bool _initialized = false;
  final List<String> _sessionHistory = [];


  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);

    if (!_initialized) {
      _length = settings.defaultPasswordLength.toDouble();
      _uppercase = settings.passwordIncludeUppercase;
      _lowercase = settings.passwordIncludeLowercase;
      _numbers = settings.passwordIncludeNumbers;
      _symbols = settings.passwordIncludeSymbols;
      _excludeSimilar = settings.passwordExcludeSimilar;
      _excludeAmbiguous = settings.passwordExcludeAmbiguous;
      _initialized = true;
    }

    final analyzer = ref.read(passwordStrengthAnalyzerProvider);
    final strength = _password.isEmpty ? null : analyzer.analyze(_password);
    final entropy = _password.isEmpty ? 0.0 : analyzer.estimateEntropyBits(_password);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: SafeTextAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: GridBackground(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.margin,
                AppSpacing.margin,
                AppSpacing.margin,
                140,
              ),
              children: [
                StepHeader(
                  number: 1,
                  title: 'COMPLEXITY CONFIGURATION',
                  isDone: _initialized,
                ),
                const SizedBox(height: AppSpacing.lg),
                _ConfigurationCard(
                  length: _length,
                  onLengthChanged: (v) => setState(() => _length = v),
                  onLengthChangeEnd: (_) {},
                  uppercase: _uppercase,
                  onUppercaseChanged: (v) => setState(() {
                    _uppercase = v;
                  }),
                  lowercase: _lowercase,
                  onLowercaseChanged: (v) => setState(() {
                    _lowercase = v;
                  }),
                  numbers: _numbers,
                  onNumbersChanged: (v) => setState(() {
                    _numbers = v;
                  }),
                  symbols: _symbols,
                  onSymbolsChanged: (v) => setState(() {
                    _symbols = v;
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                _ExclusionSection(
                  excludeSimilar: _excludeSimilar,
                  onExcludeSimilarChanged: (v) => setState(() {
                    _excludeSimilar = v;
                  }),
                  excludeAmbiguous: _excludeAmbiguous,
                  onExcludeAmbiguousChanged: (v) => setState(() {
                    _excludeAmbiguous = v;
                  }),
                ),
                const SizedBox(height: AppSpacing.xl),
                StepHeader(
                  number: 2,
                  title: 'SECURE OUTPUT',
                  isDone: _password.isNotEmpty,
                ),
                const SizedBox(height: AppSpacing.lg),
                _TerminalDisplay(
                  password: _password,
                  error: _error,
                  onRegenerate: _generate,
                  onCopy: _copy,
                ),
                const SizedBox(height: 32),
                _EntropyMeter(
                  entropy: entropy,
                  strength: strength,
                ),
                if (_password.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'SAVE TO LOG',
                    icon: Icons.history_edu_rounded,
                    onPressed: _showResultSheet,
                  ),
                ],
                if (_sessionHistory.isNotEmpty) ...[
                  const SizedBox(height: 40),
                  _HistorySection(
                    history: _sessionHistory,
                    onCopy: (p) => _copy(overridePassword: p),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 24),
                  _ErrorMessage(message: _error!),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _generate() {
    HapticFeedback.lightImpact();
    final service = ref.read(passwordGeneratorServiceProvider);
    final options = PasswordOptions(
      length: _length.round(),
      includeUppercase: _uppercase,
      includeLowercase: _lowercase,
      includeNumbers: _numbers,
      includeSymbols: _symbols,
      excludeSimilar: _excludeSimilar,
      excludeAmbiguous: _excludeAmbiguous,
    );
    try {
      final password = service.generate(options);
      setState(() {
        if (_password.isNotEmpty) {
          _sessionHistory.insert(0, _password);
          if (_sessionHistory.length > 5) _sessionHistory.removeLast();
        }
        _password = password;
        _error = null;
      });
    } on AppException catch (e) {
      setState(() {
        _password = '';
        _error = e.message;
      });
    }
  }

  void _showResultSheet() {
    if (_password.isEmpty) return;

    HapticFeedback.mediumImpact();

    final options = PasswordOptions(
      length: _length.round(),
      includeUppercase: _uppercase,
      includeLowercase: _lowercase,
      includeNumbers: _numbers,
      includeSymbols: _symbols,
      excludeSimilar: _excludeSimilar,
      excludeAmbiguous: _excludeAmbiguous,
    );

    ref.read(historyProvider.notifier).add(HistoryEntry(
          id: _uuid.v4(),
          operation: HistoryOperation.generated,
          imageName: '${options.length}-character password',
          mode: 'password',
          timestamp: DateTime.now(),
          status: HistoryStatus.success,
          toolId: HistoryTool.passwordGenerator,
        ));

    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ResultSheet(
        title: 'PASSWORD LOGGED',
        description: 'YOUR SECURE PASSWORD HAS BEEN SAVED TO HISTORY.',
        shareText: _password,
        onDone: () {},
        content: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(AppRadius.base),
            border: Border.all(color: scheme.onSurface, width: 2.0),
          ),
          child: Text(
            _password,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Roboto Mono',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  void _copy({String? overridePassword}) {
    final textToCopy = overridePassword ?? _password;
    if (textToCopy.isEmpty) return;
    
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: textToCopy));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black,
        content: const Text(
          'COPIED TO CLIPBOARD',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: const BorderSide(color: Colors.white, width: 2.0),
        ),
        margin: const EdgeInsets.all(24),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _TerminalDisplay extends StatefulWidget {
  final String password;
  final String? error;
  final VoidCallback onRegenerate;
  final VoidCallback onCopy;

  const _TerminalDisplay({
    required this.password,
    this.error,
    required this.onRegenerate,
    required this.onCopy,
  });

  @override
  State<_TerminalDisplay> createState() => _TerminalDisplayState();
}

class _TerminalDisplayState extends State<_TerminalDisplay> with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: scheme.outline, width: 2.0),
      ),
      child: Column(
        children: [
          // Terminal Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.base - 2)),
              border: Border(bottom: BorderSide(color: scheme.outline, width: 2.0)),
            ),
            child: Row(
              children: [
                _dot(AppColors.red),
                const SizedBox(width: AppSpacing.sm),
                _dot(AppColors.green),
                const SizedBox(width: AppSpacing.sm),
                _dot(Colors.white),
                const SizedBox(width: AppSpacing.md),
                const Text(
                  'SECURE_GEN_v2.0',
                  style: TextStyle(
                    fontFamily: 'Roboto Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white54,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.terminal_rounded, size: 14, color: Colors.white54),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin, vertical: AppSpacing.lg),
            child: Column(
              children: [
                Container(
                  constraints: const BoxConstraints(minHeight: 80),
                  alignment: Alignment.center,
                  child: widget.error != null
                      ? Text(
                          widget.error!.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Roboto Mono',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.red,
                          ),
                        )
                      : RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: widget.password.isEmpty ? 'AWAITING COMMAND...' : widget.password,
                                style: TextStyle(
                                  fontFamily: 'Roboto Mono',
                                  fontSize: widget.password.isEmpty ? 16 : 22,
                                  fontWeight: FontWeight.w900,
                                  color: widget.password.isEmpty ? Colors.white38 : Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              WidgetSpan(
                                child: AnimatedBuilder(
                                  animation: _cursorController,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _cursorController.value > 0.5 ? 1.0 : 0.0,
                                      child: Container(
                                        width: 10,
                                        height: 24,
                                        margin: const EdgeInsets.only(left: 4),
                                        color: AppColors.red,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.base - 2)),
              border: Border(top: BorderSide(color: scheme.outline, width: 2.0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TerminalButton(
                    icon: Icons.refresh_rounded,
                    label: 'GENERATE',
                    onTap: widget.onRegenerate,
                    color: Colors.white,
                  ),
                ),
                Container(width: 2, height: 24, color: scheme.outline),
                Expanded(
                  child: _TerminalButton(
                    icon: Icons.copy_rounded,
                    label: 'COPY',
                    onTap: widget.onCopy,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
      );
}

class _TerminalButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _TerminalButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Roboto Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntropyMeter extends StatelessWidget {
  final double entropy;
  final PasswordStrength? strength;

  const _EntropyMeter({required this.entropy, required this.strength});

  Color _getColor(ColorScheme scheme) {
    switch (strength) {
      case PasswordStrength.weak:
        return AppColors.red;
      case PasswordStrength.fair:
        return AppColors.red;
      case PasswordStrength.strong:
        return AppColors.green;
      case PasswordStrength.veryStrong:
        return AppColors.green;
      case null:
        return scheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _getColor(scheme);
    final progress = (entropy / 128).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ENTROPY STRENGTH',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: scheme.onSurface,
              ),
            ),
            Text(
              '${entropy.toStringAsFixed(1)} BITS',
              style: TextStyle(
                fontFamily: 'Roboto Mono',
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Stack(
          children: [
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: scheme.outline, width: 2.0),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 12,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: scheme.outline, width: 2.0),
                  ),
                );
              }
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          strength?.label.toUpperCase() ?? 'NONE',
          style: TextStyle(
            fontFamily: 'Roboto Mono',
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _ConfigurationCard extends StatelessWidget {
  final double length;
  final ValueChanged<double> onLengthChanged;
  final ValueChanged<double> onLengthChangeEnd;
  final bool uppercase;
  final ValueChanged<bool> onUppercaseChanged;
  final bool lowercase;
  final ValueChanged<bool> onLowercaseChanged;
  final bool numbers;
  final ValueChanged<bool> onNumbersChanged;
  final bool symbols;
  final ValueChanged<bool> onSymbolsChanged;

  const _ConfigurationCard({
    required this.length,
    required this.onLengthChanged,
    required this.onLengthChangeEnd,
    required this.uppercase,
    required this.onUppercaseChanged,
    required this.lowercase,
    required this.onLowercaseChanged,
    required this.numbers,
    required this.onNumbersChanged,
    required this.symbols,
    required this.onSymbolsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: scheme.outline, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PASSWORD LENGTH',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: scheme.outline, width: 2.0),
                ),
                child: Text(
                  '${length.round()}',
                  style: const TextStyle(
                    fontFamily: 'Roboto Mono',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 12,
              activeTrackColor: AppColors.red,
              inactiveTrackColor: scheme.outline.withValues(alpha: 0.1),
              thumbColor: AppColors.red,
              overlayColor: AppColors.red.withValues(alpha: 0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 0),
              trackShape: const RectangularSliderTrackShape(),
            ),
            child: Slider(
              value: length,
              min: 4,
              max: 64,
              divisions: 60,
              onChanged: onLengthChanged,
              onChangeEnd: onLengthChangeEnd,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'CHARACTER TYPES',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _PillChip(label: 'UPPERCASE', selected: uppercase, onChanged: onUppercaseChanged),
              _PillChip(label: 'LOWERCASE', selected: lowercase, onChanged: onLowercaseChanged),
              _PillChip(label: 'NUMBERS', selected: numbers, onChanged: onNumbersChanged),
              _PillChip(label: 'SYMBOLS', selected: symbols, onChanged: onSymbolsChanged),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _PillChip({required this.label, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onChanged(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? Colors.white : scheme.outline,
            width: 2.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto Mono',
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : scheme.onSurface,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _ExclusionSection extends StatelessWidget {
  final bool excludeSimilar;
  final ValueChanged<bool> onExcludeSimilarChanged;
  final bool excludeAmbiguous;
  final ValueChanged<bool> onExcludeAmbiguousChanged;

  const _ExclusionSection({
    required this.excludeSimilar,
    required this.onExcludeSimilarChanged,
    required this.excludeAmbiguous,
    required this.onExcludeAmbiguousChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: scheme.outline, width: 2.0),
      ),
      child: Column(
        children: [
          _ToggleTile(
            title: 'EXCLUDE SIMILAR',
            subtitle: 'L, 1, I, O, 0',
            value: excludeSimilar,
            onChanged: onExcludeSimilarChanged,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 2, thickness: 2, color: scheme.outline),
          ),
          _ToggleTile(
            title: 'EXCLUDE AMBIGUOUS',
            subtitle: '{ } [ ] ( ) / \\ \' " ` ~ , ; : . < >',
            value: excludeAmbiguous,
            onChanged: onExcludeAmbiguousChanged,
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.base),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Roboto Mono',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.red,
              inactiveThumbColor: scheme.outline.withValues(alpha: 0.4),
              inactiveTrackColor: scheme.outline.withValues(alpha: 0.1),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySection extends StatefulWidget {
  final List<String> history;
  final ValueChanged<String> onCopy;

  const _HistorySection({required this.history, required this.onCopy});

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: scheme.outline, width: 2.0),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            leading: const Icon(Icons.history_rounded, color: AppColors.red, size: 20),
            title: Text(
              'SESSION HISTORY',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
                letterSpacing: 1.0,
              ),
            ),
            trailing: Icon(
              _isExpanded ? Icons.remove_rounded : Icons.add_rounded,
              color: scheme.onSurface,
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: widget.history.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: scheme.outline, width: 2.0),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              p,
                              style: TextStyle(
                                fontFamily: 'Roboto Mono',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            onPressed: () => widget.onCopy(p),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;
  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.red, width: 2.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Roboto Mono',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.red,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
