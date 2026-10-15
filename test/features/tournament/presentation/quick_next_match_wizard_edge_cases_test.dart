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

  group('[Widget] クイック次戦作成ウィザード エッジケース検証', () {
    late MockMatchApplicationService mockMatchService;

    setUp(() {
      mockMatchService = MockMatchApplicationService();
      when(() => mockMatchService.saveMatch(any())).thenAnswer((_) async {});
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
                lastName: '塚本',
                firstName: '大道',
                lastNameKana: 'つかもと',
                firstNameKana: 'だいどう',
                grade: 4,
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

    testWidgets('剣道形において片方の選手のみ欠員として確定した際、結合文字列として正しく保存されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const kataRule = MatchRule(
        isKataMatch: true,
        isRenseikai: true,
        teamName: '道上剣友会',
      );

      const baseMatch = MatchModel(
        id: 'm_kata_edge_1',
        tournamentId: 't1',
        category: '剣道形',
        matchType: '形競技',
        redName: '道上剣友会 : 皿田 脩人・塚本 大道',
        whiteName: '相手道場 : 相手打太刀・相手仕太刀',
        groupName: '第1試合場',
        matchOrder: 1,
        rule: kataRule,
      );

      await tester.pumpWidget(createTestWidget(baseMatch: baseMatch));
      await tester.pumpAndSettle();

      // Step 1: 自チーム選手（皿田 脩人、塚本 大道）の2スロットが表示されていることを確認
      expect(find.text('皿田 脩人'), findsOneWidget);
      expect(find.text('塚本 大道'), findsOneWidget);

      // Step 2 ➔ Step 3へ進む
      await tester.tap(find.widgetWithText(ElevatedButton, '試合詳細の設定へ進む'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, '対戦相手・紅白へ進む'));
      await tester.pumpAndSettle();

      // Step 3: 対戦相手側の2スロットが表示されている
      final absentButtons = find.text('欠員');
      expect(absentButtons, findsNWidgets(2));

      // 相手の2人目（仕太刀側）のみ「欠員」をタップ
      await tester.tap(absentButtons.at(1));
      await tester.pumpAndSettle();

      // 確定
      await tester.tap(find.widgetWithText(ElevatedButton, 'このオーダーで確定して進む'));
      await tester.pumpAndSettle();

      // 検証: saveMatch が呼ばれ、白（相手側）の2人目が「選手」補完され結合されていること
      final captured = verify(
        () => mockMatchService.saveMatch(captureAny()),
      ).captured;
      expect(captured.isNotEmpty, isTrue);

      final createdMatch = captured.first as MatchModel;
      expect(createdMatch.redName, contains('皿田 脩人・塚本 大道'));
      // 相手1人目は未入力なので「選手」、2人目は欠員指定なので「欠員」となり「選手・欠員」
      expect(createdMatch.whiteName, contains('選手・欠員'));
    });

    testWidgets('剣道形において同じ相手と続けて試合で起動した際、相手ペア2名がスロットに正しく復元されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const kataRule = MatchRule(
        isKataMatch: true,
        isRenseikai: true,
        teamName: '道上剣友会',
      );

      const baseMatch = MatchModel(
        id: 'm_kata_edge_2',
        tournamentId: 't1',
        category: '剣道形',
        matchType: '形競技',
        redName: '道上剣友会 : 皿田 脩人・塚本 大道',
        whiteName: '相手道場 : 伊藤 誠・田中 太郎',
        groupName: '第1試合場',
        matchOrder: 1,
        rule: kataRule,
      );

      await tester.pumpWidget(
        createTestWidget(baseMatch: baseMatch, isSameTeamContinue: true),
      );
      await tester.pumpAndSettle();

      // Step 1 ➔ Step 2 ➔ Step 3 へ進む
      await tester.tap(find.widgetWithText(ElevatedButton, '試合詳細の設定へ進む'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, '対戦相手・紅白へ進む'));
      await tester.pumpAndSettle();

      // 相手道場名と相手ペア2名（伊藤 誠、田中 太郎）が引き継がれていることを確認
      expect(find.text('相手道場'), findsOneWidget);
      expect(find.text('伊藤 誠'), findsOneWidget);
      expect(find.text('田中 太郎'), findsOneWidget);

      // 確定
      await tester.tap(find.widgetWithText(ElevatedButton, 'このオーダーで確定して進む'));
      await tester.pumpAndSettle();

      final captured = verify(
        () => mockMatchService.saveMatch(captureAny()),
      ).captured;
      expect(captured.isNotEmpty, isTrue);

      final createdMatch = captured.first as MatchModel;
      expect(createdMatch.whiteName, contains('相手道場 : 伊藤 誠・田中 太郎'));
    });
  });
}
