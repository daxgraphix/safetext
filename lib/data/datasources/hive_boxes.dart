import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../models/history_entry.dart';
import '../models/security_settings.dart';

/// Central place to initialize Hive and register generated adapters.
class HiveBoxes {
  HiveBoxes._();

  static late Box historyBox;
  static late Box settingsBox;

  static Future<void> init({Uint8List? encryptionKey}) async {
    await Hive.initFlutter();

    // Registering Generated Adapters
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(HistoryOperationAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(HistoryEntryAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(HistoryStatusAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(SecuritySettingsAdapter());

    final strategy = encryptionKey != null ? HiveAesCipher(encryptionKey) : null;

    historyBox = await Hive.openBox<HistoryEntry>(
      AppConstants.historyBoxName,
      encryptionCipher: strategy,
    );
    settingsBox = await Hive.openBox(
      AppConstants.settingsBoxName,
      encryptionCipher: strategy,
    );
  }
}
