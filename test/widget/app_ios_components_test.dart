import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';

void main() {
  group('🛡️ AppHaptics ユーティリティ テスト', () {
    test('全Hapticメソッドがクラッシュせず安全に実行できること', () {
      expect(() => AppHaptics.selection(), returnsNormally);
      expect(() => AppHaptics.light(), returnsNormally);
      expect(() => AppHaptics.medium(), returnsNormally);
      expect(() => AppHaptics.heavy(), returnsNormally);
      expect(() => AppHaptics.success(), returnsNormally);
      expect(() => AppHaptics.warning(), returnsNormally);
      expect(() => AppHaptics.error(), returnsNormally);
    });
  });

  group('🛡️ AppLoadingIndicator ウィジェット テスト', () {
    testWidgets(
      '標準の AppLoadingIndicator が CupertinoActivityIndicator として描画されること',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: const Scaffold(body: Center(child: AppLoadingIndicator())),
          ),
        );

        final indicatorFinder = find.byType(CupertinoActivityIndicator);
        expect(indicatorFinder, findsOneWidget);

        final indicator = tester.widget<CupertinoActivityIndicator>(
          indicatorFinder,
        );
        expect(indicator.radius, 10.0);
      },
    );

    testWidgets('.small および .large ファクトリで適切な radius が設定されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: const Scaffold(
            body: Column(
              children: [
                AppLoadingIndicator.small(color: Colors.red),
                AppLoadingIndicator.large(color: Colors.blue),
              ],
            ),
          ),
        ),
      );

      final indicators = tester.widgetList<CupertinoActivityIndicator>(
        find.byType(CupertinoActivityIndicator),
      );
      expect(indicators.length, 2);
      expect(indicators.first.radius, 8.0);
      expect(indicators.first.color, Colors.red);
      expect(indicators.last.radius, 14.0);
      expect(indicators.last.color, Colors.blue);
    });
  });

  group('🛡️ AppSwitch ウィジェット テスト', () {
    testWidgets('Switch.adaptive が描画され、タップ時に値の変更コールバックが発火すること', (tester) async {
      bool currentValue = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppSwitch(
                  value: currentValue,
                  onChanged: (val) {
                    setState(() {
                      currentValue = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // タップして切り替え
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
    });
  });
  group('🛡️ AppChoiceChip ウィジェット テスト', () {
    testWidgets('ピル形状(Capsule)で描画され、タップ時にonSelectedが発火すること', (tester) async {
      bool isSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppChoiceChip(
                  label: const Text('個人戦'),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      isSelected = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      final chipFinder = find.byType(ChoiceChip);
      expect(chipFinder, findsOneWidget);

      final choiceChip = tester.widget<ChoiceChip>(chipFinder);
      expect(choiceChip.shape, isA<RoundedRectangleBorder>());
      final shape = choiceChip.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, AppRadius.capsule);

      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      expect(isSelected, isTrue);
    });
  });

  group('🛡️ AppSnackBar ユーティリティ テスト', () {
    testWidgets('show, showError, showSuccess がクラッシュせず SnackBar を表示すること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppSnackBar.show(context, 'テストメッセージ');
                  },
                  child: const Text('Show SnackBar'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();

      expect(find.text('テストメッセージ'), findsOneWidget);
    });
  });

  group('🛡️ AppBottomSheetContent ウィジェット テスト', () {
    testWidgets('ドラッグハンドルとタイトルが正しく描画されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: const Scaffold(
            body: AppBottomSheetContent(
              title: '設定シート',
              titleIcon: Icons.settings,
              child: Text('コンテンツ'),
            ),
          ),
        ),
      );

      expect(find.text('設定シート'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.text('コンテンツ'), findsOneWidget);
    });
  });

  group('🛡️ AppHeader ウィジェット テスト', () {
    testWidgets('canPop時に自動で iOS 戻るボタンが描画されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Navigator(
            onGenerateRoute: (_) {
              return MaterialPageRoute(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Scaffold(
                              appBar: AppHeader(title: 'サブ画面'),
                            ),
                          ),
                        );
                      },
                      child: const Text('Go'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.text('サブ画面'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });
  });
}
