import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';

void main() {
  group('[Widget] TextSizeMode 単体検証', () {
    testWidgets('SettingsModelにおいて textSizeModeが含まれ正しく更新されること', (tester) async {
      const settings = SettingsModel();
      expect(settings.textSizeMode, 'normal');

      final largeSettings = settings.copyWith(textSizeMode: 'large');
      expect(largeSettings.textSizeMode, 'large');

      final extraLargeSettings = settings.copyWith(textSizeMode: 'extraLarge');
      expect(extraLargeSettings.textSizeMode, 'extraLarge');
    });

    testWidgets('設定画面に文字サイズ選択セレクターが表示されること', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: SettingsScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('文字サイズ'), findsOneWidget);
    });
  });
}
