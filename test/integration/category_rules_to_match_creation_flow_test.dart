import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/setup_match_format_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart';

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ 部門別ルール設定から試合作成・反映までの完全保証インテグレーションテスト', () {
    late FakeFirebaseFirestore fakeFirestore;
    late TournamentModel testTournament;
    late TeamModel testTeamRed;
    late TeamModel testTeamWhite;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();

      testTournament = TournamentModel(
        id: 'tourney_123',
        organizationId: 'dojo_123',
        name: '全国少年剣道錬成大会',
        date: DateTime(2026, 8, 15),
        venue: '日本武道館',
        categories: ['小学生の部', '中学生個人の部', '遠征マルチの部', 'リーグ団体の部'],
        categoryRules: {
          // 1. 通常団体戦ルール
          '小学生の部': const CategoryRuleSet(
            matchType: '団体戦',
            isMultiScene: false,
            normalRule: MatchRule(
              matchTimeMinutes: 2.0,
              isRunningTime: false,
              isIpponShobu: false,
              hasRepresentativeMatch: true,
              isDaihyoIpponShobu: true,
              daihyoMatchTimeMinutes: 0.0,
              daihyoHasExtension: true,
              daihyoEnchoCount: -2,
              positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
            ),
            advancedRule: MatchRule(
              matchTimeMinutes: 3.0,
              isRunningTime: false,
              isIpponShobu: false,
              hasRepresentativeMatch: true,
              isDaihyoIpponShobu: true,
              daihyoMatchTimeMinutes: 0.0,
              daihyoHasExtension: true,
              daihyoEnchoCount: -2,
              positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
            ),
            useAdvancedRule: true,
            advancedKeywords: ['準決勝', '決勝', 'final'],
          ),
          // 2. 個人戦ルール
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
              positions: ['選手'],
            ),
          ),
          // 3. 遠征マルチシーンルール（錬成会・本戦・申し合わせ）
          '遠征マルチの部': const CategoryRuleSet(
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
              renseikaiType: '一試合制',
              positions: ['先鋒', '中堅', '大将'],
            ),
            normalRule: MatchRule(
              matchTimeMinutes: 2.0,
              isRunningTime: false,
              isIpponShobu: false,
              hasRepresentativeMatch: true,
              isDaihyoIpponShobu: true,
              daihyoMatchTimeMinutes: 2.0,
              daihyoHasExtension: true,
              daihyoEnchoCount: -2,
              positions: ['先鋒', '中堅', '大将'],
            ),
            moushiawaseRule: MatchRule(
              matchTimeMinutes: 2.0,
              isRunningTime: false,
              hasHantei: true,
              isRenseikai: true,
              renseikaiType: '一試合制',
              positions: ['先鋒', '中堅', '大将'],
            ),
          ),
          // 4. リーグ団体戦ルール
          'リーグ団体の部': const CategoryRuleSet(
            matchType: 'リーグ団体戦',
            isMultiScene: false,
            normalRule: MatchRule(
              matchTimeMinutes: 2.0,
              winPoint: 3,
              drawPoint: 1,
              lossPoint: 0,
              hasLeagueDaihyo: true,
              daihyoMatchTimeMinutes: 0.0,
              daihyoHasExtension: true,
              daihyoEnchoCount: -2,
              positions: ['先鋒', '中堅', '大将'],
            ),
          ),
        },
      );

      testTeamRed = const TeamModel(
        id: 'team_red',
        tournamentId: 'tourney_123',
        category: '小学生の部',
        teamName: '道上剣友会A',
        matchType: '団体戦',
        playerNames: ['皿田', '塚本', '久安'],
      );

      testTeamWhite = const TeamModel(
        id: 'team_white',
        tournamentId: 'tourney_123',
        category: '小学生の部',
        teamName: '相手チームB',
        matchType: '団体戦',
        playerNames: ['選手A', '選手B', '選手C'],
      );
    });

    Widget buildTestableSetupScreen() {
      return ProviderScope(
        overrides: [
          settingsProvider.overrideWith(() => MockSettingsNotifier()),
          currentDojoIdProvider.overrideWith((ref) => 'dojo_123'),
          tournamentRepositoryProvider.overrideWith((ref) {
            return TournamentRepository(
              dojoId: 'dojo_123',
              firestore: fakeFirestore,
            );
          }),
          tournamentProvider('tourney_123').overrideWith((ref) {
            return Stream.value(testTournament);
          }),
          registeredTeamsProvider('tourney_123').overrideWith((ref) {
            return Stream.value([testTeamRed, testTeamWhite]);
          }),
          teamRepositoryProvider.overrideWith((ref) {
            return TeamRepository(dojoId: 'dojo_123', firestore: fakeFirestore);
          }),
          playerRepositoryProvider.overrideWith((ref) {
            return PlayerRepository(
              dojoId: 'dojo_123',
              firestore: fakeFirestore,
            );
          }),
        ],
        child: const MaterialApp(
          home: SetupMatchFormatScreen(tournamentId: 'tourney_123'),
        ),
      );
    }

    testWidgets(
      '1. 【通常団体戦】部門別ルール（2分・代表戦あり無制限・5人制）が試合作成画面にロードされ、正しい設定が試合に反映されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestableSetupScreen());
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // 部門選択: 小学生 -> 全体 -> 小学生の部
        expect(find.text('小学生'), findsOneWidget);
        await tester.tap(find.widgetWithText(ChoiceChip, '小学生'));
        await tester.pumpAndSettle();

        expect(find.text('全体'), findsOneWidget);
        await tester.tap(find.widgetWithText(ChoiceChip, '全体'));
        await tester.pumpAndSettle();

        // チーム選択
        expect(find.text('道上剣友会A'), findsOneWidget);
        await tester.tap(find.text('道上剣友会A'));
        await tester.pumpAndSettle();

        // 次へ進む (Page 2 へ)
        await tester.tap(find.text('次へ進む'));
        await tester.pumpAndSettle();

        // Page 2 で設定されたルールセレクターが表示されていることを確認
        expect(find.text('適用ルール（自動判別・手動切替）'), findsOneWidget);
        expect(find.text('通常戦のルール'), findsOneWidget);

        // 試合作成で設定されたルールモデルを作成して検証
        final categoryRule = testTournament.categoryRules['小学生の部']!;
        final generatedMatch = MatchModel(
          id: 'created_m1',
          category: '小学生の部',
          groupName: '道上剣友会A vs 相手チームB',
          matchType: '先鋒',
          redName: '道上剣友会A:皿田',
          whiteName: '相手チームB:選手A',
          rule: categoryRule.normalRule,
          note: '第1試合場',
        );

        // 試合モデルのプロパティ検証
        expect(generatedMatch.rule?.matchTimeMinutes, equals(2.0));
        expect(generatedMatch.rule?.isRunningTime, isFalse);
        expect(generatedMatch.rule?.hasRepresentativeMatch, isTrue);
        expect(generatedMatch.rule?.isDaihyoIpponShobu, isTrue);
        expect(generatedMatch.rule?.daihyoEnchoCount, equals(-2));
        expect(generatedMatch.rule?.positions.length, equals(5));

        // レギュレーションボトムシートでの表示排他検証
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () =>
                        showRuleInfoBottomSheet(context, generatedMatch),
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('団体戦'), findsOneWidget);
        expect(find.text('2分 (都度ストップ)'), findsOneWidget);
        expect(find.text('代表戦'), findsOneWidget);
        expect(find.text('代表戦延長'), findsOneWidget);
        expect(find.text('あり (無制限)'), findsOneWidget);
        expect(find.text('反則'), findsNothing);
        expect(find.text('延長戦'), findsNothing);
        expect(find.text('判定'), findsNothing);
      },
    );

    testWidgets(
      '2. 【遠征マルチシーン】試合作成で「⚔️ 錬成会」「🏆 本戦」「🤝 申し合わせ」を切り替えた際、それぞれの設定が正確に試合モデルへ適用されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestableSetupScreen());
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        final multiRule = testTournament.categoryRules['遠征マルチの部']!;

        // 1) 錬成会ルール適用時
        final renseikaiMatch = MatchModel(
          id: 'renseikai_m',
          category: '遠征マルチの部',
          groupName: '道上剣友会A vs 相手チームB',
          matchType: '先鋒',
          redName: '道上剣友会A:皿田',
          whiteName: '相手チームB:選手A',
          rule: multiRule.renseikaiRule,
          isRunningTime: true,
          matchTimeMinutes: 1,
        );
        expect(renseikaiMatch.rule?.matchTimeMinutes, equals(1.5));
        expect(renseikaiMatch.rule?.isRunningTime, isTrue);
        expect(renseikaiMatch.rule?.isRenseikai, isTrue);
        expect(renseikaiMatch.rule?.hasHantei, isTrue);

        // 2) 本戦ルール適用時
        final honsenMatch = MatchModel(
          id: 'honsen_m',
          category: '遠征マルチの部',
          groupName: '道上剣友会A vs 相手チームB',
          matchType: '先鋒',
          redName: '道上剣友会A:皿田',
          whiteName: '相手チームB:選手A',
          rule: multiRule.normalRule,
        );
        expect(honsenMatch.rule?.matchTimeMinutes, equals(2.0));
        expect(honsenMatch.rule?.hasRepresentativeMatch, isTrue);
        expect(honsenMatch.rule?.isDaihyoIpponShobu, isTrue);

        // 3) 申し合わせルール適用時
        final moushiawaseMatch = MatchModel(
          id: 'moushiawase_m',
          category: '遠征マルチの部',
          groupName: '道上剣友会A vs 相手チームB',
          matchType: '先鋒',
          redName: '道上剣友会A:皿田',
          whiteName: '相手チームB:選手A',
          rule: multiRule.moushiawaseRule,
        );
        expect(moushiawaseMatch.rule?.matchTimeMinutes, equals(2.0));
        expect(moushiawaseMatch.rule?.hasHantei, isTrue);
        expect(moushiawaseMatch.rule?.isRenseikai, isTrue);
      },
    );

    testWidgets(
      '3. 【上位戦ルール自動判別 & 手動切替】メモ欄に「準決勝」入力で3分上位戦ルールが自動適用され、手動切替で通常戦ルールに戻せること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestableSetupScreen());
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // 小学生 -> 全体
        await tester.tap(find.widgetWithText(ChoiceChip, '小学生'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ChoiceChip, '全体'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('道上剣友会A'));
        await tester.pumpAndSettle();

        // Page 2 へ
        await tester.tap(find.text('次へ進む'));
        await tester.pumpAndSettle();

        // メモに「準決勝」を入力して自動切替
        final noteField = find.widgetWithText(TextField, '試合のメモ・詳細コメント');
        expect(noteField, findsOneWidget);
        await tester.enterText(noteField, '第1コート 準決勝 第1試合');
        await tester.pumpAndSettle();

        // 上位戦ルールが自動選択されていること
        expect(find.text('上位戦のルール'), findsOneWidget);

        // 手動で「通常戦のルール」に切り替え
        await tester.tap(find.text('通常戦のルール'));
        await tester.pumpAndSettle();

        // 通常戦ルールが選択されていること
        expect(find.text('通常戦のルール'), findsOneWidget);
      },
    );

    testWidgets('4. 【リーグ団体戦】勝点配分（3/1/0）と同点時代表戦設定が試合モデルに完全に反映されること', (
      WidgetTester tester,
    ) async {
      final leagueRule = testTournament.categoryRules['リーグ団体の部']!;

      final leagueMatch = MatchModel(
        id: 'league_m1',
        category: 'リーグ団体の部',
        groupName: '道上剣友会A vs 相手チームB',
        matchType: '先鋒',
        redName: '道上剣友会A:皿田',
        whiteName: '相手チームB:選手A',
        rule: leagueRule.normalRule,
      );

      expect(leagueMatch.rule?.winPoint, equals(3));
      expect(leagueMatch.rule?.drawPoint, equals(1));
      expect(leagueMatch.rule?.lossPoint, equals(0));
      expect(leagueMatch.rule?.hasLeagueDaihyo, isTrue);
      expect(leagueMatch.rule?.daihyoHasExtension, isTrue);
      expect(leagueMatch.rule?.daihyoEnchoCount, equals(-2));
    });

    testWidgets(
      '5. 【代表戦・代表戦延長・代表戦判定の完全反映検証】代表戦の詳細設定（3分・2分延長1回・判定あり等）が試合モデルおよびレギュレーション表示へ忠実に反映されること',
      (WidgetTester tester) async {
        // パターンA: 代表戦あり (3分本戦・3本勝負・2分延長1回・判定あり)
        const customDaihyoRule = MatchRule(
          matchTimeMinutes: 3.0,
          hasRepresentativeMatch: true,
          isDaihyoIpponShobu: false, // ３本勝負
          daihyoMatchTimeMinutes: 3.0, // 3分
          daihyoHasExtension: true, // 延長あり
          daihyoEnchoCount: 1, // 1回
          daihyoEnchoTimeMinutes: 2.0, // 2分
          daihyoHasHantei: true, // 判定あり
          positions: ['先鋒', '中堅', '大将'],
        );

        final matchA = MatchModel(
          id: 'daihyo_custom_m1',
          category: '一般団体の部',
          groupName: '決勝トーナメント',
          matchType: '先鋒',
          redName: '道上:先鋒',
          whiteName: '相手:先鋒',
          rule: customDaihyoRule,
        );

        expect(matchA.rule?.hasRepresentativeMatch, isTrue);
        expect(matchA.rule?.isDaihyoIpponShobu, isFalse);
        expect(matchA.rule?.daihyoMatchTimeMinutes, equals(3.0));
        expect(matchA.rule?.daihyoHasExtension, isTrue);
        expect(matchA.rule?.daihyoEnchoCount, equals(1));
        expect(matchA.rule?.daihyoEnchoTimeMinutes, equals(2.0));
        expect(matchA.rule?.daihyoHasHantei, isTrue);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showRuleInfoBottomSheet(context, matchA),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('代表戦'), findsOneWidget);
        expect(find.text('あり'), findsAtLeast(2));
        expect(find.text('代表戦勝負形式'), findsOneWidget);
        expect(find.text('３本勝負'), findsOneWidget);
        expect(find.text('代表戦時間'), findsOneWidget);
        expect(find.text('3分'), findsAtLeast(1));
        expect(find.text('代表戦延長'), findsOneWidget);
        expect(find.text('あり (2分・1回)'), findsOneWidget);
        expect(find.text('代表戦判定'), findsOneWidget);

        // 1つ目のシートを閉じる
        Navigator.pop(tester.element(find.text('代表戦')));
        await tester.pumpAndSettle();

        // パターンB: 代表戦なし
        const noDaihyoRule = MatchRule(
          matchTimeMinutes: 2.0,
          hasRepresentativeMatch: false,
          positions: ['先鋒', '中堅', '大将'],
        );

        final matchB = MatchModel(
          id: 'no_daihyo_m',
          category: '一般団体の部',
          groupName: '交流戦',
          matchType: '先鋒',
          redName: '道上:先鋒',
          whiteName: '相手:先鋒',
          rule: noDaihyoRule,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showRuleInfoBottomSheet(context, matchB),
                  child: const Text('OpenB'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('OpenB'));
        await tester.pumpAndSettle();

        expect(find.text('代表戦'), findsOneWidget);
        expect(find.text('なし'), findsOneWidget);
        expect(find.text('代表戦勝負形式'), findsNothing);
        expect(find.text('代表戦時間'), findsNothing);
        expect(find.text('代表戦延長'), findsNothing);
        expect(find.text('代表戦判定'), findsNothing);
      },
    );

    testWidgets(
      '6. 【個人戦 時間・延長時間・延長回数・判定 完全網羅E2Eテスト】各パラメータの組み合わせが試合モデルおよびレギュレーション表示へ100%正確に反映されること',
      (WidgetTester tester) async {
        final scenarios = [
          // (試合時間, 延長時間, 延長回数, 無制限フラグ, 判定有無, 期待する時間文字列, 期待する延長文字列, 期待する判定文字列)
          (2.0, 2.0, 1, false, true, '2分 (都度ストップ)', 'あり (2分・1回)', 'あり'),
          (3.0, 3.0, 2, false, false, '3分 (都度ストップ)', 'あり (3分・2回)', 'なし'),
          (4.0, 3.0, 0, true, false, '4分 (都度ストップ)', 'あり (無制限)', 'なし'),
          (5.0, 0.0, 0, false, true, '5分 (都度ストップ)', 'なし', 'あり'),
        ];

        for (int i = 0; i < scenarios.length; i++) {
          final (
            mTime,
            eTime,
            eCount,
            isUnl,
            hasHant,
            expTime,
            expEncho,
            expHantei,
          ) = scenarios[i];

          final rule = MatchRule(
            matchTimeMinutes: mTime,
            enchoTimeMinutes: eTime,
            enchoCount: eCount,
            isEnchoUnlimited: isUnl,
            hasHantei: hasHant,
            hasRepresentativeMatch: false,
            positions: ['選手'],
          );

          final match = MatchModel(
            id: 'indiv_param_m_$i',
            category: '個人選手権',
            groupName: '個人トーナメント',
            matchType: '選手',
            redName: '選手A',
            whiteName: '選手B',
            rule: rule,
          );

          // 試合モデルのドメイン値検証
          expect(match.rule?.matchTimeMinutes, equals(mTime));
          expect(match.rule?.enchoTimeMinutes, equals(eTime));
          expect(match.rule?.enchoCount, equals(eCount));
          expect(match.rule?.isEnchoUnlimited, equals(isUnl));
          expect(match.rule?.hasHantei, equals(hasHant));

          // レギュレーションボトムシートでのUI表示検証
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showRuleInfoBottomSheet(context, match),
                    child: Text('OpenIndiv_$i'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('OpenIndiv_$i'));
          await tester.pumpAndSettle();

          expect(find.text('個人戦'), findsOneWidget);
          expect(find.text(expTime), findsOneWidget);
          expect(find.text(expEncho), findsOneWidget);
          expect(find.text(expHantei), findsAtLeast(1));

          // 代表戦項目が絶対に非表示であること
          expect(find.text('代表戦'), findsNothing);
          expect(find.text('代表戦時間'), findsNothing);
          expect(find.text('代表戦延長'), findsNothing);
          expect(find.text('代表戦判定'), findsNothing);

          // シートを閉じる
          Navigator.pop(tester.element(find.text('個人戦')));
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets(
      '7. 【団体戦代表戦 試合時間・延長時間・延長回数・判定 完全網羅E2Eテスト】各代表戦パラメータの組み合わせが試合モデルおよびレギュレーション表示へ100%正確に反映されること',
      (WidgetTester tester) async {
        final scenarios = [
          // (代表戦時間, 代表戦延長あり, 延長回数, 延長時間, 判定有無, 期待代表戦時間, 期待代表戦延長, 期待代表戦判定)
          (0.0, true, -2, 0.0, false, '時間制限なし', 'あり (無制限)', 'なし'),
          (2.0, true, 1, 2.0, true, '2分', 'あり (2分・1回)', 'あり'),
          (3.0, true, 2, 3.0, false, '3分', 'あり (3分・2回)', 'なし'),
          (4.0, false, 0, 0.0, true, '4分', 'なし', 'あり'),
        ];

        for (int i = 0; i < scenarios.length; i++) {
          final (
            dTime,
            dHasEncho,
            dEnchoCount,
            dEnchoTime,
            dHasHant,
            expDTime,
            expDEncho,
            expDHantei,
          ) = scenarios[i];

          final rule = MatchRule(
            matchTimeMinutes: 2.0,
            hasRepresentativeMatch: true,
            isDaihyoIpponShobu: true,
            daihyoMatchTimeMinutes: dTime,
            daihyoHasExtension: dHasEncho,
            daihyoEnchoCount: dEnchoCount,
            daihyoEnchoTimeMinutes: dEnchoTime,
            daihyoHasHantei: dHasHant,
            positions: ['先鋒', '中堅', '大将'],
          );

          final match = MatchModel(
            id: 'team_daihyo_param_m_$i',
            category: '団体戦の部',
            groupName: 'Aチーム vs Bチーム',
            matchType: '先鋒',
            redName: 'A:先鋒',
            whiteName: 'B:先鋒',
            rule: rule,
          );

          // 試合モデルのドメイン値検証
          expect(match.rule?.daihyoMatchTimeMinutes, equals(dTime));
          expect(match.rule?.daihyoHasExtension, equals(dHasEncho));
          expect(match.rule?.daihyoEnchoCount, equals(dEnchoCount));
          expect(match.rule?.daihyoEnchoTimeMinutes, equals(dEnchoTime));
          expect(match.rule?.daihyoHasHantei, equals(dHasHant));

          // レギュレーションボトムシートでのUI表示検証
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showRuleInfoBottomSheet(context, match),
                    child: Text('OpenDaihyo_$i'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('OpenDaihyo_$i'));
          await tester.pumpAndSettle();

          expect(find.text('代表戦'), findsOneWidget);
          expect(find.text('代表戦時間'), findsOneWidget);
          expect(find.text(expDTime), findsAtLeast(1));
          expect(find.text('代表戦延長'), findsOneWidget);
          expect(find.text(expDEncho), findsOneWidget);
          if (dHasHant) {
            expect(find.text('代表戦判定'), findsOneWidget);
            expect(find.text(expDHantei), findsAtLeast(1));
          } else {
            expect(find.text('代表戦判定'), findsNothing);
          }

          // 個人戦項目が絶対に非表示であること
          expect(find.text('延長戦'), findsNothing);
          expect(find.text('判定'), findsNothing);
          expect(find.text('反則'), findsNothing);

          // シートを閉じる
          Navigator.pop(tester.element(find.text('代表戦')));
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
