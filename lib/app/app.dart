import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'routes.dart';
import 'theme/app_theme.dart';
import '../shared/widgets/global_auth_observer.dart';

class SafeTextApp extends ConsumerWidget {
  const SafeTextApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return GlobalAuthObserver(
      child: MaterialApp.router(
        title: 'SafeText',
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: router,
      ),
    );
  }
}
