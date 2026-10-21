import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/match_domain_service.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_save_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_state_holder.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class MockMatchApplicationService extends Mock
    implements MatchApplicationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(<MatchModel>[]);
  });

  group('[Widget] 勝ち抜き戦 選手オーダー編集・複数試合連動更新テスト', () {
    late MockMatchApplicationService mockMatchAppService;

    setUp(() {
      mockMatchAppService = MockMatchApplicationService();
      when(
        () => mockMatchAppService.saveMatchesBulk(any()),
      ).thenAnswer((_) async {});
    });

    test('MatchEditStateHolder: 待機中の1試合のみでも先鋒〜大将の5人オーダーが正しく復元されること', () {
      const kachinukiMatch = MatchModel(
        id: 'k-1',
        isKachinuki: true,
        matchType: '先鋒',
        status: 'waiting',
        redName: '道上剣友会A : 山田',
        whiteName: '五剣会八幡支部A : 佐藤',
        redRemaining: [
          '道上剣友会A : 鈴木',
          '道上剣友会A : 田中',
          '道上剣友会A : 高橋',
          '道上剣友会A : 渡辺',
        ],
        whiteRemaining: [
          '五剣会八幡支部A : 伊藤',
          '五剣会八幡支部A : 中村',
          '五剣会八幡支部A : 小林',
          '五剣会八幡支部A : 加藤',
        ],
        rule: MatchRule(
          isKachinuki: true,
          positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
        ),
      );

      final state = MatchEditStateHolder([kachinukiMatch]);

      expect(state.isKachinuki, isTrue);
      expect(state.isDantai, isTrue);
      expect(state.redTeamController.text, '道上剣友会A');
      expect(state.whiteTeamController.text, '五剣会八幡支部A');

      // 5人全員分のコントローラーが初期化されていること
      expect(state.redPlayerControllers.length, 5);
      expect(state.whitePlayerControllers.length, 5);

      expect(state.redPlayerControllers[0].text, '山田');
      expect(state.redPlayerControllers[1].text, '鈴木');
      expect(state.redPlayerControllers[2].text, '田中');
      expect(state.redPlayerControllers[3].text, '高橋');
      expect(state.redPlayerControllers[4].text, '渡辺');

      expect(state.whitePlayerControllers[0].text, '佐藤');
      expect(state.whitePlayerControllers[1].text, '伊藤');
      expect(state.whitePlayerControllers[2].text, '中村');
      expect(state.whitePlayerControllers[3].text, '小林');
      expect(state.whitePlayerControllers[4].text, '加藤');

      expect(state.positionLabels, ['先鋒', '次鋒', '中堅', '副将', '大将']);
    });

    testWidgets(
      'MatchEditSaveHelper: 待機中の勝ち抜き戦で全員の名前を変更して保存した際、先鋒および待機リストが正しく更新されること',
      (tester) async {
        const kachinukiMatch = MatchModel(
          id: 'k-1',
          isKachinuki: true,
          matchType: '先鋒',
          status: 'waiting',
          redName: '道上剣友会A : 山田',
          whiteName: '五剣会八幡支部A : 佐藤',
          redRemaining: ['道上剣友会A : 鈴木', '道上剣友会A : 田中'],
          whiteRemaining: ['五剣会八幡支部A : 伊藤', '五剣会八幡支部A : 中村'],
          rule: MatchRule(isKachinuki: true, positions: ['先鋒', '中堅', '大将']),
        );

        final state = MatchEditStateHolder([kachinukiMatch]);

        // 先鋒と大将の名前を変更
        state.redPlayerControllers[0].text = '木村';
        state.redPlayerControllers[2].text = '松本';

        state.whitePlayerControllers[0].text = '斎藤';
        state.whitePlayerControllers[1].text = '清水';

        List<MatchModel>? savedMatches;
        when(() => mockMatchAppService.saveMatchesBulk(any())).thenAnswer((
          invocation,
        ) async {
          savedMatches =
              invocation.positionalArguments.first as List<MatchModel>;
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              matchApplicationServiceProvider.overrideWithValue(
                mockMatchAppService,
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(
                extensions: [
                  AppThemeColors.ofMode(isDark: false, mode: 'operate'),
                ],
              ),
              home: Consumer(
                builder: (context, ref, child) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        MatchEditSaveHelper.executeSave(
                          context: context,
                          ref: ref,
                          matches: [kachinukiMatch],
                          isDantai: state.isDantai,
                          isSwapped: state.isSwapped,
                          initialOwnIsRed: state.initialOwnIsRed,
                          ownTeamChoice: state.ownTeamChoice,
                          groupInput: '',
                          redTeamInput: state.redTeamController.text.trim(),
                          whiteTeamInput: state.whiteTeamController.text.trim(),
                          courtInput: '',
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
                          hasRepresentativeMatch: state.hasRepresentativeMatch,
                          isDaihyoIpponShobu: state.isDaihyoIpponShobu,
                          daihyoMatchTime: state.daihyoMatchTime,
                          daihyoHasExtension: state.daihyoHasExtension,
                          daihyoEnchoTime: state.daihyoEnchoTime,
                          daihyoEnchoCount: state.daihyoEnchoCount,
                          isDaihyoEnchoUnlimited: state.isDaihyoEnchoUnlimited,
                          daihyoHasHantei: state.daihyoHasHantei,
                          renseikaiType: state.renseikaiType,
                          overallTimeMinutes: 30,
                          isKachinuki: state.isKachinuki,
                          kachinukiUnlimitedType: state.kachinukiUnlimitedType,
                          isLeague: state.isLeague,
                          winPoint: state.winPoint,
                          lossPoint: state.lossPoint,
                          drawPoint: state.drawPoint,
                          userNote: '',
                          status: state.status,
                          redPlayerControllers: state.redPlayerControllers,
                          whitePlayerControllers: state.whitePlayerControllers,
                          initialRedPlayers: state.initialRedPlayers,
                          initialWhitePlayers: state.initialWhitePlayers,
                        );
                      },
                      child: const Text('Save'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(savedMatches, isNotNull);
        expect(savedMatches!.length, 1);

        final updated = savedMatches!.first;
        // 先鋒が木村に更新されていること
        expect(updated.redName, '道上剣友会A: 木村');
        // 待機リストの中堅(鈴木)と大将(松本)が正しく更新されていること
        expect(updated.redRemaining, ['道上剣友会A: 鈴木', '道上剣友会A: 松本']);

        // 白側も確認
        expect(updated.whiteName, '五剣会八幡支部A: 斎藤');
        expect(updated.whiteRemaining, ['五剣会八幡支部A: 清水', '五剣会八幡支部A: 中村']);
      },
    );

    testWidgets('進行中の勝ち抜き戦で先鋒が勝ち抜いて2試合に登場している場合、先鋒の名前変更が2対戦とも自動連動して更新されること', (
      tester,
    ) async {
      // 第1試合: 山田 (勝ち) vs 佐藤 (負け) -> 終了
      const match1 = MatchModel(
        id: 'k-1',
        isKachinuki: true,
        matchType: '先鋒',
        status: 'finished',
        order: 1.0,
        redName: '道上剣友会A : 山田',
        whiteName: '五剣会八幡支部A : 佐藤',
        redScore: 2,
        whiteScore: 0,
        redRemaining: ['道上剣友会A : 鈴木', '道上剣友会A : 田中'],
        whiteRemaining: ['五剣会八幡支部A : 伊藤', '五剣会八幡支部A : 中村'],
        rule: MatchRule(isKachinuki: true, positions: ['先鋒', '中堅', '大将']),
      );

      // 第2試合: 山田 (勝ち残り) vs 伊藤 (次鋒登場) -> 進行中
      const match2 = MatchModel(
        id: 'k-2',
        isKachinuki: true,
        matchType: '勝ち抜き戦',
        status: 'in_progress',
        order: 1.1,
        redName: '道上剣友会A : 山田',
        whiteName: '五剣会八幡支部A : 伊藤',
        redRemaining: ['道上剣友会A : 鈴木', '道上剣友会A : 田中'],
        whiteRemaining: ['五剣会八幡支部A : 中村'],
        rule: MatchRule(isKachinuki: true, positions: ['先鋒', '中堅', '大将']),
      );

      final state = MatchEditStateHolder([match1, match2]);

      // 第1試合から先鋒〜大将の3名が復元されていること
      expect(state.redPlayerControllers.length, 3);
      expect(state.redPlayerControllers[0].text, '山田');

      // ユーザーが先鋒「山田」を「エース木村」に変更
      state.redPlayerControllers[0].text = 'エース木村';

      List<MatchModel>? savedMatches;
      when(() => mockMatchAppService.saveMatchesBulk(any())).thenAnswer((
        invocation,
      ) async {
        savedMatches = invocation.positionalArguments.first as List<MatchModel>;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchApplicationServiceProvider.overrideWithValue(
              mockMatchAppService,
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'operate'),
              ],
            ),
            home: Consumer(
              builder: (context, ref, child) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      MatchEditSaveHelper.executeSave(
                        context: context,
                        ref: ref,
                        matches: [match1, match2],
                        isDantai: state.isDantai,
                        isSwapped: state.isSwapped,
                        initialOwnIsRed: state.initialOwnIsRed,
                        ownTeamChoice: state.ownTeamChoice,
                        groupInput: '',
                        redTeamInput: state.redTeamController.text.trim(),
                        whiteTeamInput: state.whiteTeamController.text.trim(),
                        courtInput: '',
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
                        hasRepresentativeMatch: state.hasRepresentativeMatch,
                        isDaihyoIpponShobu: state.isDaihyoIpponShobu,
                        daihyoMatchTime: state.daihyoMatchTime,
                        daihyoHasExtension: state.daihyoHasExtension,
                        daihyoEnchoTime: state.daihyoEnchoTime,
                        daihyoEnchoCount: state.daihyoEnchoCount,
                        isDaihyoEnchoUnlimited: state.isDaihyoEnchoUnlimited,
                        daihyoHasHantei: state.daihyoHasHantei,
                        renseikaiType: state.renseikaiType,
                        overallTimeMinutes: 30,
                        isKachinuki: state.isKachinuki,
                        kachinukiUnlimitedType: state.kachinukiUnlimitedType,
                        isLeague: state.isLeague,
                        winPoint: state.winPoint,
                        lossPoint: state.lossPoint,
                        drawPoint: state.drawPoint,
                        userNote: '',
                        status: state.status,
                        redPlayerControllers: state.redPlayerControllers,
                        whitePlayerControllers: state.whitePlayerControllers,
                        initialRedPlayers: state.initialRedPlayers,
                        initialWhitePlayers: state.initialWhitePlayers,
                      );
                    },
                    child: const Text('Save'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedMatches, isNotNull);
      expect(savedMatches!.length, 2);

      // 第1試合（終了済）の赤選手名が「エース木村」に更新されていること
      expect(savedMatches![0].redName, '道上剣友会A: エース木村');
      expect(savedMatches![0].status, 'finished'); // ステータスが保持されていること

      // 第2試合（進行中）の赤選手名も連動して「エース木村」に自動更新されていること！
      expect(savedMatches![1].redName, '道上剣友会A: エース木村');
      expect(savedMatches![1].status, 'in_progress'); // ステータスが保持されていること
    });

    testWidgets(
      '勝ち抜き戦フルライフサイクル保証テスト: 待機中に編集したオーダーで試合が開始・進行し、勝ち抜いた選手の勝ち残りおよび敗者の次選手登場が完璧に機能すること',
      (tester) async {
        // 1. 初期状態: 待機中の第1試合
        const initialMatch = MatchModel(
          id: 'k-start-1',
          isKachinuki: true,
          matchType: '先鋒',
          status: 'waiting',
          order: 1.0,
          redName: '旧赤道場 : 旧先鋒',
          whiteName: '旧白道場 : 旧先鋒',
          redRemaining: ['旧赤道場 : 旧中堅', '旧赤道場 : 旧大将'],
          whiteRemaining: ['旧白道場 : 旧中堅', '旧白道場 : 旧大将'],
          rule: MatchRule(isKachinuki: true, positions: ['先鋒', '中堅', '大将']),
        );

        // 2. 編集シートを開いてオーダーとチーム名を全面的に変更
        final state = MatchEditStateHolder([initialMatch]);
        state.redTeamController.text = '新赤道場';
        state.whiteTeamController.text = '新白道場';

        state.redPlayerControllers[0].text = '新赤先鋒';
        state.redPlayerControllers[1].text = '新赤中堅';
        state.redPlayerControllers[2].text = '新赤大将';

        state.whitePlayerControllers[0].text = '新白先鋒';
        state.whitePlayerControllers[1].text = '新白中堅';
        state.whitePlayerControllers[2].text = '新白大将';

        List<MatchModel>? savedMatches;
        when(() => mockMatchAppService.saveMatchesBulk(any())).thenAnswer((
          invocation,
        ) async {
          savedMatches =
              invocation.positionalArguments.first as List<MatchModel>;
        });

        WidgetRef? capturedRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              matchApplicationServiceProvider.overrideWithValue(
                mockMatchAppService,
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(
                extensions: [
                  AppThemeColors.ofMode(isDark: false, mode: 'operate'),
                ],
              ),
              home: Consumer(
                builder: (context, ref, child) {
                  capturedRef = ref;
                  return const Scaffold(body: Center(child: Text('Home')));
                },
              ),
            ),
          ),
        );

        // 1回目の編集シート表示＆保存
        showModalBottomSheet(
          context: tester.element(find.text('Home')),
          builder: (sheetCtx) => ElevatedButton(
            onPressed: () {
              MatchEditSaveHelper.executeSave(
                context: sheetCtx,
                ref: capturedRef!,
                matches: [initialMatch],
                isDantai: state.isDantai,
                isSwapped: state.isSwapped,
                initialOwnIsRed: state.initialOwnIsRed,
                ownTeamChoice: state.ownTeamChoice,
                groupInput: '',
                redTeamInput: state.redTeamController.text.trim(),
                whiteTeamInput: state.whiteTeamController.text.trim(),
                courtInput: '',
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
                hasRepresentativeMatch: state.hasRepresentativeMatch,
                isDaihyoIpponShobu: state.isDaihyoIpponShobu,
                daihyoMatchTime: state.daihyoMatchTime,
                daihyoHasExtension: state.daihyoHasExtension,
                daihyoEnchoTime: state.daihyoEnchoTime,
                daihyoEnchoCount: state.daihyoEnchoCount,
                isDaihyoEnchoUnlimited: state.isDaihyoEnchoUnlimited,
                daihyoHasHantei: state.daihyoHasHantei,
                renseikaiType: state.renseikaiType,
                overallTimeMinutes: 30,
                isKachinuki: state.isKachinuki,
                kachinukiUnlimitedType: state.kachinukiUnlimitedType,
                isLeague: state.isLeague,
                winPoint: state.winPoint,
                lossPoint: state.lossPoint,
                drawPoint: state.drawPoint,
                userNote: '',
                status: state.status,
                redPlayerControllers: state.redPlayerControllers,
                whitePlayerControllers: state.whitePlayerControllers,
                initialRedPlayers: state.initialRedPlayers,
                initialWhitePlayers: state.initialWhitePlayers,
              );
            },
            child: const Text('Save1'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save1'));
        await tester.pumpAndSettle();

        expect(savedMatches, isNotNull);
        final match1 = savedMatches!.first;

        // 編集後の第1試合のデータが意図通りであることを検証
        expect(match1.redName, '新赤道場: 新赤先鋒');
        expect(match1.whiteName, '新白道場: 新白先鋒');
        expect(match1.redRemaining, ['新赤道場: 新赤中堅', '新赤道場: 新赤大将']);
        expect(match1.whiteRemaining, ['新白道場: 新白中堅', '新白道場: 新白大将']);

        // 3. 【実際の試合進行・第1試合】赤の先鋒（新赤先鋒）が一本勝ちして終了
        final finishedMatch1 = match1.copyWith(
          status: 'finished',
          redScore: 1,
          whiteScore: 0,
        );

        // MatchDomainService によって勝ち抜き戦の第2試合を生成
        final domainService = MatchDomainService();
        final rule = match1.rule!;
        final match2 = domainService.generateNextKachinukiMatch(
          finishedMatch1,
          rule,
        );

        expect(match2, isNotNull);
        // 🏆 検証: 勝った「新赤先鋒」がそのまま赤側に勝ち残っていること！
        expect(match2!.redName, '新赤道場: 新赤先鋒');
        // 🏆 検証: 負けた白側は編集で設定した次選手「新白中堅」が待機リストから正しく登場していること！
        expect(match2.whiteName, '新白道場: 新白中堅');
        // 白の待機リストには大将のみ残っていること
        expect(match2.whiteRemaining, ['新白道場: 新白大将']);
        // 赤の待機リストは全員残っていること
        expect(match2.redRemaining, ['新赤道場: 新赤中堅', '新赤道場: 新赤大将']);

        // 4. 【実際の試合進行・第2試合】今度は白（新白中堅）が二本勝ちして逆転
        final finishedMatch2 = match2.copyWith(
          status: 'finished',
          redScore: 0,
          whiteScore: 2,
        );

        // 第3試合を生成
        final match3 = domainService.generateNextKachinukiMatch(
          finishedMatch2,
          rule,
        );

        expect(match3, isNotNull);
        // 🏆 検証: 勝った「新白中堅」が白側に勝ち残っていること！
        expect(match3!.whiteName, '新白道場: 新白中堅');
        // 🏆 検証: 負けた赤側は編集で設定した次選手「新赤中堅」が登場していること！
        expect(match3.redName, '新赤道場: 新赤中堅');
        // 赤の待機リストは大将のみ残っていること
        expect(match3.redRemaining, ['新赤道場: 新赤大将']);

        // 5. 【進行中のオーダー途中変更】第3試合の前に赤の大将の名前を「新赤大将」から「覚醒赤大将」に変更
        final inProgressState = MatchEditStateHolder([match1, match2, match3]);
        inProgressState.redPlayerControllers[2].text = '覚醒赤大将';

        List<MatchModel>? savedMatches2;
        when(() => mockMatchAppService.saveMatchesBulk(any())).thenAnswer((
          invocation,
        ) async {
          savedMatches2 =
              invocation.positionalArguments.first as List<MatchModel>;
        });

        // 2回目の編集シート表示＆保存
        showModalBottomSheet(
          context: tester.element(find.text('Home')),
          builder: (sheetCtx) => ElevatedButton(
            onPressed: () {
              MatchEditSaveHelper.executeSave(
                context: sheetCtx,
                ref: capturedRef!,
                matches: [match1, match2, match3],
                isDantai: inProgressState.isDantai,
                isSwapped: inProgressState.isSwapped,
                initialOwnIsRed: inProgressState.initialOwnIsRed,
                ownTeamChoice: inProgressState.ownTeamChoice,
                groupInput: '',
                redTeamInput: inProgressState.redTeamController.text.trim(),
                whiteTeamInput: inProgressState.whiteTeamController.text.trim(),
                courtInput: '',
                selectedPresetKey: inProgressState.selectedPresetKey,
                selectedPresetRule: inProgressState.selectedPresetRule,
                matchTime: inProgressState.matchTime,
                isRunningTime: inProgressState.isRunningTime,
                isIpponShobu: inProgressState.isIpponShobu,
                hasExtension: inProgressState.hasExtension,
                enchoTime: inProgressState.enchoTime,
                enchoCount: inProgressState.enchoCount,
                isEnchoUnlimited: inProgressState.isEnchoUnlimited,
                hasHantei: inProgressState.hasHantei,
                hasRepresentativeMatch: inProgressState.hasRepresentativeMatch,
                isDaihyoIpponShobu: inProgressState.isDaihyoIpponShobu,
                daihyoMatchTime: inProgressState.daihyoMatchTime,
                daihyoHasExtension: inProgressState.daihyoHasExtension,
                daihyoEnchoTime: inProgressState.daihyoEnchoTime,
                daihyoEnchoCount: inProgressState.daihyoEnchoCount,
                isDaihyoEnchoUnlimited: inProgressState.isDaihyoEnchoUnlimited,
                daihyoHasHantei: inProgressState.daihyoHasHantei,
                renseikaiType: inProgressState.renseikaiType,
                overallTimeMinutes: 30,
                isKachinuki: inProgressState.isKachinuki,
                kachinukiUnlimitedType: inProgressState.kachinukiUnlimitedType,
                isLeague: inProgressState.isLeague,
                winPoint: inProgressState.winPoint,
                lossPoint: inProgressState.lossPoint,
                drawPoint: inProgressState.drawPoint,
                userNote: '',
                status: inProgressState.status,
                redPlayerControllers: inProgressState.redPlayerControllers,
                whitePlayerControllers: inProgressState.whitePlayerControllers,
                initialRedPlayers: inProgressState.initialRedPlayers,
                initialWhitePlayers: inProgressState.initialWhitePlayers,
              );
            },
            child: const Text('Save2'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save2'));
        await tester.pumpAndSettle();

        expect(savedMatches2, isNotNull);
        final updatedMatch3 = savedMatches2![2];
        // 🏆 検証: 第3試合の待機リストの大将名が「新赤道場: 覚醒赤大将」に連動更新されていること！
        expect(updatedMatch3.redRemaining, ['新赤道場: 覚醒赤大将']);

        // 6. 【第3試合終了 -> 大将戦の生成】白（新白中堅）が再び勝ち、赤大将が登場
        final finishedMatch3 = updatedMatch3.copyWith(
          status: 'finished',
          redScore: 0,
          whiteScore: 1,
        );

        final match4 = domainService.generateNextKachinukiMatch(
          finishedMatch3,
          rule,
        );

        expect(match4, isNotNull);
        // 🏆 検証: 途中変更した「新赤道場: 覚醒赤大将」が第4試合の出場選手として完璧に繰り上がること！
        expect(match4!.redName, '新赤道場: 覚醒赤大将');
        expect(match4.whiteName, '新白道場: 新白中堅');
      },
    );
  });
}
