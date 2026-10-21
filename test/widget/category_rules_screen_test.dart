import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/category_rules_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeTournamentRepository extends TournamentRepository {
  FakeTournamentRepository()
    : super(dojoId: 'org1', firestore: FakeFirebaseFirestore());

  @override
  Future<void> updateTournament(TournamentModel tournament) async {}
}

void main() {
  group('[Widget] CategoryRulesScreen UI統合テスト要塞', () {
    testWidgets('同一カテゴリ（例: 小学生の部）で団体戦と個人戦の2つのルールが共存表示されること', (tester) async {
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
            tournamentRepositoryProvider.overrideWithValue(
              FakeTournamentRepository(),
            ),
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
      expect(find.text('試合ルール設定'), findsOneWidget);

      // 3つのルールカードがすべて独立して描画されていること（プリセットチップ等と合わせて確認）
      expect(find.text('小学生の部'), findsWidgets);
      expect(find.text('小学生の部（個人戦）'), findsOneWidget);
      expect(find.text('中学生の部'), findsWidgets);

      // 種別バッジ（個人戦 / 団体戦）の表示確認
      expect(find.text('🥋 個人戦'), findsOneWidget);
      expect(find.text('👥 団体戦'), findsNWidgets(2));
    });

    testWidgets('新規部門名を入力して追加ボタンを押すと、編集画面（ルールの編集）に遷移すること', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final tournament = TournamentModel(
        id: 't_add_test',
        organizationId: 'org1',
        name: 'テスト大会',
        date: DateTime(2026, 8, 28),
        venue: '武道館',
        categoryRules: {},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentRepositoryProvider.overrideWithValue(
              FakeTournamentRepository(),
            ),
            tournamentProvider.overrideWith(
              (ref, id) => Stream.value(tournament),
            ),
            matchListByTournamentProvider.overrideWith(
              (ref, id) => Stream.value([]),
            ),
          ],
          child: const MaterialApp(
            home: CategoryRulesScreen(tournamentId: 't_add_test'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 部門名入力欄に「高校生の部」を入力
      await tester.enterText(find.byType(TextField).first, '高校生の部');
      await tester.pump();

      // 追加ボタン（＋アイコン）をタップ
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // ルールの編集画面に遷移し、タイトルが「ルールの編集」になること
      expect(find.text('ルールの編集'), findsOneWidget);
    });

    testWidgets('定番の部門ショートカットチップをタップすると、新規ルールが作成されて編集画面へ遷移すること', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final tournament = TournamentModel(
        id: 't_preset_test',
        organizationId: 'org1',
        name: 'テスト大会',
        date: DateTime(2026, 8, 28),
        venue: '武道館',
        categoryRules: {},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentRepositoryProvider.overrideWithValue(
              FakeTournamentRepository(),
            ),
            tournamentProvider.overrideWith(
              (ref, id) => Stream.value(tournament),
            ),
            matchListByTournamentProvider.overrideWith(
              (ref, id) => Stream.value([]),
            ),
          ],
          child: const MaterialApp(
            home: CategoryRulesScreen(tournamentId: 't_preset_test'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 定番部門チップ「小学生の部」をタップ
      await tester.tap(find.text('小学生の部').first);
      await tester.pumpAndSettle();

      // ルールの編集画面に遷移すること
      expect(find.text('ルールの編集'), findsOneWidget);
    });

    testWidgets('ルールカードをタップするとルール詳細ボトムシートが表示されること', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final tournament = TournamentModel(
        id: 't_detail_test',
        organizationId: 'org1',
        name: 'テスト大会',
        date: DateTime(2026, 8, 28),
        venue: '武道館',
        categoryRules: {
          '中学生の部': const CategoryRuleSet(
            normalRule: MatchRule(matchTimeMinutes: 3.0, hasHantei: true),
            matchType: '個人戦',
          ),
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentRepositoryProvider.overrideWithValue(
              FakeTournamentRepository(),
            ),
            tournamentProvider.overrideWith(
              (ref, id) => Stream.value(tournament),
            ),
            matchListByTournamentProvider.overrideWith(
              (ref, id) => Stream.value([]),
            ),
          ],
          child: const MaterialApp(
            home: CategoryRulesScreen(tournamentId: 't_detail_test'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 中学生の部カードをタップ
      await tester.tap(find.text('中学生の部').last);
      await tester.pumpAndSettle();

      // 詳細ボトムシートが表示されること
      expect(find.text('中学生の部 のルール設定'), findsOneWidget);
      expect(find.text('通常戦ルール'), findsOneWidget);
      expect(find.text('3分 (都度ストップ)'), findsOneWidget);
    });

    testWidgets('ルールの編集画面で試合方式に剣道形を選択した際、形試合用ルール（時間計測なし・旗判定）が適応されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final tournament = TournamentModel(
        id: 't_kata_edit_test',
        organizationId: 'org1',
        name: 'テスト大会',
        date: DateTime(2026, 8, 28),
        venue: '武道館',
        categoryRules: {
          '形の部': const CategoryRuleSet(
            normalRule: MatchRule(matchTimeMinutes: 3.0),
            matchType: '個人戦',
          ),
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentRepositoryProvider.overrideWithValue(
              FakeTournamentRepository(),
            ),
            tournamentProvider.overrideWith(
              (ref, id) => Stream.value(tournament),
            ),
            matchListByTournamentProvider.overrideWith(
              (ref, id) => Stream.value([]),
            ),
          ],
          child: const MaterialApp(
            home: CategoryRulesScreen(tournamentId: 't_kata_edit_test'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 部門名入力欄に「テスト部門」を入力
      await tester.enterText(find.byType(TextField).first, 'テスト部門');
      await tester.pump();

      // 追加ボタン（＋アイコン）をタップして編集画面へ
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('ルールの編集'), findsOneWidget);
      expect(find.text('試合時間'), findsOneWidget); // 通常試合なので試合時間設定が表示されている

      // 試合方式のドロップダウンから「剣道形」を選択
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('剣道形').last);
      await tester.pumpAndSettle();

      // 剣道形用のルールが適用され、試合時間設定が消え、形用案内が表示されること
      expect(find.text('試合時間'), findsNothing);
      expect(
        find.textContaining('3名の審判による旗判定または不戦勝によって勝敗を決定します'),
        findsOneWidget,
      );
    });
  });
}
