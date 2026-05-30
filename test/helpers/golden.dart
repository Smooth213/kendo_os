import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 🛡️ STEP 1-2 要件：Golden共通比較アサーションのプロトタイプ確立
Future<void> verifyGoldenView(WidgetTester tester, String screenshotName) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$screenshotName.png'),
  );
}