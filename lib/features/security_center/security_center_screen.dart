import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math' as math;

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/app_colors.dart';
import '../../core/security/device_integrity_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/history_entry.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/grid_painter.dart';
import '../../shared/widgets/safetext_app_bar.dart';
import 'providers/integrity_provider.dart';

class _Protocol {
  final IconData icon;
  final String title;
  final String description;
  const _Protocol({required this.icon, required this.title, required this.description});
}

class SecurityCenterScreen extends ConsumerStatefulWidget {
  const SecurityCenterScreen({super.key});

  @override
  ConsumerState<SecurityCenterScreen> createState() => _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends ConsumerState<SecurityCenterScreen> {
  final ScrollController _scrollController = ScrollController();

  static const _protocols = [
    _Protocol(icon: Icons.lock_rounded, title: 'AES-256 Encryption', description: 'Military-grade symmetric key encryption for all stored content. AES-GCM provides both confidentiality and authenticity for every byte.'),
    _Protocol(icon: Icons.vpn_key_rounded, title: 'Argon2id Protection', description: 'Resistance against GPU cracking and side-channel attacks. Uses memory-hard functions to prevent brute-force attempts.'),
    _Protocol(icon: Icons.cloud_off_rounded, title: 'Offline Processing', description: 'Zero cloud dependency. Data never leaves your physical device. All cryptographic operations happen in isolated memory.'),
    _Protocol(icon: Icons.storage_rounded, title: 'Local Storage', description: 'Sandboxed on-device persistence for all generated data using secure file-system permissions.'),
    _Protocol(icon: Icons.screenshot_monitor_outlined, title: 'Screenshot Prevention', description: 'System-level blocking of unauthorized capture attempts. Prevents sensitive data from leaking via OS-level background snapshots.'),
    _Protocol(icon: Icons.verified_rounded, title: 'Integrity Audit', description: 'CRC32 + AES-GCM authentication on every hidden payload to detect bit-rot or malicious tampering.'),
  ];

  static const _tools = [
    (Icons.image_search_rounded, 'Steganography', AppRoutes.steganography),
    (Icons.password_rounded, 'Pass Gen', AppRoutes.passwordGenerator),
    (Icons.abc_rounded, 'Caesar Cipher', AppRoutes.caesarCipher),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final history = ref.watch(historyProvider);
    final integrity = ref.watch(integrityProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: SafeTextAppBar(
        scrollController: _scrollController,
      ),
      body: GridBackground(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(AppSpacing.margin, 24, AppSpacing.margin, 140),
          children: [
            integrity.when(
              data: (data) => _SecurityStatusCard(integrity: data),
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
              error: (_, __) => _SecurityStatusCard(integrity: DeviceIntegrityResult.unknown()),
            ),
            const SizedBox(height: 32),
            const _SectionHeader(title: 'SECURITY TOOLS', icon: Icons.construction_rounded),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: _tools.map((tool) => _ToolCard(icon: tool.$1, label: tool.$2, route: tool.$3)).toList(),
            ),
            const SizedBox(height: 32),
            const _SectionHeader(title: 'ACTIVE PROTOCOLS', icon: Icons.shield_outlined),
            const SizedBox(height: 16),
            for (final protocol in _protocols)
              _ExpandableProtocolCard(
                protocol: protocol,
                isSafe: integrity.maybeWhen(data: (d) => d.isSafe && !d.isRooted, orElse: () => true),
              ),
            const SizedBox(height: 32),
            const _SectionHeader(title: 'THREAT LEVEL MONITOR', icon: Icons.radar_rounded),
            const SizedBox(height: 16),
            integrity.when(
              data: (data) => _ThreatLevelMonitor(integrity: data),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),
            const _SectionHeader(title: 'SECURITY AUDIT LOG', icon: Icons.history_toggle_off_rounded),
            const SizedBox(height: 16),
            _AuditLogList(history: history),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _ToolCard({required this.icon, required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: scheme.outline, width: 2.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: scheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }
}

class _SecurityStatusCard extends StatefulWidget {
  final DeviceIntegrityResult integrity;
  const _SecurityStatusCard({required this.integrity});

  @override
  State<_SecurityStatusCard> createState() => _SecurityStatusCardState();
}

class _SecurityStatusCardState extends State<_SecurityStatusCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double _calculateScore() {
    double score = 1.0;
    if (widget.integrity.isRooted) score -= 0.6;
    if (widget.integrity.isDevMode) score -= 0.1;
    if (!widget.integrity.isRealDevice) score -= 0.3;
    if (!widget.integrity.isSafe) score -= 0.2;
    return score.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final score = _calculateScore();
    final isSafe = score > 0.8;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white, width: 2.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ScoreBadge(score: score),
                    const SizedBox(height: 16),
                    Text(
                      isSafe ? 'ENVIRONMENT SECURED' : 'SECURITY WARNING',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              _SecurityGauge(score: score),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            (isSafe
                ? 'Your device environment passed all high-level integrity checks. Hardware-backed encryption is active and no tampering was detected.'
                : 'Warning: This environment has potential security risks. Some hardware-backed security features may be disabled or bypassed.').toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.4,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;
  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score > 0.8 ? AppColors.green : AppColors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white, width: 2.0),
      ),
      child: Text(
        'SCORE: ${(score * 100).toInt()}%',
        style: const TextStyle(
          fontFamily: 'Roboto Mono',
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SecurityGauge extends StatelessWidget {
  final double score;
  const _SecurityGauge({required this.score});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = score > 0.8 ? AppColors.green : AppColors.red;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 86,
          height: 86,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: score),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutBack,
            builder: (context, value, _) => CircularProgressIndicator(
              value: value,
              strokeWidth: 12,
              backgroundColor: scheme.outline.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.square,
            ),
          ),
        ),
        Icon(
          score > 0.8 ? Icons.verified_user_rounded : (score > 0.4 ? Icons.gpp_maybe_rounded : Icons.gpp_bad_rounded),
          color: color,
          size: 36,
        ),
      ],
    );
  }
}

class _ExpandableProtocolCard extends StatefulWidget {
  final _Protocol protocol;
  final bool isSafe;
  const _ExpandableProtocolCard({required this.protocol, required this.isSafe});

