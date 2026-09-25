import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/widgets/action_buttons.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('📸 【Golden】文字拡大モード（1.5x / 2.0x）視覚的整合性テスト', () {
    testWidgets('1. TextScaler 1.5x 環境下での打突アクションボタン群レイアウト整合性', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: MaterialApp(
              theme: ThemeData.light().copyWith(extensions: [themeColors]),
              home: Scaffold(
                body: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            height: 80,
                            child: HoldConfirmButton(
                              label: 'メ',
                              onConfirm: () {},
                              color: Colors.red,
                              textColor: Colors.white,
                              disabled: false,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            height: 80,
                            child: HoldConfirmButton(
                              label: 'コ',
                              onConfirm: () {},
                              color: Colors.red,
                              textColor: Colors.white,
                              disabled: false,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            height: 80,
                            child: HoldConfirmButton(
                              label: 'ド',
                              onConfirm: () {},
                              color: Colors.grey.shade800,
                              textColor: Colors.white,
                              disabled: false,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            height: 80,
                            child: HoldConfirmButton(
                              label: 'ツ',
                              onConfirm: () {},
                              color: Colors.grey.shade800,
                              textColor: Colors.white,
                              disabled: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HoldConfirmButton), findsNWidgets(4));
    });

    testWidgets('2. TextScaler 2.0x 極大文字環境下でのオーバーフロー耐性検証', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: Scaffold(
                body: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '第68回 全日本剣道選手権大会',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 90,
                              child: HoldConfirmButton(
                                label: 'メ',
                                onConfirm: () {},
                                color: Colors.red,
                                textColor: Colors.white,
                                disabled: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 120,
                              height: 90,
                              child: HoldConfirmButton(
                                label: '反',
                                onConfirm: () {},
                                color: Colors.grey.shade800,
                                textColor: Colors.white,
                                disabled: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('第68回 全日本剣道選手権大会'), findsOneWidget);
    });
  });
}
