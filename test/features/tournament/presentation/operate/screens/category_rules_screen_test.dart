import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/category_rules_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('🥋 CategoryRulesScreen UI統合テスト要塞', () {
    testWidgets('1. 同一カテゴリ（例: 小学生の部）で団体戦と個人戦の2つのルールが共存表示されること', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final tournament = TournamentModel(
        id: 't_multi_rules',
        organizationId: 'org1',
        name: 'テスト大会',
        date: DateTime(2026, 8, 28),
        venue: '武道館',
        categoryRules: {
          '小学生の部': const CategoryRuleSet(
            normalRule: MatchRule(matchTimeMinutes: 3.0),
            matchType: '団体戦',
          ),
          '小学生の部（個人戦）': const CategoryRuleSet(
            normalRule: MatchRule(matchTimeMinutes: 2.0),
            matchType: '個人戦',
          ),
          '中学生の部': const CategoryRuleSet(
            normalRule: MatchRule(matchTimeMinutes: 3.0),
            matchType: '団体戦',
          ),
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentProvider.overrideWith(
              (ref, id) => Stream.value(tournament),
            ),
            matchListByTournamentProvider.overrideWith(
              (ref, id) => Stream.value([]),
            ),
          ],
          child: const MaterialApp(
            home: CategoryRulesScreen(tournamentId: 't_multi_rules'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ヘッダー確認
      expect(find.text('部門別ルール設定'), findsOneWidget);

      // 3つのルールカードがすべて独立して描画されていること（プリセットチップ等と合わせて確認）
      expect(find.text('小学生の部'), findsWidgets);
      expect(find.text('小学生の部（個人戦）'), findsOneWidget);
      expect(find.text('中学生の部'), findsWidgets);

      // 種別バッジ（個人戦 / 団体戦）の表示確認
      expect(find.text('🥋 個人戦'), findsOneWidget);
      expect(find.text('👥 団体戦'), findsNWidgets(2));
    });
  });
}
