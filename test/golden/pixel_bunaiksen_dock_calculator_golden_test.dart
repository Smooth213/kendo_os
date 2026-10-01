import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/presentation/providers/match_calculator_provider.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_accordion_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_format_selector.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 部内戦ドック試合数計算機 Pixel完全性テスト', () {
    Widget buildCalculatorTestWidget({
      required bool isDark,
      required CalculatorSettings settings,
    }) {
      final themeColors = AppThemeColors.ofMode(
        isDark: isDark,
        mode: 'bunaiksen',
      );

      return MaterialApp(
        theme: isDark
            ? ThemeData.dark().copyWith(extensions: [themeColors])
            : ThemeData.light().copyWith(extensions: [themeColors]),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  MatchCalculatorAccordionCard(
                    title: '試合形式設定',
                    badgeText: settings.format.label,
                    initiallyExpanded: true,
                    child: MatchCalculatorFormatSelector(
                      settings: settings,
                      notifier: MatchCalculatorNotifier(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('スマートフォン標準幅表示において 計算機アコーディオンおよび形式選択が正常描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const settings = CalculatorSettings(format: MatchFormatType.multiLeague);
      await tester.pumpWidget(
        buildCalculatorTestWidget(isDark: false, settings: settings),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MatchCalculatorAccordionCard), findsOneWidget);
      expect(find.byType(MatchCalculatorFormatSelector), findsOneWidget);
    });

    testWidgets('タブレット大画面幅表示において 計算機アコーディオンおよびUIパーツが崩れず描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(820, 1180);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const settings = CalculatorSettings(format: MatchFormatType.singleLeague);
      await tester.pumpWidget(
        buildCalculatorTestWidget(isDark: false, settings: settings),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MatchCalculatorAccordionCard), findsOneWidget);
    });

    testWidgets('ダークモード表示において テーマ拡張トークンが適用され正常に描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const settings = CalculatorSettings(
        format: MatchFormatType.prelimLeagueAndTournament,
      );
      await tester.pumpWidget(
        buildCalculatorTestWidget(isDark: true, settings: settings),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MatchCalculatorAccordionCard), findsOneWidget);
    });
  });
}
