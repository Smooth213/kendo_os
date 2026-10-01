import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_kachinuki_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] 勝ち抜き戦公式記録カードの視認性テスト', () {
    final kachinukiMatches = [
      MatchModel(
        id: 'kachinuki_m1',
        matchType: '勝ち抜き戦',
        redName: '宇品体協剣道部: 沖野',
        whiteName: '道上剣友会B: 選手A',
        status: 'finished',
        redScore: 2,
        whiteScore: 0,
        redRemaining: ['沖野', '大川'],
        whiteRemaining: ['選手B'],
      ),
    ];

    testWidgets('ライトモード時にスコアカードの背景が白系(cardBackground)でありtextColor(黒)でないこと', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              brightness: Brightness.light,
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return OfficialRecordKachinukiCard(
                    matches: kachinukiMatches,
                    isDark: false,
                    ref: ref,
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Card の背景色を検証
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);
      expect(
        cardWidget.color,
        equals(
          AppThemeColors.ofMode(isDark: false, mode: 'normal').cardBackground,
        ),
      );

      // スコア領域のContainerの背景色を検証 (textColorではなくcardBackground)
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Container),
        ),
      );
      expect(containers.isNotEmpty, isTrue);
      expect(
        containers.first.color,
        isNot(
          equals(
            AppThemeColors.ofMode(isDark: false, mode: 'normal').textColor,
          ),
        ),
      );
      expect(
        containers.first.color,
        equals(
          AppThemeColors.ofMode(isDark: false, mode: 'normal').cardBackground,
        ),
      );
    });

    testWidgets('ダークモード時にスコアカードの背景がダーク系色となること', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              brightness: Brightness.dark,
              extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
            ),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return OfficialRecordKachinukiCard(
                    matches: kachinukiMatches,
                    isDark: true,
                    ref: ref,
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);
      expect(
        cardWidget.color,
        equals(
          AppThemeColors.ofMode(isDark: true, mode: 'normal').cardBackground,
        ),
      );

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Container),
        ),
      );
      expect(containers.isNotEmpty, isTrue);
      expect(
        containers.first.color,
        equals(
          AppThemeColors.ofMode(isDark: true, mode: 'normal').cardBackground,
        ),
      );
    });
  });
}
