import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/share_intent_service.dart';
import '../../data/models/history_entry.dart';
import '../encode/providers/encode_provider.dart';
import '../../shared/widgets/grid_painter.dart';
import '../../shared/widgets/quick_action_card.dart';
import '../../shared/widgets/safetext_app_bar.dart';
import '../../shared/widgets/status_chip.dart';
import '../security_center/providers/integrity_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription? _shareSubscription;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _checkInitialShareIntent();
    _listenToShareIntents();
  }

  void _listenToShareIntents() {
    _shareSubscription = ShareIntentService().shareStream.listen((files) {
      if (files.isNotEmpty) {
        _handleSharedFiles(files);
      }
    });
  }

  Future<void> _checkInitialShareIntent() async {
    final sharedFiles = await ShareIntentService().getInitialSharedFiles();
    if (sharedFiles != null && sharedFiles.isNotEmpty) {
      _handleSharedFiles(sharedFiles);
    }
  }

  Future<void> _handleSharedFiles(List<String> paths) async {
    if (!mounted) return;
    
    final path = paths.first;
    final file = File(path);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      final name = path.split('/').last;
      
      await ref.read(encodeProvider.notifier).setImage(bytes, name);
      if (mounted) {
        context.push(AppRoutes.encode);
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    _shareSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final history = ref.watch(historyProvider);
    final integrity = ref.watch(integrityProvider);

    return Scaffold(
      appBar: SafeTextAppBar(
        scrollController: _scrollController,
        statusPill: integrity.maybeWhen(
          data: (d) => StatusChip(
            label: d.isSafe ? 'SECURE' : 'RISK',
            tone: d.isSafe ? StatusTone.success : StatusTone.danger,
            dot: true,
          ),
          orElse: () => const StatusChip(label: 'SCANNING', tone: StatusTone.info, dot: true),
        ),
      ),
      body: GridBackground(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: [
            _HeroCard(now: _now, scheme: scheme, historyCount: history.length),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'PRIMARY OPERATIONS', icon: Icons.terminal_rounded),
            const SizedBox(height: 16),
            QuickActionCard(
              icon: Icons.security_rounded,
              color: AppColors.green,
              title: 'SYSTEM SECURITY SCAN',
              subtitle: 'PERFORM FULL DEVICE INTEGRITY & AUDIT ASSESSMENT',
              onTap: () => context.push(AppRoutes.security),
            ),
            const SizedBox(height: 12),
            QuickActionCard(
              icon: Icons.lock_outline_rounded,
              color: scheme.primary,
              title: 'SECURE ENCODING',
              subtitle: 'ENCRYPT AND CONCEAL TEXT WITHIN CARRIER MEDIA',
              onTap: () => context.push(AppRoutes.encode),
            ),
            const SizedBox(height: 12),
            QuickActionCard(
              icon: Icons.vpn_key_outlined,
              color: AppColors.red,
              title: 'EXTRACT & DECODE',
              subtitle: 'REVEAL HIDDEN MESSAGES FROM SECURED IMAGES',
              onTap: () => context.push(AppRoutes.decode),
            ),
            const SizedBox(height: 24),
            if (history.isNotEmpty) ...[
              const _SectionHeader(title: 'RECENT ACTIVITY', icon: Icons.history_rounded),
              const SizedBox(height: 16),
              ...history.reversed.take(3).map((entry) => _RecentActivityTile(entry: entry)),
              const SizedBox(height: 8),
              SecondaryButton(
                label: 'VIEW FULL HISTORY',
                onPressed: () => context.push(AppRoutes.history),
              ),
            ],
            const SizedBox(height: 24),
            const _SectionHeader(title: 'EXTENDED UTILITIES', icon: Icons.extension_rounded),
            const SizedBox(height: 16),
            QuickActionCard(
              icon: Icons.qr_code_2_rounded,
              color: AppColors.blue,
              title: 'QR VAULT',
              subtitle: 'SECURE QR GENERATION & ENCRYPTED DATA SCANNING',
              onTap: () => context.push(AppRoutes.qrVault),
            ),
            const SizedBox(height: 12),
            QuickActionCard(
              icon: Icons.image_search_rounded,
              color: scheme.secondary,
              title: 'STEGANOGRAPHY LAB',
              subtitle: 'ADVANCED PIXEL-LEVEL CONCEALMENT PROTOCOLS',
              onTap: () => context.push(AppRoutes.steganography),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const SecondaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: BorderSide(color: scheme.outline, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        foregroundColor: scheme.onSurface,
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0),
      ),
    );
  }
}

class _RecentActivityTile extends StatelessWidget {
  final HistoryEntry entry;
  const _RecentActivityTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEncoded = entry.operation == HistoryOperation.encoded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.outline, width: 2.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isEncoded ? scheme.primary : AppColors.red).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: isEncoded ? scheme.primary : AppColors.red, width: 1),
            ),
            child: Icon(
              isEncoded ? Icons.lock_rounded : Icons.lock_open_rounded,
              size: 18,
              color: isEncoded ? scheme.primary : AppColors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.imageName.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${entry.operation.name.toUpperCase()} · ${DateFormat('MMM d, HH:mm').format(entry.timestamp).toUpperCase()}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          StatusChip(
            label: entry.status == HistoryStatus.success ? 'OK' : 'FAIL',
            tone: entry.status == HistoryStatus.success ? StatusTone.success : StatusTone.danger,
          ),
        ],
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
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: scheme.primary,
            fontFamily: 'Roboto Mono',
          ),
        ),
      ],
    );
  }
}

class _ShimmerTile extends StatefulWidget {
  const _ShimmerTile();

  @override
  State<_ShimmerTile> createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<_ShimmerTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            gradient: LinearGradient(
              colors: [
                scheme.surfaceContainerLow,
                scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                scheme.surfaceContainerLow,
              ],
              stops: [0.0, _controller.value, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
          ),
        );
      },
    );
  }
}

class _HeroCard extends ConsumerWidget {
  final DateTime now;
  final ColorScheme scheme;
  final int historyCount;

  const _HeroCard({required this.now, required this.scheme, required this.historyCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final integrity = ref.watch(integrityProvider);
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        color: scheme.surface,
        border: Border.all(color: scheme.outline, width: 2.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.shield_rounded,
              size: 160,
              color: scheme.outline.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: scheme.outline, width: 2.0),
                      ),
                      child: const Text(
                        'SYSTEM STATUS: ACTIVE',
                        style: TextStyle(
                          fontFamily: 'Roboto Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      'V1.0.0-SEC',
                      style: TextStyle(
                        fontFamily: 'Roboto Mono',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                integrity.maybeWhen(
                  data: (data) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEVICE: ${data.deviceModel.toUpperCase()}',
                          style: TextStyle(
                            fontFamily: 'Roboto Mono',
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          'OS: ${data.osVersion.toUpperCase()}',
                          style: TextStyle(
                            fontFamily: 'Roboto Mono',
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('HH:mm:ss').format(now),
                            style: const TextStyle(
                              fontFamily: 'Roboto Mono',
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, MMM d').format(now).toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: scheme.primary,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          historyCount.toString().padLeft(3, '0'),
                          style: const TextStyle(
                            fontFamily: 'Roboto Mono',
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'TOTAL AUDITS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
