import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

void main() {
  group('[Golden] CSV一括取込バリデーションエラー行ハイライトダイアログ ピクセル検証テスト', () {
    testWidgets('CSV取込エラー行（行番号・エラー理由・入力値）ハイライト表示のピクセルレイアウトが検証されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      final sampleErrors = [
        {'line': 4, 'field': '選手名', 'value': '', 'reason': '選手名が未入力です'},
        {
          'line': 12,
          'field': '段位',
          'value': '十段',
          'reason': '有効な段位（初段〜八段）を入力してください',
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: Center(
              child: AppDialog(
                title: 'CSV取り込みエラー',
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '以下の行に不整合または不正なデータが検出されました：',
                      style: TextStyle(fontWeight: AppFontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...sampleErrors.map((err) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppKendoColors.red.withValues(alpha: 0.1),
                          borderRadius: AppRadius.small,
                          border: Border.all(
                            color: AppKendoColors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '行 ${err['line']}: ',
                              style: const TextStyle(
                                fontWeight: AppFontWeight.bold,
                                color: AppKendoColors.red,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${err['field']} 「${err['value']}」 - ${err['reason']}',
                                style: const TextStyle(
                                  fontSize: AppFontSize.small,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () {}, child: const Text('閉じる')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AppDialog), findsOneWidget);
      expect(find.text('CSV取り込みエラー'), findsOneWidget);
      expect(find.textContaining('行 4:'), findsOneWidget);
      expect(find.textContaining('行 12:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
