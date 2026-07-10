import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

class _OnboardPage {
  final IconData icon;
  final String title;
  final String description;
  final List<(IconData, String)>? badges;
  final bool isSecondary;
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.description,
    this.isSecondary = false,
    this.badges,
  });
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> with TickerProviderStateMixin {
  final _controller = PageController();
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  double _scrollOffset = 0;
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      icon: Icons.phone_iphone_rounded,
      title: 'Everything stays on your device',
      description: 'No cloud, no servers, no middleman. Your private data remains local and under your control.',
      badges: [
        (Icons.verified_rounded, '100% Offline'),
        (Icons.memory_rounded, 'Local Processing'),
      ],
    ),
    _OnboardPage(
      icon: Icons.lock_rounded,
      isSecondary: true,
      title: 'Protect messages with encryption',
      description: 'Every message is wrapped with AES-256-GCM authenticated encryption before it ever touches an image.',
      badges: [
        (Icons.enhanced_encryption_rounded, 'AES-256-GCM'),
        (Icons.vpn_key_rounded, 'Passphrase Protected'),
      ],
    ),
    _OnboardPage(
      icon: Icons.image_rounded,
      title: 'Hide secret messages inside images',
      description: 'Embed encrypted data directly into photos so your files stay ordinary while your secrets stay secure.',
      badges: [
        (Icons.image_search_rounded, 'Steganography'),
        (Icons.visibility_off_outlined, 'Stealth Ready'),
      ],
    ),
    _OnboardPage(
      icon: Icons.auto_awesome_rounded,
      isSecondary: true,
      title: 'Zero compromise on privacy',
      description: 'Your data is never collected, never analyzed, and never leaves your phone. Total digital sovereignty.',
      badges: [
        (Icons.analytics_outlined, 'No Tracking'),
        (Icons.history_edu_rounded, 'Audit Ready'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _controller.addListener(() {
      setState(() {
        _scrollOffset = _controller.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(settingsRepositoryProvider).setOnboardingComplete(true);
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          // High-Contrast Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(
                color: scheme.outline.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(scheme),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, index) {
                      return _OnboardPageView(
                        page: _pages[index],
                        index: index,
                        scrollOffset: _scrollOffset,
                        pulse: _pulseController,
                      );
                    },
                  ),
                ),
                _buildFooter(scheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 12, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: scheme.outline, width: 2.0),
            ),
            child: Icon(Icons.shield_rounded, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'SAFETEXT',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _finish,
            child: Text(
              'SKIP',
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 24 : 12,
                height: 12,
                decoration: BoxDecoration(
                  color: active ? scheme.primary : scheme.surface,
                  borderRadius: BorderRadius.circular(0),
                  border: Border.all(color: scheme.outline, width: 2),
                ),
              );
            }),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              if (_page > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _controller.previousPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutQuart,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: scheme.outline, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: scheme.surface,
                      elevation: 0,
                    ),
                    child: Text(
                      'BACK',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              if (_page > 0) const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _page == _pages.length - 1 ? _finish : () => _controller.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutQuart,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      side: BorderSide(color: scheme.outline, width: 2.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _page == _pages.length - 1 ? 'GET STARTED' : 'CONTINUE',
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _page == _pages.length - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _OnboardPageView extends StatelessWidget {
  final _OnboardPage page;
  final int index;
  final double scrollOffset;
  final AnimationController pulse;

  const _OnboardPageView({
    required this.page,
    required this.index,
    required this.scrollOffset,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parallax = (scrollOffset - index) * 100.0;
    final pageColor = page.isSecondary ? AppColors.red : scheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration with Parallax
          Transform.translate(
            offset: Offset(parallax, 0),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border.all(color: scheme.outline, width: 2.0),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: _IllustrationPainter(
                      type: index,
                      color: pageColor,
                      animationValue: pulse.value,
                    ),
                  ),
                  Icon(page.icon, size: 64, color: pageColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
          
          // Title
          Text(
            page.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -0.5,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          
          // Description
          Text(
            page.description.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          
          if (page.badges != null) ...[
            const SizedBox(height: 40),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final badge in page.badges!)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: scheme.outline, width: 2.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badge.$1, color: pageColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          badge.$2.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            fontFamily: 'Roboto Mono',
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

class _IllustrationPainter extends CustomPainter {
  final int type;
  final Color color;
  final double animationValue;

  _IllustrationPainter({
    required this.type,
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);

    if (type == 0) { // Device / Local
      for (var i = 1; i <= 3; i++) {
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 40.0 * i + (animationValue * 5), height: 40.0 * i + (animationValue * 5)),
          paint,
        );
      }
    } else if (type == 1) { // Encryption
      final rect = Rect.fromCenter(center: center, width: 100, height: 100);
      canvas.drawRect(rect, paint);
      for (var i = 0; i < 4; i++) {
        final angle = (i * 90) * pi / 180 + (animationValue * 0.5);
        canvas.drawLine(
          center + Offset(cos(angle) * 40, sin(angle) * 40),
          center + Offset(cos(angle) * 70, sin(angle) * 70),
          paint,
        );
      }
    } else if (type == 2) { // Steganography
      for (var x = 0; x < 4; x++) {
        for (var y = 0; y < 4; y++) {
          final p = Offset(size.width * 0.25 + x * 35, size.height * 0.25 + y * 35);
          final opacity = (sin(animationValue * 2 * pi + (x + y)) + 1) / 2 * 0.4;
          canvas.drawRect(
            Rect.fromCenter(center: p, width: 15, height: 15),
            Paint()..color = color.withValues(alpha: opacity)..style = PaintingStyle.fill,
          );
        }
      }
    } else { // Privacy
      final rect = Rect.fromCenter(center: center, width: 120, height: 120);
      canvas.drawRect(rect, paint);
      canvas.drawPath(
        Path()
          ..moveTo(center.dx - 40, center.dy - 40)
          ..lineTo(center.dx + 40, center.dy + 40)
          ..moveTo(center.dx + 40, center.dy - 40)
          ..lineTo(center.dx - 40, center.dy + 40),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter oldDelegate) => true;
}
