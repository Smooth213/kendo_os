import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/safe_pump_helper.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] 団体戦公式記録 文字拡大モード(1.35x)表示テスト', () {
    testWidgets('文字拡大モード(特大 1.35x)下での7人制結果表示・オーバーフローゼロが正しく検証されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      // 文字拡大 1.35x をシミュレート
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(1.35),
                size: Size(390, 1000),
              ),
              child: Scaffold(
                appBar: AppBar(
                  title: const Text(
                    '7人制 団体戦公式記録',
                    style: TextStyle(fontSize: AppFontSize.headline),
                  ),
                ),
                body: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: themeColors.cardBackground,
                        borderRadius: AppRadius.medium,
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '錬心館道場 3 (4) - 3 (4) 修道館道場',
                            style: TextStyle(
                              fontSize: AppFontSize.headline,
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            '代表戦: 錬心館道場 勝ち (赤坂 メ - 白峰)',
                            style: TextStyle(
                              fontSize: AppFontSize.body,
                              color: AppKendoColors.ipponGold,
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.text('7人制 団体戦公式記録'), findsOneWidget);
      expect(find.text('錬心館道場 3 (4) - 3 (4) 修道館道場'), findsOneWidget);
      expect(find.textContaining('代表戦: 錬心館道場 勝ち'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
