import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../shared/widgets/grid_painter.dart';
import '../../shared/widgets/quick_action_card.dart';
import '../../shared/widgets/safetext_app_bar.dart';
import '../../shared/widgets/status_chip.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: SafeTextAppBar(
        scrollController: _scrollController,
        statusPill: const StatusChip(label: 'SECURE', tone: StatusTone.success, dot: true),
      ),
      body: GridBackground(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: [
            _HeroCard(now: _now, scheme: scheme),
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
            borderRadius: BorderRadius.circular(24),
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

class _HeroCard extends StatelessWidget {
  final DateTime now;
  final ColorScheme scheme;

  const _HeroCard({required this.now, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(4),
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
                      const SizedBox(height: 16),
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
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border.all(color: scheme.outline, width: 2.0),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.qr_code_scanner_rounded, size: 40, color: scheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
