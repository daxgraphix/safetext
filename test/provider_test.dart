import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:safetext/app/providers/settings_providers.dart';
import 'package:safetext/app/providers/history_providers.dart';
import 'package:safetext/app/providers/services_providers.dart';
import 'package:safetext/core/constants/app_constants.dart';
import 'package:safetext/data/datasources/hive_boxes.dart';
import 'package:safetext/features/encode/providers/encode_provider.dart';
import 'package:safetext/features/decode/providers/decode_provider.dart';
import 'package:safetext/data/models/history_entry.dart';
import 'package:safetext/data/models/security_settings.dart';
import 'package:safetext/data/repositories/history_repository.dart';
import 'package:safetext/data/repositories/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('safetext_hive_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HistoryEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SecuritySettingsAdapter());
    }
    HiveBoxes.historyBox = await Hive.openBox<HistoryEntry>(AppConstants.historyBoxName);
    HiveBoxes.settingsBox = await Hive.openBox(AppConstants.settingsBoxName);
  });

  tearDownAll(() async {
    await HiveBoxes.historyBox.close();
    await HiveBoxes.settingsBox.close();
  });

  group('SettingsNotifier', () {
    test('toggles dark mode and persists', () async {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(const SettingsRepository()),
        ],
      );
      final notifier = container.read(settingsProvider.notifier);

      expect(container.read(settingsProvider).darkMode, isTrue);
      await notifier.toggleDarkMode(false);
      expect(container.read(settingsProvider).darkMode, isFalse);
    });

    test('changes default stego mode', () async {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(const SettingsRepository()),
        ],
      );
      final notifier = container.read(settingsProvider.notifier);

      await notifier.setDefaultStegoMode(StegoMode.armor);
      expect(container.read(settingsProvider).defaultStegoMode, StegoMode.armor);
    });
  });

  group('EncodeNotifier', () {
    test('clears stale validation errors once the user edits the passphrase', () async {
      final container = ProviderContainer();
      final notifier = container.read(encodeProvider.notifier);

      await notifier.encode();
      expect(container.read(encodeProvider).stage, EncodeStage.error);
      expect(container.read(encodeProvider).errorMessage, isNotNull);

      notifier.setPassphrase('long-enough-passphrase');

      expect(container.read(encodeProvider).errorMessage, isNull);
    });
  });

  group('DecodeNotifier', () {
    test('surfaces a clear message when no payload is present', () async {
      final container = ProviderContainer();
      final notifier = container.read(decodeProvider.notifier);

      await notifier.decode();

      expect(container.read(decodeProvider).stage, DecodeStage.error);
      expect(container.read(decodeProvider).errorMessage, contains('No SafeText payload'));
    });
  });

  group('HistoryNotifier', () {
    test('adds and retrieves entries', () async {
      final container = ProviderContainer(
        overrides: [
          historyRepositoryProvider.overrideWithValue(const HistoryRepository()),
        ],
      );
      final notifier = container.read(historyProvider.notifier);

      final entry = HistoryEntry(
        id: 'test-1',
        operation: HistoryOperation.encoded,
        imageName: 'test.png',
        mode: 'ghost',
        timestamp: DateTime.now(),
        status: HistoryStatus.success,
        toolId: HistoryTool.safetext,
      );
      await notifier.add(entry);
      expect(container.read(historyProvider).length, greaterThanOrEqualTo(1));
    });

    test('deletes entry by id', () async {
      final container = ProviderContainer(
        overrides: [
          historyRepositoryProvider.overrideWithValue(const HistoryRepository()),
        ],
      );
      final notifier = container.read(historyProvider.notifier);

      final entry = HistoryEntry(
        id: 'test-delete-${DateTime.now().millisecondsSinceEpoch}',
        operation: HistoryOperation.encoded,
        imageName: 'test.png',
        mode: 'ghost',
        timestamp: DateTime.now(),
        status: HistoryStatus.success,
        toolId: HistoryTool.safetext,
      );
      await notifier.add(entry);
      final countBefore = container.read(historyProvider).length;
      await notifier.delete(entry.id);
      expect(container.read(historyProvider).length, lessThan(countBefore));
    });
  });
}
