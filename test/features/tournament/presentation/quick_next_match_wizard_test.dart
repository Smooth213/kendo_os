import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/quick_next_match/quick_next_match_wizard_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_screen_providers.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

class MockMatchApplicationService extends Mock
    implements MatchApplicationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const MatchModel(
        id: 'fallback_id',
        matchType: '先鋒',
        redName: 'red',
        whiteName: 'white',
      ),
    );
  });

  group('[Widget] クイック次戦作成ウィザードの検証', () {
    late MockMatchApplicationService mockMatchService;

    setUp(() {
      mockMatchService = MockMatchApplicationService();
      when(() => mockMatchService.saveMatch(any())).thenAnswer((_) async {});
    });

    tearDown(() async {
      // リセット
    });

    Widget createTestWidget({
      required MatchModel baseMatch,
      List<MatchModel> teamMatches = const [],
      bool isSameTeamContinue = false,
    }) {
      return ProviderScope(
        overrides: [
          matchApplicationServiceProvider.overrideWithValue(mockMatchService),
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
                lastName: '佐藤',
                firstName: '健',
                lastNameKana: 'さとう',
                firstNameKana: 'たける',
                grade: 6,
              ),
            ]),
          ),
          customTeamNamesProvider.overrideWith(
            (ref) => Stream.value(['道上剣友会']),
          ),
          registeredTeamsProvider('t1').overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: QuickNextMatchWizardSheet(
              baseMatch: baseMatch,
              teamMatches: teamMatches,
              isSameTeamContinue: isSameTeamContinue,
            ),
          ),
        ),
      );
    }

    testWidgets('クイック次戦作成: 紅白トグルで白を選択した際、自チームが白・相手が赤に反転して保存されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const baseMatch = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        category: '小学生団体',
        matchType: '先鋒',
        redName: '道上剣友会 : 皿田 脩人',
        whiteName: '相手道場 : 相手選手',
        note: '第1試合場, 1試合目',
        rule: MatchRule(teamName: '道上剣友会'),
      );

      await tester.pumpWidget(
        createTestWidget(baseMatch: baseMatch, teamMatches: [baseMatch]),
      );
      await tester.pumpAndSettle();

      // Step 1: 「試合詳細の設定へ進む」をタップ
      final nextButton1 = find.widgetWithText(ElevatedButton, '試合詳細の設定へ進む');
      expect(nextButton1, findsOneWidget);
      await tester.tap(nextButton1);
      await tester.pumpAndSettle();

      // Step 2: 「対戦相手・紅白へ進む」をタップ
      final nextButton2 = find.widgetWithText(ElevatedButton, '対戦相手・紅白へ進む');
      expect(nextButton2, findsOneWidget);
      await tester.tap(nextButton2);
      await tester.pumpAndSettle();

      // Step 3: 「白（右側）」をタップして自チームを白に変更
      final whiteToggle = find.text('白（右側）');
      expect(whiteToggle, findsOneWidget);
      await tester.tap(whiteToggle);
      await tester.pumpAndSettle();

      // 「このオーダーで確定して進む」をタップ
      final confirmButton = find.widgetWithText(
        ElevatedButton,
        'このオーダーで確定して進む',
      );
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // 検証: 保存された MatchModel の redName が相手、whiteName が自チームになっていること
      final captured = verify(
        () => mockMatchService.saveMatch(captureAny()),
      ).captured;
      expect(captured.isNotEmpty, isTrue);

      final createdMatch = captured.first as MatchModel;
      expect(createdMatch.whiteName, contains('道上剣友会 : 皿田 脩人'));
      expect(createdMatch.redName, contains('相手道場'));
    });

    testWidgets('錬成会モード: オーダー確認画面で即開始ボタンを押した際、後続設定をスキップして即座に次戦が保存されること', (
      tester,
    ) async {
      const baseMatch = MatchModel(
        id: 'm_renseikai',
        tournamentId: 't1',
        category: '錬成会',
        matchType: '先鋒',
        redName: '道上剣友会 : 皿田 脩人',
        whiteName: 'ライバル道場 : 相手選手',
        note: '第2試合場',
        rule: MatchRule(teamName: '道上剣友会', isRenseikai: true),
      );

      await tester.pumpWidget(
        createTestWidget(
          baseMatch: baseMatch,
          teamMatches: [baseMatch],
          isSameTeamContinue: true,
        ),
      );
      await tester.pumpAndSettle();

      // 錬成会即開始ボタンが存在すること
      final quickStartButton = find.widgetWithText(
        ElevatedButton,
        'このオーダーのまま即開始（Step2/3をスキップ）',
      );
      expect(quickStartButton, findsOneWidget);

      // タップして即時作成
      await tester.tap(quickStartButton);
      await tester.pumpAndSettle();

      // 検証: Step 2/3 を経由せずに即 saveMatch が呼ばれたこと
      final captured = verify(
        () => mockMatchService.saveMatch(captureAny()),
      ).captured;
      expect(captured.isNotEmpty, isTrue);

      final createdMatch = captured.first as MatchModel;
      expect(createdMatch.redName, contains('道上剣友会 : 皿田 脩人'));
      expect(createdMatch.whiteName, contains('ライバル道場 : 相手選手'));
      expect(createdMatch.note, equals('第2試合場'));
    });

    testWidgets('回戦チップ選択: 試合詳細画面で回戦を選択した際、見出しnoteに正しく反映されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const baseMatch = MatchModel(
        id: 'm_tourney',
        tournamentId: 't1',
        category: 'トーナメント',
        matchType: '先鋒',
        redName: '道上剣友会 : 皿田 脩人',
        whiteName: '相手道場 : 選手',
        note: '第1試合場, 1回戦',
        rule: MatchRule(teamName: '道上剣友会'),
      );

      await tester.pumpWidget(
        createTestWidget(baseMatch: baseMatch, teamMatches: [baseMatch]),
      );
      await tester.pumpAndSettle();

      // Step 1 ➔ Step 2 へ進む
      await tester.tap(find.widgetWithText(ElevatedButton, '試合詳細の設定へ進む'));
      await tester.pumpAndSettle();

      // Step 2: 「2回戦」チップをタップ
      final round2Chip = find.text('2回戦');
      expect(round2Chip, findsOneWidget);
      await tester.tap(round2Chip);
      await tester.pumpAndSettle();

      // Step 2 ➔ Step 3 へ進む
      await tester.tap(find.widgetWithText(ElevatedButton, '対戦相手・紅白へ進む'));
      await tester.pumpAndSettle();

      // Step 3: 確定
      await tester.tap(find.widgetWithText(ElevatedButton, 'このオーダーで確定して進む'));
      await tester.pumpAndSettle();

      // 検証: note に '2回戦' が反映されていること
      final captured = verify(
        () => mockMatchService.saveMatch(captureAny()),
      ).captured;
      expect(captured.isNotEmpty, isTrue);

      final createdMatch = captured.first as MatchModel;
      expect(createdMatch.note, contains('2回戦'));
    });
  });
}
