import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_settings_bottom_sheet.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('🛡️ ViewerSettingsBottomSheet Widget Tests', () {
    testWidgets('Renders theme options and liquid glass switch', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(
            home: Scaffold(body: ViewerSettingsBottomSheet()),
          ),
        ),
      );

      expect(find.text('表示設定'), findsOneWidget);
      expect(find.text('テーマの切り替え'), findsOneWidget);
      expect(find.text('省エネモード（背景アニメーション停止）'), findsOneWidget);
      expect(find.text('サーマル冷却・省電力制御'), findsOneWidget);
    });
  });
}