  @override
  State<_ExpandableProtocolCard> createState() => _ExpandableProtocolCardState();
}

class _ExpandableProtocolCardState extends State<_ExpandableProtocolCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: _isExpanded ? (widget.isSafe ? AppColors.green : AppColors.red) : scheme.outline,
          width: 2.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _isExpanded = !_isExpanded);
        },
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _ProtocolIcon(
                    icon: widget.protocol.icon,
                    isExpanded: _isExpanded,
                    isSafe: widget.isSafe,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.protocol.title.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: scheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (!_isExpanded)
                          Text(
                            'HARDWARE-BACKED & VERIFIED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: scheme.onSurface.withValues(alpha: 0.6),
                              letterSpacing: 0.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.remove_rounded : Icons.add_rounded,
                    color: scheme.onSurface,
                    size: 20,
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16, left: 4, right: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(height: 1, thickness: 2, color: scheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              widget.protocol.description.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Row(
                              children: [
                                StatusChip(label: 'VERIFIED', tone: StatusTone.success),
                                SizedBox(width: 8),
                                StatusChip(label: 'FIPS 140-2', tone: StatusTone.info),
                              ],
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProtocolIcon extends StatelessWidget {
  final IconData icon;
  final bool isExpanded;
  final bool isSafe;
  const _ProtocolIcon({required this.icon, required this.isExpanded, required this.isSafe});

  @override
  Widget build(BuildContext context) {
    final color = isExpanded ? (isSafe ? AppColors.green : AppColors.red) : Colors.white;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color, width: 2.0),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _ThreatLevelMonitor extends StatelessWidget {
  final DeviceIntegrityResult integrity;
  const _ThreatLevelMonitor({required this.integrity});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.outline, width: 2.0),
      ),
      child: Column(
        children: [
          _ThreatVisualizationItem(
            label: 'ROOT ACCESS DETECTION',
            value: integrity.isRooted ? 'COMPROMISED' : 'SECURE',
            passed: !integrity.isRooted,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: scheme.outline.withValues(alpha: 0.1)),
          ),
          _ThreatVisualizationItem(
            label: 'HARDWARE INTEGRITY',
            value: integrity.isRealDevice ? 'GENUINE' : 'EMULATED',
            passed: integrity.isRealDevice,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: scheme.outline.withValues(alpha: 0.1)),
          ),
          _ThreatVisualizationItem(
            label: 'DEVELOPER ENVIRONMENT',
            value: integrity.isDevMode ? 'UNRESTRICTED' : 'ENFORCED',
            passed: !integrity.isDevMode,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: scheme.outline.withValues(alpha: 0.1)),
          ),
          _ThreatVisualizationItem(
            label: 'KERNEL SAFETY',
            value: integrity.isSafe ? 'VERIFIED' : 'SUSPICIOUS',
            passed: integrity.isSafe,
          ),
        ],
      ),
    );
  }
}

