import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/official_record_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'
    show customTeamNamesProvider, tournamentProvider;
import 'package:go_router/go_router.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() => const SettingsModel(securityLevel: 1);
}

void main() {
  group('OfficialRecordScreen UI/Logic Tests', () {
    const testTournamentId = 'test_tournament_1';
    const testGroupId = '12345678-1234-1234-1234-123456789012';

    Widget createTestableWidget(
      List<MatchModel> mockMatches, {
      String tournamentId = testTournamentId,
    }) {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                OfficialRecordScreen(tournamentId: tournamentId),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          registeredTeamsProvider(
            tournamentId,
          ).overrideWith((ref) => Stream.value(<TeamModel>[])),
          isExportingProvider.overrideWith((ref) => false),
          matchListProvider.overrideWith((ref) => mockMatches),
          customTeamNamesProvider.overrideWith(
            (ref) => Stream.value(<String>[]),
          ),
          permissionProvider.overrideWith(
            (ref) => const AppPermissions(
              canCreateMatch: true,
              canManageTournament: true,
              isReadOnly: false,
              canChangeSettings: true,
              canDeleteData: true,
            ),
          ),
          settingsProvider.overrideWith(() => MockSettingsNotifier()),
          tournamentProvider(
            tournamentId,
          ).overrideWith((ref) => Stream.value(null)),
        ],
        child: MediaQuery(
          data: const MediaQueryData(size: Size(1200, 2400)),
          child: MaterialApp.router(
            theme: ThemeData(splashFactory: NoSplash.splashFactory),
            routerConfig: router,
          ),
        ),
      );
    }

    testWidgets('1. 代表戦のスコアがチームの合計(勝数/本数)に合算されないこと', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockMatches = [
        const MatchModel(
          id: 'm1',
          tournamentId: testTournamentId,
          category: '一般',
          groupName: 'team_group_1',
          matchType: '大将',
          redName: 'Aチーム: 赤選手',
          whiteName: 'Bチーム: 白選手',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
        ),
        const MatchModel(
          id: 'm2',
          tournamentId: testTournamentId,
          category: '一般',
          groupName: 'team_group_1',
          matchType: '代表戦', // ★ 代表戦
          redName: 'Aチーム: 赤代表',
          whiteName: 'Bチーム: 白代表',
          redScore: 2, // 代表戦で赤が2本取る
          whiteScore: 0,
          status: 'finished',
        ),
      ];

      await tester.pumpWidget(createTestableWidget(mockMatches));
      await tester.pumpAndSettle();

      // 本戦（大将戦）のチーム勝数「1勝 0敗」が集計サマリーに描画されていること
      expect(
        find.textContaining('1勝 0敗'),
        findsOneWidget,
        reason: '赤チームの本戦勝利「1勝 0敗」がサマリーに表示されるべき',
      );
    });

    testWidgets('2. 判定勝ちの場合、「判」という1文字に圧縮されて丸囲み等で描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final hanteiEvent = ScoreEventLegacyAdapter.fromLegacy(
        id: 'e1',
        type: PointType.hantei,
        side: Side.red,
        timestamp: DateTime.now(),
      );

      final mockMatches = [
        MatchModel(
          id: 'm1',
          tournamentId: testTournamentId,
          category: '一般',
          groupName: testGroupId,
          matchType: '個人戦',
          redName: '赤選手',
          whiteName: '白選手',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          events: [hanteiEvent],
        ),
      ];

      await tester.pumpWidget(createTestableWidget(mockMatches));
      await tester.pumpAndSettle();

      // KendoRuleEngine を通して「判定」が返ってくるが、UIで「判」に圧縮される
      expect(find.text('判'), findsOneWidget);
      expect(
        find.text('判定'),
        findsNothing,
        reason: 'レイアウト崩れを防ぐため「判定」とは表示されないこと',
      );
    });

    testWidgets('3. 欠員の場合、選手名のセルは空欄で表示されるべき', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final matches = [
        const MatchModel(
          id: 'm_kekkin',
          tournamentId: testTournamentId,
          category: '一般',
          groupName: 'team_group_1',
          redName: 'チームA:山田太郎',
          whiteName: 'チームB:(欠員)',
          redScore: 1,
          whiteScore: 0,
          matchType: '先鋒',
          status: 'finished',
        ),
      ];

      await tester.pumpWidget(createTestableWidget(matches));
      await tester.pumpAndSettle();

      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('(欠員)'), findsNothing);
    });

    testWidgets('4. 同姓の選手がいる場合、名（イニシャル）が表示されるべき', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final matches = [
        const MatchModel(
          id: 'm_same_1',
          tournamentId: testTournamentId,
          category: '一般',
          groupName: 'team_group_1',
          order: 1,
          matchType: '先鋒',
          redName: 'チームA:山田 太郎',
          whiteName: 'チームB:佐藤 一',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
        ),
        const MatchModel(
          id: 'm_same_2',
          tournamentId: testTournamentId,
          category: '一般',
          groupName: 'team_group_1',
          order: 2,
          matchType: '次鋒',
          redName: 'チームA:山田 花子',
          whiteName: 'チームB:鈴木 二',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
        ),
      ];

      await tester.pumpWidget(createTestableWidget(matches));
      await tester.pumpAndSettle();

      // イニシャル '太' と '花' が画面上に描画されていることを確認
      expect(find.text('太'), findsOneWidget);
      expect(find.text('花'), findsOneWidget);
    });

    testWidgets('5. PDF出力ボタンをタップした際、ローディングが表示され最終的に閉じられること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final matches = [
        const MatchModel(
          id: 'm1',
          tournamentId: testTournamentId,
          category: '一般',
          groupName: testGroupId,
          matchType: '個人戦',
          redName: 'チームA:山田太郎',
          whiteName: 'チームB:佐藤一郎',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
        ),
      ];

      await tester.pumpWidget(createTestableWidget(matches));
      await tester.pumpAndSettle();

      // PDFボタンを探す
      final pdfButton = find.text('PDF').first;
      expect(pdfButton, findsOneWidget);

      // タップする
      await tester.tap(pdfButton);
      await tester.pump(); // ダイアログ表示アニメーションへ

      // CircularProgressIndicator が表示されていることを確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 非同期処理が完了するまで待機（SnackBar等が出た場合も消えるまで待機）
      await tester.pumpAndSettle();

      // ダイアログが消えていることを確認
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('6. 試合が order プロパティの昇順にソートされて表示されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // order が逆順になっているモックデータを作成
      final mockMatches = [
        const MatchModel(
          id: 'm2',
          tournamentId: testTournamentId,
          category: '一般',
          groupName: 'team_group_1',
          matchType: '大将',
          redName: 'Aチーム: 赤大将',
          whiteName: 'Bチーム: 白大将',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          order: 2.0, // order が大きい
        ),
        const MatchModel(
          id: 'm1',
          tournamentId: testTournamentId,
          category: '一般',
          groupName: 'team_group_1',
          matchType: '先鋒',
          redName: 'Aチーム: 赤先鋒',
          whiteName: 'Bチーム: 白先鋒',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          order: 1.0, // order が小さい
        ),
      ];

      await tester.pumpWidget(createTestableWidget(mockMatches));
      await tester.pumpAndSettle();

      // 先鋒が画面上（または左側）で大将より前にレイアウトされていることを確認
      final senhoPos = tester.getTopLeft(find.text('先鋒'));
      final taishoPos = tester.getTopLeft(find.text('大将'));

      expect(
        senhoPos.dx < taishoPos.dx || senhoPos.dy < taishoPos.dy,
        isTrue,
        reason: 'order: 1.0 の先鋒が order: 2.0 の大将より前に描画されること',
      );
    });
  });
}
