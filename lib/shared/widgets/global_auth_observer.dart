import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers/settings_providers.dart';
import '../../app/routes.dart';
import '../dialogs/security_gate_dialog.dart';

class GlobalAuthObserver extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalAuthObserver({super.key, required this.child});

  @override
  ConsumerState<GlobalAuthObserver> createState() => _GlobalAuthObserverState();
}

class _GlobalAuthObserverState extends ConsumerState<GlobalAuthObserver> with WidgetsBindingObserver {
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = ref.read(settingsProvider);
    if (!settings.isPasswordSet) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Set locked state when app goes to background or becomes inactive
      ref.read(lockStateProvider.notifier).state = true;
    } else if (state == AppLifecycleState.resumed) {
      final isLocked = ref.read(lockStateProvider);
      if (isLocked && !_isDialogOpen) {
        _showLockScreen();
      }
    }
  }

  Future<void> _showLockScreen() async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    setState(() => _isDialogOpen = true);
    
    final authenticated = await SecurityGateDialog.show(
      context,
      title: 'APP LOCKED',
      message: 'AUTHENTICATION IS REQUIRED TO RESUME.',
    );
    
    if (mounted) {
      setState(() => _isDialogOpen = false);
      if (authenticated) {
        ref.read(lockStateProvider.notifier).state = false;
      } else {
        // If they cancel, keep it locked and re-show or exit
        // Forcing a re-show on next resume or exiting is safer
        SystemNavigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
