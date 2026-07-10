import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app/app.dart';
import 'core/security/device_security_service.dart';
import 'data/datasources/hive_boxes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Securely initialize Hive with hardware-anchored encryption
  final deviceSecurity = DeviceSecurityService(const FlutterSecureStorage());
  final encryptionKey = await deviceSecurity.getDatabaseKey();

  await HiveBoxes.init(encryptionKey: encryptionKey);

  runApp(const ProviderScope(child: SafeTextApp()));
}
