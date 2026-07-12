import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/services_providers.dart';
import '../features/caesar_cipher/caesar_cipher_screen.dart';
import '../features/decode/decode_result_screen.dart';
import '../features/decode/decode_screen.dart';
import '../features/encode/encode_result_screen.dart';
import '../features/encode/encode_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/password_generator/password_generator_screen.dart';
import '../features/qr_vault/qr_vault_screen.dart';
import '../features/security_center/security_center_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/steganography/lsb_des/lsb_des_screen.dart';
import '../features/steganography/lsb_text/lsb_text_screen.dart';
import '../features/steganography/steganography_home_screen.dart';
import '../shared/widgets/app_shell.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const history = '/history';
  static const security = '/security';
  static const settings = '/settings';
  static const encode = '/encode';
  static const encodeResult = '/encode/result';
  static const decode = '/decode';
  static const decodeResult = '/decode/result';

  // New modules
  static const steganography = '/steganography';
  static const stegoLsbText = '/steganography/lsb-text';
  static const stegoLsbDes = '/steganography/lsb-des';
  static const passwordGenerator = '/password-generator';
  static const caesarCipher = '/caesar-cipher';
  static const qrVault = '/qr-vault';
}

/// A helper to create consistent slide+fade transitions for full-screen flows.
CustomTransitionPage _buildPageWithTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => SplashScreen(onboardingComplete: settingsRepo.onboardingComplete),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),

      // Bottom-nav shell: Home / History / Security / Settings
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (context, state) => const HomeScreen()),
          GoRoute(path: AppRoutes.history, builder: (context, state) => const HistoryScreen()),
          GoRoute(path: AppRoutes.security, builder: (context, state) => const SecurityCenterScreen()),
          GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
        ],
      ),

      GoRoute(
        path: AppRoutes.encode,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const EncodeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.encodeResult,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const EncodeResultScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.decode,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const DecodeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.decodeResult,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const DecodeResultScreen(),
        ),
      ),

      // New modules
      GoRoute(
        path: AppRoutes.steganography,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const SteganographyHomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.stegoLsbText,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const LsbTextScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.stegoLsbDes,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const LsbDesScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.passwordGenerator,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const PasswordGeneratorScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.caesarCipher,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const CaesarCipherScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.qrVault,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const QRVaultScreen(),
        ),
      ),
    ],
  );
});
