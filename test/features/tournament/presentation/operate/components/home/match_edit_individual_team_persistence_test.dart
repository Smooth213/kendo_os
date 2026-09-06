import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_save_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_state_holder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_team_and_players_tab.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class MockMatchApplicationService extends Mock
    implements MatchApplicationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(<MatchModel>[]);
  });

  group('🥋 個人戦 試合コメント編集時における所属チーム保持テスト要塞', () {
    late MockMatchApplicationService mockMatchAppService;

    setUp(() {
      mockMatchAppService = MockMatchApplicationService();
      when(
        () => mockMatchAppService.saveMatchesBulk(any()),
      ).thenAnswer((_) async {});
    });

    test('1. MatchEditStateHolder: 個人戦で所属がある場合、所属名と選手名が正しく分離抽出されること', () {
      const matchWithAffiliation = MatchModel(
        id: 'm-ind-1',
        matchType: '個人戦',
        redName: '小林道場: 小林 奨',
        whiteName: '皿田倶楽部: 皿田 唯人',
        groupName: '第1試合場, 33試合目',
        note: '第1試合場, 33試合目\n公式戦コメント',
      );

      final state = MatchEditStateHolder([matchWithAffiliation]);

      expect(state.isDantai, isFalse);
      expect(state.redTeamController.text, '小林道場');
      expect(state.whiteTeamController.text, '皿田倶楽部');
      expect(state.redPlayerControllers.first.text, '小林 奨');
      expect(state.whitePlayerControllers.first.text, '皿田 唯人');
      expect(state.noteController.text, '公式戦コメント');
      expect(state.courtController.text, '第1試合場, 33試合目');
    });

    test('2. MatchEditStateHolder: 個人戦で所属がない場合、空文字のまま保持され赤チーム等のダミーが入らないこと', () {
      const matchWithoutAffiliation = MatchModel(
        id: 'm-ind-2',
        matchType: '個人戦',
        redName: '小林 奨',
        whiteName: '皿田 唯人',
        note: '個人エントリーのメモ',
      );

      final state = MatchEditStateHolder([matchWithoutAffiliation]);

      expect(state.isDantai, isFalse);
      expect(state.redTeamController.text, '');
      expect(state.whiteTeamController.text, '');
      expect(state.redPlayerControllers.first.text, '小林 奨');
      expect(state.whitePlayerControllers.first.text, '皿田 唯人');
    });

    testWidgets('3. MatchEditSaveHelper: 個人戦のコメント編集保存後も所属チームが消失せず保持されること', (
      tester,
    ) async {
      const originalMatch = MatchModel(
        id: 'm-ind-3',
        matchType: '個人戦',
        redName: '小林道場: 小林 奨',
        whiteName: '皿田倶楽部: 皿田 唯人',
        groupName: '第1試合場, 33試合目',
        note: '第1試合場, 33試合目\n元のコメント',
      );

      final state = MatchEditStateHolder([originalMatch]);

      List<MatchModel>? savedMatches;
      when(() => mockMatchAppService.saveMatchesBulk(any())).thenAnswer((
        invocation,
      ) async {
        savedMatches = invocation.positionalArguments[0] as List<MatchModel>;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchApplicationServiceProvider.overrideWithValue(
              mockMatchAppService,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Consumer(
                    builder: (ctx, ref, _) {
                      return ElevatedButton(
                        onPressed: () async {
                          await MatchEditSaveHelper.executeSave(
                            context: ctx,
                            ref: ref,
                            matches: [originalMatch],
                            isDantai: state.isDantai,
                            isSwapped: state.isSwapped,
                            initialOwnIsRed: state.initialOwnIsRed,
                            groupInput: state.groupNameController.text,
                            redTeamInput: state.redTeamController.text,
                            whiteTeamInput: state.whiteTeamController.text,
                            courtInput: state.courtController.text,
                            selectedPresetKey: state.selectedPresetKey,
                            selectedPresetRule: state.selectedPresetRule,
                            matchTime: state.matchTime,
                            isRunningTime: state.isRunningTime,
                            isIpponShobu: state.isIpponShobu,
                            hasExtension: state.hasExtension,
                            enchoTime: state.enchoTime,
                            enchoCount: state.enchoCount,
                            isEnchoUnlimited: state.isEnchoUnlimited,
                            hasHantei: state.hasHantei,
                            hasRepresentativeMatch:
                                state.hasRepresentativeMatch,
                            isDaihyoIpponShobu: state.isDaihyoIpponShobu,
                            daihyoMatchTime: state.daihyoMatchTime,
                            daihyoHasExtension: state.daihyoHasExtension,
                            daihyoEnchoTime: state.daihyoEnchoTime,
                            daihyoEnchoCount: state.daihyoEnchoCount,
                            isDaihyoEnchoUnlimited:
                                state.isDaihyoEnchoUnlimited,
                            daihyoHasHantei: state.daihyoHasHantei,
                            renseikaiType: state.renseikaiType,
                            overallTimeMinutes: 30,
                            userNote: '編集された新しい詳細コメント',
                            status: state.status,
                            redPlayerControllers: state.redPlayerControllers,
                            whitePlayerControllers:
                                state.whitePlayerControllers,
                          );
                        },
                        child: const Text('保存実行'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('保存実行'));
      await tester.pumpAndSettle();

      expect(savedMatches, isNotNull);
      expect(savedMatches!.length, 1);

      final resultMatch = savedMatches!.first;
      // 🎯 最重要検証: 個人戦であっても所属チームがコロン付きで完全に残っていること！
      expect(resultMatch.redName, '小林道場: 小林 奨');
      expect(resultMatch.whiteName, '皿田倶楽部: 皿田 唯人');
      expect(resultMatch.groupName, '第1試合場, 33試合目');
      expect(resultMatch.note, contains('編集された新しい詳細コメント'));
    });

    testWidgets('4. MatchEditSaveHelper: 個人エントリー（所属なし）保存時は不要なコロンが付かないこと', (
      tester,
    ) async {
      const originalMatch = MatchModel(
        id: 'm-ind-4',
        matchType: '個人戦',
        redName: '小林 奨',
        whiteName: '皿田 唯人',
        note: 'メモ',
      );

      final state = MatchEditStateHolder([originalMatch]);

      List<MatchModel>? savedMatches;
      when(() => mockMatchAppService.saveMatchesBulk(any())).thenAnswer((
        invocation,
      ) async {
        savedMatches = invocation.positionalArguments[0] as List<MatchModel>;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchApplicationServiceProvider.overrideWithValue(
              mockMatchAppService,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Consumer(
                    builder: (ctx, ref, _) {
                      return ElevatedButton(
                        onPressed: () async {
                          await MatchEditSaveHelper.executeSave(
                            context: ctx,
                            ref: ref,
                            matches: [originalMatch],
                            isDantai: state.isDantai,
                            isSwapped: state.isSwapped,
                            initialOwnIsRed: state.initialOwnIsRed,
                            groupInput: state.groupNameController.text,
                            redTeamInput: state.redTeamController.text,
                            whiteTeamInput: state.whiteTeamController.text,
                            courtInput: state.courtController.text,
                            selectedPresetKey: state.selectedPresetKey,
                            selectedPresetRule: state.selectedPresetRule,
                            matchTime: state.matchTime,
                            isRunningTime: state.isRunningTime,
                            isIpponShobu: state.isIpponShobu,
                            hasExtension: state.hasExtension,
                            enchoTime: state.enchoTime,
                            enchoCount: state.enchoCount,
                            isEnchoUnlimited: state.isEnchoUnlimited,
                            hasHantei: state.hasHantei,
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
                            userNote: '更新コメント',
                            status: state.status,
                            redPlayerControllers: state.redPlayerControllers,
                            whitePlayerControllers:
                                state.whitePlayerControllers,
                          );
                        },
                        child: const Text('保存'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      final resultMatch = savedMatches!.first;
      expect(resultMatch.redName, '小林 奨');
      expect(resultMatch.whiteName, '皿田 唯人');
    });

    testWidgets('5. MatchEditTeamAndPlayersTab: 個人戦時に所属・道場名ラベルが表示されること', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final redTeamCtrl = TextEditingController(text: '小林道場');
      final whiteTeamCtrl = TextEditingController(text: '皿田倶楽部');
      final redPlayerCtrls = [TextEditingController(text: '小林 奨')];
      final whitePlayerCtrls = [TextEditingController(text: '皿田 唯人')];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: MatchEditTeamAndPlayersTab(
              isDantai: false,
              redTeamController: redTeamCtrl,
              whiteTeamController: whiteTeamCtrl,
              redPlayerControllers: redPlayerCtrls,
              whitePlayerControllers: whitePlayerCtrls,
              primaryAccent: AppKendoColors.indigo,
              isDark: false,
              textColor: AppKendoColors.pureBlack,
              onSwapTeamsAndPlayers: () {},
            ),
          ),
        ),
      );

      expect(find.text('👤 対戦者情報'), findsOneWidget);
      expect(find.text('赤（RED）所属・道場名'), findsOneWidget);
      expect(find.text('白（WHITE）所属・道場名'), findsOneWidget);
      expect(find.text('小林道場'), findsOneWidget);
      expect(find.text('皿田倶楽部'), findsOneWidget);
      expect(find.text('小林 奨'), findsOneWidget);
      expect(find.text('皿田 唯人'), findsOneWidget);
    });
  });
}
