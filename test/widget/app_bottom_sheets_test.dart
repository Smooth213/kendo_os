import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_detail_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_representative_modal_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_share_options_bottom_sheet.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ Phase 3: ボトムシート統一ウィジェット テスト', () {
    testWidgets('CategoryRuleDetailBottomSheet がクラッシュせず正常にレンダリングされること', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      CategoryRuleDetailBottomSheet.show(
                        context,
                        categoryName: '小学生の部',
                        ruleSet: const CategoryRuleSet(
                          matchType: '団体戦',
                          normalRule: MatchRule(),
                        ),
                        isDark: false,
                      );
                    },
                    child: const Text('Open Sheet'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('小学生の部 のルール設定'), findsOneWidget);
      expect(find.text('閉じる'), findsOneWidget);
    });

    testWidgets('MatchRepresentativeModalBottomSheet がクラッシュせず正常に描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      MatchRepresentativeModalBottomSheet.show(
                        context,
                        match: const MatchModel(
                          id: 'match_1',
                          tournamentId: 'tour_1',
                          matchType: '団体戦',
                          redName: '赤チーム',
                          whiteName: '白チーム',
                        ),
                        rTeam: '赤チーム',
                        wTeam: '白チーム',
                        redPlayers: ['先鋒 赤', '中堅 赤'],
                        whitePlayers: ['先鋒 白', '中堅 白'],
                      );
                    },
                    child: const Text('Open Modal'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('代表戦の準備'), findsOneWidget);
    });

    testWidgets('MatchShareOptionsBottomSheet がクラッシュせず正常に描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      MatchShareOptionsBottomSheet.show(
                        context,
                        match: const MatchModel(
                          id: 'match_1',
                          tournamentId: 'tour_1',
                          matchType: '団体戦',
                          redName: '赤チーム',
                          whiteName: '白チーム',
                        ),
                      );
                    },
                    child: const Text('Open Share'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Share'));
      await tester.pumpAndSettle();

      expect(find.text('観戦の共有方法を選択'), findsOneWidget);
    });
  });
}
