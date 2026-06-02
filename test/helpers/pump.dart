import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 🛡️ STEP 1-2 要件：pumpの共通化、および可視ウィジェットの確実なタップ（tapVisible）
extension KendoWidgetTesterX on WidgetTester {
  Future<void> pumpApp(Widget widget) async {
    await pumpWidget(widget);
    await pump();
  }

  Future<void> tapVisible(Finder finder) async {
    ensureVisible(finder);
    await tap(finder);
    await pumpAndSettle();
  }
}
