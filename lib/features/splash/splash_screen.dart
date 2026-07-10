import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final bool onboardingComplete;
  const SplashScreen({super.key, required this.onboardingComplete});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _pulseController;
  late final AnimationController _bgController;
  
  late final Animation<double> _logoScale;
  late final Animation<double> _nameFade;
  late final Animation<double> _taglineSlide;
  late final Animation<double> _statusFade;
  late final Animation<double> _loadingProgress;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();

    _logoScale = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
    );
    _nameFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
    );
    _taglineSlide = Tween<double>(begin: 20, end: 0).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.5, 0.8, curve: Curves.easeOutCubic),
    ));
    _statusFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.7, 0.9, curve: Curves.easeIn),
    );
    _loadingProgress = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.95, curve: Curves.easeInOut),
    ));

    _mainController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final settings = ref.read(settingsProvider);
    if (settings.historyExpiryEnabled) {
      await ref.read(historyProvider.notifier).deleteExpired(Duration(days: settings.historyExpiryDays));
    }

    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    context.go(widget.onboardingComplete ? AppRoutes.home : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _bgController.dispose();
    super.dispose();
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
          
          // Particle Mesh Background (Digital style)
          Positioned.fill(
            child: CustomPaint(
              painter: _ParticlePainter(
                color: scheme.primary.withValues(alpha: 0.1),
                animationValue: _bgController.value,
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with Pulse
                ScaleTransition(
                  scale: _logoScale,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: scheme.primary,
                            width: 2.0 + (1.0 * _pulseController.value),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.shield_rounded, 
                          color: scheme.primary, 
                          size: 52,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                
                // Name Fade-in
                FadeTransition(
                  opacity: _nameFade,
                  child: Text(
                    'SAFETEXT',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                  ),
                ),
                
                // Tagline Slide-up
                AnimatedBuilder(
                  animation: _taglineSlide,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _taglineSlide.value),
                      child: Opacity(
                        opacity: _nameFade.value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'PRIVATE MESSAGES HIDDEN IN PLAIN SIGHT',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 64),
                
                // Status Pill
                FadeTransition(
                  opacity: _statusFade,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: scheme.outline, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: scheme.secondary, // Green
                                shape: BoxShape.rectangle,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'INITIALIZING SECURE VAULT',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: scheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Loading Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      border: Border.all(color: scheme.outline, width: 2),
                    ),
                    alignment: Alignment.centerLeft,
                    child: AnimatedBuilder(
                      animation: _loadingProgress,
                      builder: (context, child) {
                        return FractionallySizedBox(
                          widthFactor: _loadingProgress.value,
                          child: Container(
                            height: double.infinity,
                            color: scheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
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

    const spacing = 30.0;
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


class _ParticlePainter extends CustomPainter {
  final Color color;
  final double animationValue;
  final List<Offset> points = [];
  final Random random = Random(42);

  _ParticlePainter({required this.color, required this.animationValue}) {
    for (int i = 0; i < 40; i++) {
      points.add(Offset(random.nextDouble(), random.nextDouble()));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final x = (p.dx * size.width + sin(animationValue * 2 * pi + i) * 20) % size.width;
      final y = (p.dy * size.height + cos(animationValue * 2 * pi + i) * 20) % size.height;
      
      canvas.drawCircle(Offset(x, y), 1.5, paint);
      
      // Connect nearby particles
      for (var j = i + 1; j < points.length; j++) {
        final p2 = points[j];
        final x2 = (p2.dx * size.width + sin(animationValue * 2 * pi + j) * 20) % size.width;
        final y2 = (p2.dy * size.height + cos(animationValue * 2 * pi + j) * 20) % size.height;
        
        final dist = sqrt(pow(x - x2, 2) + pow(y - y2, 2));
        if (dist < 100) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x2, y2),
            Paint()
              ..color = color.withValues(alpha: color.a * (1 - dist / 100))
              ..strokeWidth = 0.5,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
