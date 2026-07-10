import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:safetext/app/app.dart';
import 'package:safetext/data/datasources/hive_boxes.dart';
import 'package:safetext/data/models/history_entry.dart';
import 'package:safetext/data/models/security_settings.dart';

void main() {
  setUpAll(() async {
    Hive.init('./test/hive_test');
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HistoryEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SecuritySettingsAdapter());
    }
    await HiveBoxes.init();
  });

  tearDownAll(() async {
    await HiveBoxes.historyBox.close();
    await HiveBoxes.settingsBox.close();
  });

  testWidgets('SafeTextApp starts on splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SafeTextApp()));
    expect(find.text('SafeText'), findsOneWidget);
  });
}
