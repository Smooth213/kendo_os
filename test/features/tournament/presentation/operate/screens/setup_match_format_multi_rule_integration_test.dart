import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/setup_match_format_screen.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

class _MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🥋 同一部門の複数ルール全表示および選択ルールの完全適応保証テスト要塞', () {
    late FakeFirebaseFirestore fakeFirestore;
    late TournamentModel testTournament;
    late TeamModel testTeam;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();

      testTeam = const TeamModel(
        id: 'team_low_elem',
        tournamentId: 'tourney_multi_rule',
        category: '小学生低学年の部',
        teamName: '道上剣友会 低学年チーム',
        matchType: '団体戦',
        playerNames: ['先鋒A', '中堅B', '大将C'],
      );

      testTournament = TournamentModel(
        id: 'tourney_multi_rule',
        organizationId: 'dojo_test',
        name: '第50回記念 春季親善剣道大会',
        date: DateTime(2026, 9, 20),
        venue: '日本武道館',
        categories: ['小学生低学年の部', '小学生低学年の部 (2)', '小学生低学年の部 (3)', '中学生の部'],
        categoryRules: {
          // 1. 予選リーグ用ルール (2分、引き分けあり、勝点3/負点0/分点1)
          '小学生低学年の部': const CategoryRuleSet(
            subtitle: '予選リーグ',
            matchType: '団体戦',
            useHonsenRule: true,
            normalRule: MatchRule(
              matchTimeMinutes: 2.0,
              isRunningTime: false,
              hasHantei: true,
              winPoint: 3.0,
              lossPoint: 0.0,
              drawPoint: 1.0,
            ),
          ),
          // 2. 決勝トーナメント用ルール (3分、上位戦4分・延長無制限)
          '小学生低学年の部 (2)': const CategoryRuleSet(
            subtitle: '決勝トーナメント',
            matchType: '団体戦',
            useHonsenRule: true,
            useAdvancedRule: true,
            normalRule: MatchRule(
              matchTimeMinutes: 3.0,
              isRunningTime: false,
              hasHantei: true,
            ),
            advancedRule: MatchRule(
              matchTimeMinutes: 4.0,
              isRunningTime: false,
              hasHantei: false,
              isEnchoUnlimited: true,
              enchoTimeMinutes: 2.0,
            ),
            advancedKeywords: ['決勝', '準決勝'],
          ),
          // 3. 錬成会用マルチシーンルール (錬成1.5分、本戦2.5分、申合せ1.0分)
          '小学生低学年の部 (3)': const CategoryRuleSet(
            subtitle: '錬成会',
            matchType: '団体戦',
            isMultiScene: true,
            useRenseikaiRule: true,
            useHonsenRule: true,
            useMoushiawaseRule: true,
            renseikaiRule: MatchRule(
              matchTimeMinutes: 1.5,
              isRunningTime: true,
              hasHantei: true,
              isRenseikai: true,
              renseikaiType: '時間制',
            ),
            normalRule: MatchRule(
              matchTimeMinutes: 2.5,
              isRunningTime: false,
              hasHantei: true,
            ),
            moushiawaseRule: MatchRule(
              matchTimeMinutes: 1.0,
              isRunningTime: true,
              hasHantei: false,
              isRenseikai: true,
              renseikaiType: '時間制',
            ),
          ),
          // 4. 別部門ルール（中学生の部: 小学生低学年の部には表示されてはいけない）
          '中学生の部': const CategoryRuleSet(
            subtitle: '中学生本戦',
            matchType: '団体戦',
            useHonsenRule: true,
            normalRule: MatchRule(matchTimeMinutes: 3.0),
          ),
        },
      );
    });

    Widget createTestApp({required ProviderContainer container}) {
      final router = GoRouter(
        initialLocation: '/setup-match-format/tourney_multi_rule',
        routes: [
          GoRoute(
            path: '/setup-match-format/:tournamentId',
            builder: (context, state) => SetupMatchFormatScreen(
              tournamentId: state.pathParameters['tournamentId']!,
            ),
          ),
          GoRoute(
            path: '/order-setup/:tournamentId',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('オーダー設定画面へ遷移成功'))),
          ),
        ],
      );

      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      );
    }

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(() => _MockSettingsNotifier()),
          currentDojoIdProvider.overrideWith((ref) => 'dojo_test'),
          tournamentRepositoryProvider.overrideWith(
            (ref) => TournamentRepository(
              dojoId: 'dojo_test',
              firestore: fakeFirestore,
            ),
          ),
          tournamentProvider(
            'tourney_multi_rule',
          ).overrideWith((ref) => Stream.value(testTournament)),
          registeredTeamsProvider(
            'tourney_multi_rule',
          ).overrideWith((ref) => Stream.value([testTeam])),
          teamRepositoryProvider.overrideWith(
            (ref) =>
                TeamRepository(dojoId: 'dojo_test', firestore: fakeFirestore),
          ),
          playerRepositoryProvider.overrideWith(
            (ref) =>
                PlayerRepository(dojoId: 'dojo_test', firestore: fakeFirestore),
          ),
        ],
      );
    }

    testWidgets('1. 同一部門のすべての登録ルールおよびシーンが漏れなくチップとしてUI上に表示されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = createContainer();
      await tester.pumpWidget(createTestApp(container: container));
      await tester.pumpAndSettle();

      // 部門「小学生」->「低学年」を選択して「小学生低学年の部」にする
      expect(find.text('小学生'), findsOneWidget);
      await tester.tap(find.text('小学生'));
      await tester.pumpAndSettle();

      expect(find.text('低学年 (1-4年)'), findsOneWidget);
      await tester.tap(find.text('低学年 (1-4年)'));
      await tester.pumpAndSettle();

      // チーム選択
      expect(find.text('道上剣友会 低学年チーム'), findsOneWidget);
      await tester.tap(find.text('道上剣友会 低学年チーム'));
      await tester.pumpAndSettle();

      // 次へ進む (Page 2 へ)
      await tester.tap(find.text('次へ進む'));
      await tester.pumpAndSettle();

      // 案内文の検証
      expect(find.text('この部門（小学生低学年の部）に登録されているルールを選択:'), findsOneWidget);

      // 【保証 1】登録されているすべてのルールとシーンのチップが漏れなく表示されていること
      // 1. 予選リーグ (単一シーン通常戦)
      expect(find.text('🏆 予選リーグ'), findsOneWidget);

      // 2. 決勝トーナメント (通常戦 + 上位戦)
      expect(find.text('🏆 決勝トーナメント'), findsOneWidget);
      expect(find.text('⭐ 決勝トーナメント（上位戦）'), findsOneWidget);

      // 3. 錬成会 (マルチシーン: 錬成 + 本戦 + 申合せ)
      expect(find.text('⚔️ 錬成会（錬成）'), findsOneWidget);
      expect(find.text('🏆 錬成会（本戦）'), findsOneWidget);
      expect(find.text('🤝 錬成会（申合せ）'), findsOneWidget);

      // 【保証 2】別部門（中学生の部）のルールチップは混入していないこと
      expect(find.textContaining('中学生'), findsNothing);
    });

    testWidgets('2. チップ選択切り替えにより、試合時間・延長・各設定値および概要カードが即座かつ正しく適応されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = createContainer();
      await tester.pumpWidget(createTestApp(container: container));
      await tester.pumpAndSettle();

      // 部門・チーム選択 -> Page 2 へ
      await tester.tap(find.text('小学生'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('低学年 (1-4年)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('道上剣友会 低学年チーム'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('次へ進む'));
      await tester.pumpAndSettle();

      // --- [状態 1: 初期選択（予選リーグ）の適応確認] ---
      // 概要カードタイトル
      expect(find.textContaining('🏆 通常戦ルール（予選リーグ）'), findsOneWidget);
      // 試合時間は 2分 (通常計測)
      expect(find.textContaining('2分 (通常計測)'), findsOneWidget);

      // --- [状態 2: 「🏆 決勝トーナメント」を選択] ---
      await tester.tap(find.text('🏆 決勝トーナメント'));
      await tester.pumpAndSettle();

      // 概要カードタイトルが決勝トーナメントに即時更新
      expect(find.textContaining('🏆 通常戦ルール（決勝トーナメント）'), findsOneWidget);
      // 試合時間が 3分 (通常計測) に更新
      expect(find.textContaining('3分 (通常計測)'), findsOneWidget);

      // --- [状態 3: 「⭐ 決勝トーナメント（上位戦）」を選択] ---
      await tester.tap(find.text('⭐ 決勝トーナメント（上位戦）'));
      await tester.pumpAndSettle();

      // 概要カードタイトルが上位戦に即時更新
      expect(find.textContaining('⭐ 上位戦ルール（決勝トーナメント）'), findsOneWidget);
      // 試合時間が 4分 (通常計測) に更新
      expect(find.textContaining('4分 (通常計測)'), findsOneWidget);
      // 延長設定が「回数無制限」に更新
      expect(find.textContaining('回数無制限'), findsOneWidget);

      // --- [状態 4: 「⚔️ 錬成会（錬成）」を選択] ---
      await tester.tap(find.text('⚔️ 錬成会（錬成）'));
      await tester.pumpAndSettle();

      // 概要カードタイトルが錬成ルールに即時更新
      expect(find.textContaining('⚔️ 錬成ルール（錬成会）'), findsOneWidget);
      // 試合時間が 1分30秒 に更新
      expect(find.text('1分30秒'), findsOneWidget);
      // 錬成形式バッジの確認
      expect(find.text('時間制'), findsOneWidget);

      // --- [状態 5: 「🤝 錬成会（申合せ）」を選択] ---
      await tester.tap(find.text('🤝 錬成会（申合せ）'));
      await tester.pumpAndSettle();

      // 概要カードタイトルが申合せルールに即時更新
      expect(find.textContaining('🤝 申合せルール（錬成会）'), findsOneWidget);
      // 試合時間が 1分 に更新
      expect(find.text('1分'), findsOneWidget);
    });

    testWidgets('3. 選択したルールの設定が試合作成（MatchRuleProvider / 次のフロー）へ完全に適応・保存されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = createContainer();
      await tester.pumpWidget(createTestApp(container: container));
      await tester.pumpAndSettle();

      // 部門・チーム選択 -> Page 2 へ
      await tester.tap(find.text('小学生'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('低学年 (1-4年)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('道上剣友会 低学年チーム'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('次へ進む'));
      await tester.pumpAndSettle();

      // 「⭐ 決勝トーナメント（上位戦）」を選択
      await tester.tap(find.text('⭐ 決勝トーナメント（上位戦）'));
      await tester.pumpAndSettle();

      // 「このルールで枠を作成」ボタンをタップして確定
      expect(find.text('このルールで枠を作成'), findsOneWidget);
      await tester.tap(find.text('このルールで枠を作成'));
      await tester.pumpAndSettle();

      // オーダー設定画面への遷移成功を確認
      expect(find.text('オーダー設定画面へ遷移成功'), findsOneWidget);

      // 【保証 3】プロバイダ（matchRuleProvider）に保存された MatchRule の完全適応検証
      final savedRule = container.read(matchRuleProvider);
      expect(savedRule, isNotNull);
      expect(savedRule.matchTimeMinutes, 4.0);
      expect(savedRule.isEnchoUnlimited, isTrue);
      expect(savedRule.enchoTimeMinutes, 2.0);
      expect(savedRule.hasHantei, isFalse);
    });

    testWidgets('4. 選択された「予選リーグ」ルールが正しく MatchRuleProvider へ保存されること（対比検証）', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = createContainer();
      await tester.pumpWidget(createTestApp(container: container));
      await tester.pumpAndSettle();

      // 部門・チーム選択 -> Page 2 へ
      await tester.tap(find.text('小学生'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('低学年 (1-4年)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('道上剣友会 低学年チーム'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('次へ進む'));
      await tester.pumpAndSettle();

      // 初期状態で「予選リーグ」が選択されている状態で完了
      expect(find.text('このルールで枠を作成'), findsOneWidget);
      await tester.tap(find.text('このルールで枠を作成'));
      await tester.pumpAndSettle();

      expect(find.text('オーダー設定画面へ遷移成功'), findsOneWidget);

      final savedRule = container.read(matchRuleProvider);
      expect(savedRule, isNotNull);
      expect(savedRule.matchTimeMinutes, 2.0);
      expect(savedRule.winPoint, 3.0);
      expect(savedRule.lossPoint, 0.0);
      expect(savedRule.drawPoint, 1.0);
      expect(savedRule.hasHantei, isTrue);
    });
  });
}
