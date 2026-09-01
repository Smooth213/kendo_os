import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/category_rules_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/setup_match_format_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  group('CategoryRules & SetupMatchFormat Integration Widget Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late TournamentModel testTournament;
    late TeamModel testTeam;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();

      testTournament = TournamentModel(
        id: 'test_tournament',
        organizationId: 'test_dojo_id',
        name: '千葉テスト大会',
        date: DateTime(2026, 7, 25),
        venue: 'テスト体育館',
        categories: ['小学生の部'],
        categoryRules: {
          '小学生の部': CategoryRuleSet(
            normalRule: const MatchRule(matchTimeMinutes: 2.0, hasHantei: true),
            advancedRule: const MatchRule(
              matchTimeMinutes: 3.0,
              isEnchoUnlimited: true,
            ),
            useAdvancedRule: true,
          ),
        },
      );

      testTeam = const TeamModel(
        id: 'team_1',
        tournamentId: 'test_tournament',
        category: '小学生の部',
        teamName: '千代田チーム',
        matchType: '個人戦',
        playerNames: ['山田'],
      );
    });

    testWidgets('1. CategoryRulesScreen list and edit rules flow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
            tournamentRepositoryProvider.overrideWith((ref) {
              return TournamentRepository(
                dojoId: 'test_dojo_id',
                firestore: fakeFirestore,
              );
            }),
            tournamentProvider('test_tournament').overrideWith((ref) {
              return Stream.value(testTournament);
            }),
            matchListByTournamentProvider('test_tournament').overrideWith((
              ref,
            ) {
              return Stream.value([]);
            }),
          ],
          child: const MaterialApp(
            home: CategoryRulesScreen(tournamentId: 'test_tournament'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Check category card is rendered
      expect(find.text('小学生の部'), findsAtLeast(1));
      expect(find.text('🥋 個人戦'), findsWidgets);
      expect(find.text('⏱️ 2分'), findsWidgets);

      // Swipe left on the card to reveal edit action
      await tester.drag(
        find.byKey(const ValueKey('slidable_rule_小学生の部')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('編集'));
      await tester.pumpAndSettle();

      // Inside rule editor
      expect(find.text('準決勝・決勝は別ルールにする'), findsOneWidget);
      expect(find.text('通常戦のルール'), findsOneWidget);
      expect(find.text('上位戦（準決勝・決勝）'), findsOneWidget);

      // Tap "通常戦のルール" to verify editing page
      expect(find.text('試合時間'), findsOneWidget);
      expect(find.text('2分'), findsAtLeast(1));

      // Verify Match Format dynamic form visibility
      expect(find.text('試合方式'), findsOneWidget);
      // "代表戦あり（団体戦用）" is hidden for Individual matches by default
      expect(find.text('代表戦あり（団体戦用）'), findsNothing);

      // Change Match Format to Team Match
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('団体戦 (トーナメント)').last);
      await tester.pumpAndSettle();

      // Representative Match setting should now be visible!
      expect(find.text('代表戦あり（団体戦用）'), findsOneWidget);
    });

    testWidgets(
      '2. SetupMatchFormatScreen dynamic category rules load and auto/manual round toggle',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(() => MockSettingsNotifier()),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
              tournamentRepositoryProvider.overrideWith((ref) {
                return TournamentRepository(
                  dojoId: 'test_dojo_id',
                  firestore: fakeFirestore,
                );
              }),
              tournamentProvider('test_tournament').overrideWith((ref) {
                return Stream.value(testTournament);
              }),
              registeredTeamsProvider('test_tournament').overrideWith((ref) {
                return Stream.value([testTeam]);
              }),
              teamRepositoryProvider.overrideWith((ref) {
                return TeamRepository(
                  dojoId: 'test_dojo_id',
                  firestore: fakeFirestore,
                );
              }),
              playerRepositoryProvider.overrideWith((ref) {
                return PlayerRepository(
                  dojoId: 'test_dojo_id',
                  firestore: fakeFirestore,
                );
              }),
            ],
            child: const MaterialApp(
              home: SetupMatchFormatScreen(tournamentId: 'test_tournament'),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Page 1: Select "小学生" (Major) + "全体" (Minor) -> "小学生の部"
        expect(find.text('小学生'), findsOneWidget);
        await tester.tap(
          find.widgetWithText(ChoiceChip, '小学生'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(find.text('全体'), findsOneWidget);
        await tester.tap(
          find.widgetWithText(ChoiceChip, '全体'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Select "千代田チーム"
        expect(find.text('千代田チーム'), findsOneWidget);
        await tester.tap(find.text('千代田チーム'));
        await tester.pumpAndSettle();

        // Tap Next to go to Page 2 (Summary & Details Page)
        await tester.tap(find.text('次へ進む'));
        await tester.pumpAndSettle();

        // Enter "準決勝" in the note field to trigger auto advanced rules toggle
        final noteField = find.widgetWithText(TextField, '試合のメモ・詳細コメント');
        expect(noteField, findsOneWidget);
        await tester.enterText(noteField, 'Aコート 準決勝 第1試合');
        await tester.pumpAndSettle();

        // Verify rule switcher toggle appeared and "上位戦のルール" is selected
        expect(find.text('適用ルール（自動判別・手動切替）'), findsOneWidget);
        expect(find.text('上位戦のルール'), findsOneWidget);

        // Tap "通常戦のルール" to manually override
        await tester.tap(find.text('通常戦のルール'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets('3. CategoryRulesScreen detailed rule sheet popup on tap', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
            tournamentRepositoryProvider.overrideWith((ref) {
              return TournamentRepository(
                dojoId: 'test_dojo_id',
                firestore: fakeFirestore,
              );
            }),
            tournamentProvider('test_tournament').overrideWith((ref) {
              return Stream.value(testTournament);
            }),
            matchListByTournamentProvider('test_tournament').overrideWith((
              ref,
            ) {
              return Stream.value([]);
            }),
          ],
          child: const MaterialApp(
            home: CategoryRulesScreen(tournamentId: 'test_tournament'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Check category card is rendered
      expect(find.text('小学生の部'), findsAtLeast(1));

      // Tap on the category card
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('slidable_rule_小学生の部')),
          matching: find.text('小学生の部'),
        ),
      );
      await tester.pumpAndSettle();

      // Bottom sheet should open with detailed rules
      expect(find.text('小学生の部 のルール設定'), findsOneWidget);
      expect(find.text('通常戦ルール'), findsOneWidget);
      expect(find.text('上位戦（準決勝・決勝等）ルール'), findsOneWidget);
      expect(find.text('上位戦 適用ワード'), findsOneWidget);

      // We should see a close button
      expect(find.text('閉じる'), findsOneWidget);
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();

      // Bottom sheet should be closed
      expect(find.text('小学生の部 のルール設定'), findsNothing);
    });

    testWidgets(
      '4. 【マルチシーン選択ルール回帰防止テスト】チェックを入れていないルールシーン（錬成会OFF、本戦ON、申し合わせON）は一覧カードに表示されず、選択されたルールのみが表示されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 錬成会OFF, 本戦ON, 申し合わせON のマルチシーントーナメント
        final multiSceneTournament = TournamentModel(
          id: 'multi_scene_tourney',
          organizationId: 'test_dojo_id',
          name: '遠征大会',
          date: DateTime(2026, 8, 15),
          venue: '武道館',
          categories: ['小学生の部'],
          categoryRules: {
            '小学生の部': const CategoryRuleSet(
              matchType: '団体戦',
              isMultiScene: true,
              useRenseikaiRule: false, // ★ チェックOFF
              useHonsenRule: true, // ★ チェックON
              useMoushiawaseRule: true, // ★ チェックON
              renseikaiRule: MatchRule(
                matchTimeMinutes: 1.5,
                isRunningTime: true,
                hasHantei: true,
                isRenseikai: true,
              ),
              normalRule: MatchRule(
                matchTimeMinutes: 2.0,
                hasRepresentativeMatch: true,
                daihyoHasExtension: true,
              ),
              moushiawaseRule: MatchRule(
                matchTimeMinutes: 2.0,
                hasHantei: true,
                isRenseikai: true,
              ),
            ),
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(() => MockSettingsNotifier()),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
              tournamentRepositoryProvider.overrideWith((ref) {
                return TournamentRepository(
                  dojoId: 'test_dojo_id',
                  firestore: fakeFirestore,
                );
              }),
              tournamentProvider('multi_scene_tourney').overrideWith((ref) {
                return Stream.value(multiSceneTournament);
              }),
              matchListByTournamentProvider('multi_scene_tourney').overrideWith(
                (ref) {
                  return Stream.value([]);
                },
              ),
            ],
            child: const MaterialApp(
              home: CategoryRulesScreen(tournamentId: 'multi_scene_tourney'),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // 小学生の部が表示されていること
        expect(find.text('小学生の部'), findsAtLeast(1));

        // ★ チェックを入れた「本戦」「申合せ」チップは表示されること
        expect(find.text('🏆 本戦'), findsOneWidget);
        expect(find.text('🤝 申合せ'), findsOneWidget);

        // ★ チェックを外した「錬成」チップは絶対に表示されないこと
        expect(find.text('⚔️ 錬成'), findsNothing);
      },
    );

    testWidgets(
      '5. 【部門ルール詳細ボトムシート排他検証テスト】団体戦部門タップ時のボトムシートにおいて「反則」「延長戦」「判定」が表示されず、設定された団体戦ルールのみが表示されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final teamTournament = TournamentModel(
          id: 'team_tourney',
          organizationId: 'test_dojo_id',
          name: '団体戦大会',
          date: DateTime(2026, 8, 15),
          venue: '武道館',
          categories: ['小学生の部'],
          categoryRules: {
            '小学生の部': const CategoryRuleSet(
              matchType: '団体戦',
              isMultiScene: false,
              normalRule: MatchRule(
                matchTimeMinutes: 2.0,
                isRunningTime: false,
                isIpponShobu: false,
                hasRepresentativeMatch: true,
                isDaihyoIpponShobu: true,
                daihyoMatchTimeMinutes: 2.0,
                daihyoHasExtension: true,
                daihyoEnchoCount: -2,
                daihyoHasHantei: false,
              ),
              useAdvancedRule: false,
            ),
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(() => MockSettingsNotifier()),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
              tournamentRepositoryProvider.overrideWith((ref) {
                return TournamentRepository(
                  dojoId: 'test_dojo_id',
                  firestore: fakeFirestore,
                );
              }),
              tournamentProvider('team_tourney').overrideWith((ref) {
                return Stream.value(teamTournament);
              }),
              matchListByTournamentProvider('team_tourney').overrideWith((ref) {
                return Stream.value([]);
              }),
            ],
            child: const MaterialApp(
              home: CategoryRulesScreen(tournamentId: 'team_tourney'),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // 小学生の部カードをタップして詳細ボトムシートを開く
        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('slidable_rule_小学生の部')),
            matching: find.text('小学生の部'),
          ),
        );
        await tester.pumpAndSettle();

        // ボトムシートが開いていること
        expect(find.text('小学生の部 のルール設定'), findsOneWidget);
        expect(find.text('通常戦ルール'), findsOneWidget);

        // 表示されるべき正しい項目
        expect(find.text('団体戦'), findsOneWidget);
        expect(find.text('2分 (都度ストップ)'), findsOneWidget);
        expect(find.text('３本勝負 (２本先取)'), findsOneWidget);
        expect(find.text('団体戦・チーム設定'), findsOneWidget);
        expect(find.text('あり'), findsOneWidget);
        expect(find.text('代表戦勝負形式'), findsOneWidget);
        expect(find.text('１本勝負'), findsOneWidget);
        expect(find.text('代表戦時間'), findsOneWidget);
        expect(find.text('2分'), findsAtLeast(1));
        expect(find.text('代表戦延長'), findsOneWidget);
        expect(find.text('あり (無制限)'), findsOneWidget);

        // ★ ユーザー指摘の「反則」「延長戦」「判定」が表示されないこと
        expect(find.text('反則'), findsNothing);
        expect(find.text('延長戦'), findsNothing);
        expect(find.text('判定'), findsNothing);
      },
    );

    testWidgets(
      '6. 【部門ルール詳細ボトムシート排他検証テスト】個人戦部門タップ時のボトムシートにおいて「延長戦」「判定」が表示され、「反則」「代表戦」が表示されないこと',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final indTournament = TournamentModel(
          id: 'ind_tourney',
          organizationId: 'test_dojo_id',
          name: '個人戦大会',
          date: DateTime(2026, 8, 15),
          venue: '武道館',
          categories: ['中学生個人の部'],
          categoryRules: {
            '中学生個人の部': const CategoryRuleSet(
              matchType: '個人戦',
              isMultiScene: false,
              normalRule: MatchRule(
                matchTimeMinutes: 3.0,
                isRunningTime: false,
                isIpponShobu: false,
                enchoCount: 1,
                enchoTimeMinutes: 2.0,
                hasHantei: true,
              ),
              useAdvancedRule: false,
            ),
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(() => MockSettingsNotifier()),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
              tournamentRepositoryProvider.overrideWith((ref) {
                return TournamentRepository(
                  dojoId: 'test_dojo_id',
                  firestore: fakeFirestore,
                );
              }),
              tournamentProvider('ind_tourney').overrideWith((ref) {
                return Stream.value(indTournament);
              }),
              matchListByTournamentProvider('ind_tourney').overrideWith((ref) {
                return Stream.value([]);
              }),
            ],
            child: const MaterialApp(
              home: CategoryRulesScreen(tournamentId: 'ind_tourney'),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // 中学生個人の部カードをタップ
        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('slidable_rule_中学生個人の部')),
            matching: find.text('中学生個人の部'),
          ),
        );
        await tester.pumpAndSettle();

        // 個人戦の設定が表示されること
        expect(find.text('中学生個人の部 のルール設定'), findsOneWidget);
        expect(find.text('個人戦'), findsOneWidget);
        expect(find.text('3分 (都度ストップ)'), findsOneWidget);
        expect(find.text('３本勝負 (２本先取)'), findsOneWidget);
        expect(find.text('延長戦'), findsOneWidget);
        expect(find.text('あり (2分・1回)'), findsOneWidget);
        expect(find.text('判定'), findsOneWidget);
        expect(find.text('あり'), findsOneWidget);

        // 代表戦や反則が表示されないこと
        expect(find.text('代表戦'), findsNothing);
        expect(find.text('代表戦時間'), findsNothing);
        expect(find.text('団体戦・チーム設定'), findsNothing);
        expect(find.text('反則'), findsNothing);
      },
    );

    testWidgets(
      '7. 【部門ルール詳細ボトムシート排他検証テスト】勝ち抜き戦部門タップ時のボトムシートにおいて「勝ち抜き戦設定」「無制限条件」が表示され、「反則」「代表戦」「延長戦」「判定」が表示されないこと',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final kachinukiTournament = TournamentModel(
          id: 'kachinuki_tourney',
          organizationId: 'test_dojo_id',
          name: '勝ち抜き大会',
          date: DateTime(2026, 8, 15),
          venue: '武道館',
          categories: ['高校生の部'],
          categoryRules: {
            '高校生の部': const CategoryRuleSet(
              matchType: '勝ち抜き戦',
              isMultiScene: false,
              normalRule: MatchRule(
                matchTimeMinutes: 4.0,
                isRunningTime: false,
                isIpponShobu: false,
                kachinukiUnlimitedType: '大将対大将',
              ),
              useAdvancedRule: false,
            ),
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(() => MockSettingsNotifier()),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
              tournamentRepositoryProvider.overrideWith((ref) {
                return TournamentRepository(
                  dojoId: 'test_dojo_id',
                  firestore: fakeFirestore,
                );
              }),
              tournamentProvider('kachinuki_tourney').overrideWith((ref) {
                return Stream.value(kachinukiTournament);
              }),
              matchListByTournamentProvider('kachinuki_tourney').overrideWith((
                ref,
              ) {
                return Stream.value([]);
              }),
            ],
            child: const MaterialApp(
              home: CategoryRulesScreen(tournamentId: 'kachinuki_tourney'),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('slidable_rule_高校生の部')),
            matching: find.text('高校生の部'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('高校生の部 のルール設定'), findsOneWidget);
        expect(find.text('勝ち抜き戦'), findsOneWidget);
        expect(find.text('4分 (都度ストップ)'), findsOneWidget);
        expect(find.text('勝ち抜き戦設定'), findsOneWidget);
        expect(find.text('無制限条件'), findsOneWidget);
        expect(find.text('大将対大将'), findsOneWidget);

        // 排他チェック
        expect(find.text('代表戦'), findsNothing);
        expect(find.text('代表戦時間'), findsNothing);
        expect(find.text('延長戦'), findsNothing);
        expect(find.text('判定'), findsNothing);
        expect(find.text('反則'), findsNothing);
      },
    );

    testWidgets(
      '8. 【部門ルール詳細ボトムシート排他検証テスト】錬成会部門タップ時のボトムシートにおいて「錬成会」「進行方式」が表示され、「勝負形式」「反則」「代表戦」「延長戦」「判定」が表示されないこと',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final renseikaiTournament = TournamentModel(
          id: 'renseikai_tourney',
          organizationId: 'test_dojo_id',
          name: '錬成大会',
          date: DateTime(2026, 8, 15),
          venue: '武道館',
          categories: ['合同錬成の部'],
          categoryRules: {
            '合同錬成の部': const CategoryRuleSet(
              matchType: '錬成会',
              isMultiScene: false,
              normalRule: MatchRule(
                matchTimeMinutes: 2.0,
                isRunningTime: true,
                isRenseikai: true,
                renseikaiType: '時間制',
                overallTimeMinutes: 15,
              ),
              useAdvancedRule: false,
            ),
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(() => MockSettingsNotifier()),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
              tournamentRepositoryProvider.overrideWith((ref) {
                return TournamentRepository(
                  dojoId: 'test_dojo_id',
                  firestore: fakeFirestore,
                );
              }),
              tournamentProvider('renseikai_tourney').overrideWith((ref) {
                return Stream.value(renseikaiTournament);
              }),
              matchListByTournamentProvider('renseikai_tourney').overrideWith((
                ref,
              ) {
                return Stream.value([]);
              }),
            ],
            child: const MaterialApp(
              home: CategoryRulesScreen(tournamentId: 'renseikai_tourney'),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('slidable_rule_合同錬成の部')),
            matching: find.text('合同錬成の部'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('合同錬成の部 のルール設定'), findsOneWidget);
        expect(find.text('錬成会'), findsOneWidget);
        expect(find.text('錬成会設定'), findsOneWidget);
        expect(find.text('進行方式'), findsOneWidget);
        expect(find.text('時間制'), findsOneWidget);
        expect(find.text('制限時間'), findsOneWidget);
        expect(find.text('15分'), findsOneWidget);

        // 排他チェック
        expect(find.text('勝負形式'), findsNothing);
        expect(find.text('反則'), findsNothing);
        expect(find.text('代表戦'), findsNothing);
        expect(find.text('延長戦'), findsNothing);
        expect(find.text('判定'), findsNothing);
      },
    );

    testWidgets(
      '9. 【マルチシーンボトムシート排他検証テスト】チェックを外したシーン（錬成会OFF）はボトムシート内にセクションが表示されず、チェックONの「本戦」「申し合わせ」のみが表示されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final multiSceneTournament = TournamentModel(
          id: 'multi_sheet_tourney',
          organizationId: 'test_dojo_id',
          name: '遠征大会',
          date: DateTime(2026, 8, 15),
          venue: '武道館',
          categories: ['選抜小学生の部'],
          categoryRules: {
            '選抜小学生の部': const CategoryRuleSet(
              matchType: '団体戦',
              isMultiScene: true,
              useRenseikaiRule: false, // ★ チェックOFF
              useHonsenRule: true, // ★ チェックON
              useMoushiawaseRule: true, // ★ チェックON
              renseikaiRule: MatchRule(
                matchTimeMinutes: 1.5,
                isRunningTime: true,
                hasHantei: true,
                isRenseikai: true,
              ),
              normalRule: MatchRule(
                matchTimeMinutes: 2.0,
                hasRepresentativeMatch: true,
                daihyoHasExtension: true,
              ),
              moushiawaseRule: MatchRule(
                matchTimeMinutes: 2.0,
                hasHantei: true,
                isRenseikai: true,
              ),
            ),
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(() => MockSettingsNotifier()),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
              tournamentRepositoryProvider.overrideWith((ref) {
                return TournamentRepository(
                  dojoId: 'test_dojo_id',
                  firestore: fakeFirestore,
                );
              }),
              tournamentProvider('multi_sheet_tourney').overrideWith((ref) {
                return Stream.value(multiSceneTournament);
              }),
              matchListByTournamentProvider('multi_sheet_tourney').overrideWith(
                (ref) {
                  return Stream.value([]);
                },
              ),
            ],
            child: const MaterialApp(
              home: CategoryRulesScreen(tournamentId: 'multi_sheet_tourney'),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('slidable_rule_選抜小学生の部')),
            matching: find.text('選抜小学生の部'),
          ),
        );
        await tester.pumpAndSettle();

        // ★ チェックを入れた「本戦」「申合せ」セクションは表示されること
        expect(find.text('🏆 本戦ルール'), findsOneWidget);
        expect(find.text('🤝 申合せルール'), findsOneWidget);

        // ★ チェックを外した「錬成ルール」セクションは絶対に表示されないこと
        expect(find.text('⚔️ 錬成ルール'), findsNothing);
      },
    );
  });
}