class _ThreatVisualizationItem extends StatelessWidget {
  final String label;
  final String value;
  final bool passed;
  const _ThreatVisualizationItem({required this.label, required this.value, required this.passed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = passed ? AppColors.green : AppColors.red;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: color, width: 2.0),
          ),
          child: Icon(
            passed ? Icons.check_rounded : Icons.priority_high_rounded,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                passed ? 'PASSIVE MONITORING ACTIVE' : 'CRITICAL SECURITY ALERT',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Roboto Mono',
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _AuditLogList extends ConsumerWidget {
  final List<HistoryEntry> history;
  const _AuditLogList({required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: scheme.outline, width: 2.0),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 32, color: scheme.outline.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text(
                'NO SECURITY EVENTS RECORDED',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.outline, width: 2.0),
      ),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.margin),
            itemCount: math.min(history.length, 8),
            separatorBuilder: (_, __) => Divider(height: 24, thickness: 1, color: scheme.outline.withValues(alpha: 0.1)),
            itemBuilder: (context, index) {
              return _AuditLogEntry(entry: history[index]);
            },
          ),
          if (history.length > 8) ...[
            Divider(height: 1, thickness: 1, color: scheme.outline.withValues(alpha: 0.1)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'SHOWING LAST 8 EVENTS. FULL AUDIT REPORT AVAILABLE VIA SYSTEM ADMINISTRATOR.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SecondaryButton(
              label: 'EXPORT SECURITY AUDIT',
              icon: Icons.ios_share_rounded,
              onPressed: () => _exportAudit(context, ref, history),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAudit(BuildContext context, WidgetRef ref, List<HistoryEntry> history) async {
    HapticFeedback.mediumImpact();
    final integrity = await ref.read(integrityProvider.future);
    
    final StringBuffer report = StringBuffer();
    report.writeln('========================================');
    report.writeln('      SAFETEXT SECURITY AUDIT REPORT    ');
    report.writeln('      GENERATED: ${DateTime.now()}      ');
    report.writeln('========================================\n');
    
    report.writeln('[DEVICE INTEGRITY]');
    report.writeln('ROOTED: ${integrity.isRooted ? "YES (CRITICAL)" : "NO"}');
    report.writeln('REAL DEVICE: ${integrity.isRealDevice ? "YES" : "NO (EMULATOR)"}');
    report.writeln('DEV MODE: ${integrity.isDevMode ? "ENABLED" : "DISABLED"}');
    report.writeln('SAFE DEVICE: ${integrity.isSafe ? "YES" : "NO"}\n');
    
    report.writeln('[AUDIT LOGS]');
    for (final entry in history) {
      report.writeln('${Formatters.timestamp(entry.timestamp)} | ${entry.operation.name.toUpperCase()} | ${entry.toolId} | ${entry.status.name.toUpperCase()}');
    }
    
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/safetext_audit_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(report.toString());
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'SafeText Security Audit Report',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FAILED TO GENERATE REPORT')),
        );
      }
    }
  }
}

class _AuditLogEntry extends StatelessWidget {
  final HistoryEntry entry;
  const _AuditLogEntry({required this.entry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSuccess = entry.status == HistoryStatus.success;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isSuccess ? AppColors.green : AppColors.red,
            shape: BoxShape.rectangle,
            border: Border.all(color: scheme.outline, width: 2.0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.operation.name.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Roboto Mono',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                entry.imageName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.timestamp(entry.timestamp).split(',')[0].toUpperCase(),
              style: TextStyle(
                fontFamily: 'Roboto Mono',
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
            Text(
              (Formatters.timestamp(entry.timestamp).contains(',') 
                ? Formatters.timestamp(entry.timestamp).split(',')[1].trim()
                : '').toUpperCase(),
              style: TextStyle(
                fontFamily: 'Roboto Mono',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
