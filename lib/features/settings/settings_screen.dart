import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/formatters.dart';
import '../../shared/dialogs/confirm_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int? _cacheBytes;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final size = await const StorageService().cacheSizeBytes();
    if (mounted) setState(() => _cacheBytes = size);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Colors.white, width: 2)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        children: [
          const _SectionLabel('APPEARANCE'),
          _SettingsCard(children: [
            _SwitchRow(
              icon: Icons.dark_mode_outlined,
              title: 'DARK MODE',
              subtitle: 'REDUCE EYE STRAIN IN LOW LIGHT',
              value: settings.darkMode,
              onChanged: notifier.toggleDarkMode,
            ),
            Container(height: 2, color: scheme.outline),
            _SwitchRow(
              icon: Icons.notifications_none_rounded,
              title: 'COMPRESSION WARNING',
              subtitle: 'NOTIFY ABOUT RISK DURING SHARING',
              value: settings.compressionWarningEnabled,
              onChanged: notifier.toggleCompressionWarning,
            ),
          ]),
          const SizedBox(height: 32),
          const _SectionLabel('SECURITY & PRIVACY'),
          _SettingsCard(children: [
            _SwitchRow(
              icon: Icons.content_paste_off_rounded,
              title: 'AUTO-CLEAR CLIPBOARD',
              subtitle: 'CLEAR SENSITIVE DATA AFTER 2 MINUTES',
              value: settings.autoClearClipboard,
              onChanged: notifier.toggleAutoClearClipboard,
            ),
            Container(height: 2, color: scheme.outline),
            _SwitchRow(
              icon: Icons.visibility_off_outlined,
              title: 'HIDE APP PREVIEWS',
              subtitle: 'BLUR CONTENT IN APP SWITCHER',
              value: settings.hideAppPreviews,
              onChanged: notifier.toggleHideAppPreviews,
            ),
            Container(height: 2, color: scheme.outline),
            _SwitchRow(
              icon: Icons.screenshot_monitor_outlined,
              title: 'BLOCK SCREENSHOTS',
              subtitle: 'PREVENT CAPTURE ON SENSITIVE SCREENS',
              value: settings.blockScreenshots,
              onChanged: notifier.toggleBlockScreenshots,
            ),
            Container(height: 2, color: scheme.outline),
            _SwitchRow(
              icon: Icons.auto_delete_outlined,
              title: 'HISTORY AUTO-EXPIRY',
              subtitle: 'WIPE OLD HISTORY ENTRIES AUTOMATICALLY',
              value: settings.historyExpiryEnabled,
              onChanged: notifier.toggleHistoryExpiry,
            ),
            if (settings.historyExpiryEnabled) ...[
              Container(height: 2, color: scheme.outline),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 36),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EXPIRY THRESHOLD',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: scheme.onSurface,
                                ),
                              ),
                              Text(
                                '${settings.historyExpiryDays} DAYS',
                                style: const TextStyle(
                                  fontFamily: 'Roboto Mono',
                                  fontSize: 12,
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: scheme.primary,
                        inactiveTrackColor: scheme.outline.withValues(alpha: 0.1),
                        thumbColor: scheme.primary,
                        trackHeight: 6,
                      ),
                      child: Slider(
                        value: settings.historyExpiryDays.toDouble(),
                        min: 1,
                        max: 365,
                        divisions: 364,
                        onChanged: (v) => notifier.setHistoryExpiryDays(v.round()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ]),
          const SizedBox(height: 32),
          const _SectionLabel('TOOL DEFAULTS'),
          _SettingsCard(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.password_rounded, color: scheme.onSurface, size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DEFAULT PASSWORD LENGTH',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: scheme.onSurface,
                              ),
                            ),
                            Text(
                              '${settings.defaultPasswordLength} CHARACTERS',
                              style: const TextStyle(
                                fontFamily: 'Roboto Mono',
                                fontSize: 12,
                                color: AppColors.green,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: scheme.primary,
                      inactiveTrackColor: scheme.outline.withValues(alpha: 0.1),
                      thumbColor: scheme.primary,
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: settings.defaultPasswordLength.toDouble(),
                      min: 4,
                      max: 64,
                      divisions: 60,
                      onChanged: (v) => notifier.setDefaultPasswordLength(v.round()),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 2, color: scheme.outline),
            _SwitchRow(
              icon: Icons.text_fields_rounded,
              title: 'INCLUDE UPPERCASE',
              value: settings.passwordIncludeUppercase,
              onChanged: notifier.togglePasswordUppercase,
            ),
            Container(height: 2, color: scheme.outline),
            _SwitchRow(
              icon: Icons.numbers_rounded,
              title: 'INCLUDE NUMBERS',
              value: settings.passwordIncludeNumbers,
              onChanged: notifier.togglePasswordNumbers,
            ),
            Container(height: 2, color: scheme.outline),
            _NavRow(
              icon: Icons.tune_rounded,
              title: 'STEGANOGRAPHY MODE',
              subtitle: settings.defaultStegoMode == StegoMode.armor ? 'ARMOR (ROBUST)' : 'GHOST (STEALTH)',
              onTap: () => _showStegoModePicker(context, settings.defaultStegoMode, notifier),
            ),
          ]),
          const SizedBox(height: 32),
          const _SectionLabel('STORAGE & DATA'),
          _SettingsCard(children: [
            _NavRow(
              icon: Icons.cleaning_services_outlined,
              title: 'CLEAR CACHE',
              subtitle: _cacheBytes != null ? 'FREE UP ${Formatters.bytes(_cacheBytes!).toUpperCase()}' : 'CALCULATING...',
              onTap: () async {
                await const StorageService().clearCache();
                await _loadCacheSize();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: scheme.onSurface,
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'CACHE CLEARED',
                        style: TextStyle(
                          color: scheme.surface,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
            Container(height: 2, color: scheme.outline),
            _NavRow(
              icon: Icons.delete_forever_outlined,
              title: 'DELETE ALL MEDIA',
              subtitle: 'PERMANENTLY WIPE GENERATED IMAGES',
              danger: true,
              onTap: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'DELETE ALL MEDIA',
                  message: 'THIS WILL PERMANENTLY DELETE EVERY SECURE IMAGE. THIS ACTION CANNOT BE UNDONE.',
                  confirmLabel: 'DELETE ALL',
                  danger: true,
                );
                if (confirmed == true) {
                  await const StorageService().clearGeneratedImages();
                  await _loadCacheSize();
                }
              },
            ),
          ]),
          const SizedBox(height: 32),
          const _SectionLabel('ABOUT SAFETEXT'),
          _SettingsCard(children: [
            _NavRow(
              icon: Icons.shield_outlined,
              title: 'PRIVACY POLICY',
              onTap: () => _showPrivacyNotice(context),
            ),
          ]),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppColors.green, size: 32),
                const SizedBox(height: 16),
                Text(
                  'SECURE ENVIRONMENT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showPrivacyNotice(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        title: const Text(
          'PRIVACY NOTICE',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
        ),
        content: const Text(
          'SAFETEXT KEEPS YOUR DATA LOCAL ON THIS DEVICE. NO DATA IS SENT TO REMOTE SERVERS.',
          style: TextStyle(fontFamily: 'Roboto Mono', fontWeight: FontWeight.w700, fontSize: 13, height: 1.5, color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CLOSE',
              style: TextStyle(fontFamily: 'Inter', color: AppColors.red, fontWeight: FontWeight.w900),
            ),
          )
        ],
      ),
    );
  }

  void _showStegoModePicker(BuildContext context, StegoMode current, SettingsNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.base)),
      ),
      builder: (context) => Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white, width: 2)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.base)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'STEGANOGRAPHY MODE',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                _PickerOption(
                  icon: Icons.visibility_off_outlined,
                  title: 'GHOST MODE',
                  subtitle: 'MAXIMUM STEALTH, SCATTERED PIXEL EMBEDDING',
                  selected: current == StegoMode.ghost,
                  onTap: () {
                    notifier.setDefaultStegoMode(StegoMode.ghost);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                _PickerOption(
                  icon: Icons.shield_outlined,
                  title: 'ARMOR MODE',
                  subtitle: 'SURVIVES COMPRESSION, REDUNDANT EMBEDDING',
                  selected: current == StegoMode.armor,
                  onTap: () {
                    notifier.setDefaultStegoMode(StegoMode.armor);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = selected ? (isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)) : Colors.transparent;
    final borderColor = selected ? (isDarkMode ? Colors.white : Colors.black) : scheme.outline;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: borderColor,
              width: 2.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected ? scheme.onSurface.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: scheme.outline, width: 1),
                ),
                child: Icon(icon, color: scheme.onSurface, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      subtitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: scheme.outline, width: 2.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.base - 2),
        child: Column(children: children),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({required this.icon, required this.title, this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: scheme.onSurface, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scheme.onSurface.withValues(alpha: 0.6)),
                      ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.green,
                activeThumbColor: Colors.white,
                inactiveTrackColor: scheme.outline.withValues(alpha: 0.2),
                inactiveThumbColor: scheme.onSurface.withValues(alpha: 0.4),
                trackOutlineColor: WidgetStateProperty.all(scheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool danger;
  final VoidCallback? onTap;

  const _NavRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = danger ? AppColors.red : scheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.6)),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: color),
          ],
        ),
      ),
    );
  }
}
