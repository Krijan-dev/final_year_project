import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:life_pattern_tracker/main.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync("life_pattern_hive_test");
    Hive.init(dir.path);
  });

  testWidgets("LifePatternApp builds", (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LifePatternApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
