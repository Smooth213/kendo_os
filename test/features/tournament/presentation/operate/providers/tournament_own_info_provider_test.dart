import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_save_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_state_holder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_team_and_players_tab.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/tournament_own_info_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_registration_screen.dart'
    show playerListProvider;
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart'
    show registeredTeamsProvider;
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class MockMatchApplicationService extends Mock
    implements MatchApplicationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(<MatchModel>[]);
  });

  group('🥋 大会登録選手に基づく自チーム完全自動認識＆自チーム指定UI テスト要塞', () {
    const ownInfo = TournamentOwnInfo(
      ownTeamNames: {'小畠剣道教室'},
      ownPlayerNames: {'小林 奨', '山田 太郎'},
      playerToTeamMap: {'小林 奨': '小畠剣道教室', '山田 太郎': '小畠剣道教室'},
    );

    test('1. TournamentOwnInfo: 登録選手名から自チーム判定およびチーム名解決が高精度に機能すること', () {
      // 登録選手「小林 奨」は自チーム側
      expect(ownInfo.isOwnSide(teamPart: '', namePart: '小林 奨'), isTrue);
      // 登録チーム「小畠剣道教室」は自チーム側
      expect(ownInfo.isOwnSide(teamPart: '小畠剣道教室', namePart: '誰か'), isTrue);
      // 未登録の「皿田 唯人」は他チーム
      expect(ownInfo.isOwnSide(teamPart: '道上剣友会', namePart: '皿田 唯人'), isFalse);
      // 選手名から所属チームを自動解決
      expect(ownInfo.resolveTeamForPlayer('小林 奨'), '小畠剣道教室');
      expect(ownInfo.resolveTeamForPlayer('皿田 唯人'), isNull);
    });

    test('2. MatchEditStateHolder: 所属が空の場合、自チーム登録選手から所属道場名が自動補完されること', () {
      const match = MatchModel(
        id: 'm-auto-1',
        matchType: '個人戦',
        redName: '小林 奨', // 所属チーム未入力
        whiteName: '道上剣友会: 皿田 唯人',
      );

      final state = MatchEditStateHolder([match], ownInfo: ownInfo);

      // 💡 赤の選手「小林 奨」から自動で「小畠剣道教室」が補完されること
      expect(state.redTeamController.text, '小畠剣道教室');
      expect(state.whiteTeamController.text, '道上剣友会');
      // 赤側が自チームとして自動判定されること
      expect(state.ownTeamChoice, MatchEditOwnTeamChoice.red);
    });

    test('3. MatchEditStateHolder: 白側が自チーム登録選手の場合、自チーム選択が白になること', () {
      const match = MatchModel(
        id: 'm-auto-2',
        matchType: '個人戦',
        redName: '道上剣友会: 皿田 唯人',
        whiteName: '小畠剣道教室: 小林 奨',
      );

      final state = MatchEditStateHolder([match], ownInfo: ownInfo);

      expect(state.ownTeamChoice, MatchEditOwnTeamChoice.white);

      // 入れ替えを実行すると自チーム選択も赤にスワップ追随すること
      state.swapTeamsAndPlayers();
      expect(state.ownTeamChoice, MatchEditOwnTeamChoice.red);
      expect(state.redTeamController.text, '小畠剣道教室');
      expect(state.whiteTeamController.text, '道上剣友会');
    });

    test('4. MatchEditStateHolder: どちらも自チーム登録でない場合、勝手に赤にせず「none（中立）」になること', () {
      const match = MatchModel(
        id: 'm-auto-3',
        matchType: '個人戦',
        redName: '他道場A: 佐藤',
        whiteName: '他道場B: 鈴木',
      );

      final state = MatchEditStateHolder([match], ownInfo: ownInfo);

      // 勝手に赤にならず「none」になる
      expect(state.ownTeamChoice, MatchEditOwnTeamChoice.none);
    });

    Widget buildSaveTestApp({
      required MockMatchApplicationService mockAppService,
      required MatchModel match,
      required MatchEditOwnTeamChoice choice,
      required String buttonText,
    }) {
      return ProviderScope(
        overrides: [
          matchApplicationServiceProvider.overrideWithValue(mockAppService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (rootCtx) => ElevatedButton(
                onPressed: () {
                  Navigator.of(rootCtx).push(
                    MaterialPageRoute(
                      builder: (pageCtx) => Scaffold(
                        body: Consumer(
                          builder: (ctx, ref, _) => ElevatedButton(
                            onPressed: () async {
                              await MatchEditSaveHelper.executeSave(
                                context: ctx,
                                ref: ref,
                                matches: [match],
                                isDantai: false,
                                isSwapped: false,
                                initialOwnIsRed: true,
                                ownTeamChoice: choice,
                                groupInput: '',
                                redTeamInput: '小畠剣道教室',
                                whiteTeamInput: '道上剣友会',
                                courtInput: '',
                                selectedPresetKey: 'honsen',
                                selectedPresetRule: const MatchRule(),
                                matchTime: 3.0,
                                isRunningTime: false,
                                isIpponShobu: false,
                                hasExtension: false,
                                enchoTime: 2.0,
                                enchoCount: 1,
                                isEnchoUnlimited: false,
                                hasHantei: false,
                                hasRepresentativeMatch: false,
                                isDaihyoIpponShobu: false,
                                daihyoMatchTime: 2.0,
                                daihyoHasExtension: false,
                                daihyoEnchoTime: 2.0,
                                daihyoEnchoCount: 1,
                                isDaihyoEnchoUnlimited: false,
                                daihyoHasHantei: false,
                                renseikaiType: '一試合制',
                                overallTimeMinutes: 30,
                                userNote: '',
                                status: 'finished',
                                redPlayerControllers: [
                                  TextEditingController(text: '小林 奨'),
                                ],
                                whitePlayerControllers: [
                                  TextEditingController(text: '皿田 唯人'),
                                ],
                              );
                            },
                            child: Text(buttonText),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('開く'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('5. MatchEditSaveHelper: 自チーム指定「白」の保存が正しく反映されること', (
      tester,
    ) async {
      final mockAppService = MockMatchApplicationService();
      List<MatchModel>? savedMatches;
      when(() => mockAppService.saveMatchesBulk(any())).thenAnswer((inv) async {
        savedMatches = inv.positionalArguments[0] as List<MatchModel>;
      });

      const match = MatchModel(
        id: 'm1',
        matchType: '個人戦',
        redName: '小畠剣道教室: 小林 奨',
        whiteName: '道上剣友会: 皿田 唯人',
        rule: MatchRule(teamName: '小畠剣道教室'),
      );

      await tester.pumpWidget(
        buildSaveTestApp(
          mockAppService: mockAppService,
          match: match,
          choice: MatchEditOwnTeamChoice.white,
          buttonText: '保存実行',
        ),
      );

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存実行'));
      await tester.pumpAndSettle();

      expect(savedMatches, isNotNull);
      expect(savedMatches!.first.rule?.teamName, '道上剣友会');
    });

    testWidgets('6. MatchEditSaveHelper: 自チーム指定「なし（中立）」の保存でteamNameがクリアされること', (
      tester,
    ) async {
      final mockAppService = MockMatchApplicationService();
      List<MatchModel>? savedMatches;
      when(() => mockAppService.saveMatchesBulk(any())).thenAnswer((inv) async {
        savedMatches = inv.positionalArguments[0] as List<MatchModel>;
      });

      const match = MatchModel(
        id: 'm1',
        matchType: '個人戦',
        redName: '小畠剣道教室: 小林 奨',
        whiteName: '道上剣友会: 皿田 唯人',
        rule: MatchRule(teamName: '小畠剣道教室'),
      );

      await tester.pumpWidget(
        buildSaveTestApp(
          mockAppService: mockAppService,
          match: match,
          choice: MatchEditOwnTeamChoice.none,
          buttonText: '中立保存実行',
        ),
      );

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('中立保存実行'));
      await tester.pumpAndSettle();

      expect(savedMatches, isNotNull);
      expect(savedMatches!.first.rule?.teamName, '');
    });

    testWidgets(
      '7. MatchEditTeamAndPlayersTab: 自チーム指定ChoiceChipが表示されタップで切り替わること',
      (tester) async {
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );
        final redTeamCtrl = TextEditingController(text: '小畠剣道教室');
        final whiteTeamCtrl = TextEditingController(text: '道上剣友会');
        final redPlayerCtrls = [TextEditingController(text: '小林 奨')];
        final whitePlayerCtrls = [TextEditingController(text: '皿田 唯人')];

        MatchEditOwnTeamChoice selectedChoice = MatchEditOwnTeamChoice.red;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return MatchEditTeamAndPlayersTab(
                    isDantai: false,
                    redTeamController: redTeamCtrl,
                    whiteTeamController: whiteTeamCtrl,
                    redPlayerControllers: redPlayerCtrls,
                    whitePlayerControllers: whitePlayerCtrls,
                    primaryAccent: AppKendoColors.indigo,
                    isDark: false,
                    textColor: AppKendoColors.pureBlack,
                    ownTeamChoice: selectedChoice,
                    onOwnTeamChoiceChanged: (choice) {
                      setState(() => selectedChoice = choice);
                    },
                    onSwapTeamsAndPlayers: () {},
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('自チーム指定（スコア・勝敗集計の対象）'), findsOneWidget);
        expect(find.text('🔴 赤（小畠剣道教室）'), findsOneWidget);
        expect(find.text('⚪ 白（道上剣友会）'), findsOneWidget);
        expect(find.text('✖ なし（他チーム同士）'), findsOneWidget);

        // 「⚪ 白（道上剣友会）」をタップ
        await tester.tap(find.text('⚪ 白（道上剣友会）'));
        await tester.pumpAndSettle();
        expect(selectedChoice, MatchEditOwnTeamChoice.white);

        // 「✖ なし（他チーム同士）」をタップ
        await tester.tap(find.text('✖ なし（他チーム同士）'));
        await tester.pumpAndSettle();
        expect(selectedChoice, MatchEditOwnTeamChoice.none);
      },
    );

    test(
      '8. tournamentOwnInfoProvider: 合同チームの他道場助っ人選手は自チームから除外され、登録メンバーのみが自チームとなること',
      () async {
        final container = ProviderContainer(
          overrides: [
            registeredTeamsProvider('tour-joint').overrideWith(
              (ref) => Stream.value([
                const TeamModel(
                  id: 'team-joint',
                  tournamentId: 'tour-joint',
                  category: '小学生高学年の部',
                  teamName: '道上剣友会',
                  matchType: '団体戦（5人制）',
                  playerNames: ['皿田 脩人', '久安 智也', '他道場 助っ人'], // 合同チーム（助っ人含む）
                ),
              ]),
            ),
            playerListProvider.overrideWith(
              (ref) => Stream.value([
                PlayerModel(
                  id: 'p1',
                  lastName: '皿田',
                  firstName: '脩人',
                  lastNameKana: 'さらだ',
                  firstNameKana: 'しゅうと',
                  grade: 5,
                ),
                PlayerModel(
                  id: 'p2',
                  lastName: '久安',
                  firstName: '智也',
                  lastNameKana: 'ひさやす',
                  firstNameKana: 'ともや',
                  grade: 6,
                ),
              ]),
            ),
          ],
        );

        // StreamProvider の値を解決
        await container.read(registeredTeamsProvider('tour-joint').future);
        await container.read(playerListProvider.future);

        final ownInfo = container.read(tournamentOwnInfoProvider('tour-joint'));

        // 自道場の正規メンバーは自チーム
        expect(ownInfo.ownPlayerNames.contains('皿田 脩人'), isTrue);
        expect(ownInfo.ownPlayerNames.contains('久安 智也'), isTrue);

        // 合同チームの他道場助っ人は自チームから除外される！
        expect(ownInfo.ownPlayerNames.contains('他道場 助っ人'), isFalse);
        expect(ownInfo.isOwnSide(teamPart: '', namePart: '他道場 助っ人'), isFalse);

        // 個人戦で自道場メンバー vs 他道場助っ人が対戦した場合
        expect(ownInfo.isOwnSide(teamPart: '', namePart: '皿田 脩人'), isTrue);
        expect(ownInfo.isOwnSide(teamPart: '', namePart: '他道場 助っ人'), isFalse);
      },
    );
  });
}
