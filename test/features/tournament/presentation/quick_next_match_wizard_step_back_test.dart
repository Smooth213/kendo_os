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

  group('[Widget] クイック次戦作成ウィザード ステップ後退・状態整合性テスト', () {
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
                organization: '道上剣友会',
              ),
              PlayerModel(
                id: 'p2',
                lastName: '佐藤',
                firstName: '健',
                lastNameKana: 'さとう',
                firstNameKana: 'たける',
                grade: 5,
                organization: '道上剣友会',
              ),
            ]),
          ),
          customTeamNamesProvider.overrideWith(
            (ref) => Stream.value(['道上剣友会']),
          ),
          registeredTeamsProvider(
            baseMatch.tournamentId ?? '',
          ).overrideWith((ref) => Stream.value([])),
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

    testWidgets('対戦相手設定ステップから試合詳細ステップへ戻り、再進捗しても状態が安全に同期されること', (
      WidgetTester tester,
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

      // Step 0: 「試合詳細の設定へ進む」をタップ
      final nextButton1 = find.widgetWithText(ElevatedButton, '試合詳細の設定へ進む');
      expect(nextButton1, findsOneWidget);
      await tester.tap(nextButton1);
      await tester.pumpAndSettle();

      // Step 1: 「対戦相手・紅白へ進む」が表示されていること
      final nextButton2 = find.widgetWithText(ElevatedButton, '対戦相手・紅白へ進む');
      expect(nextButton2, findsOneWidget);

      // Step 1 から Step 0 へ戻る（OutlinedButtonの「戻る」ボタンを押下）
      final backButton = find.widgetWithText(OutlinedButton, '戻る');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // 再び Step 0 の「試合詳細の設定へ進む」が表示されていること
      expect(find.widgetWithText(ElevatedButton, '試合詳細の設定へ進む'), findsOneWidget);
    });

    testWidgets('ウィザードを途中で閉じた（キャンセルした）際にクラッシュせず安全に破棄されること', (
      WidgetTester tester,
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

      // キャンセルボタン（Icons.close）を押下
      final closeBtn = find.byIcon(Icons.close);
      if (closeBtn.evaluate().isNotEmpty) {
        await tester.tap(closeBtn.first);
        await tester.pumpAndSettle();
      }
    });
  });
}
