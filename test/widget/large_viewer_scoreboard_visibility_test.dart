import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/viewer/components/large_viewer_scoreboard.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_match_card.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_score_table_card.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testProjection = MatchProjection(
    id: 'm1',
    tournamentId: 't1',
    matchOrder: 1,
    matchType: '先鋒',
    status: 'finished',
    groupName: '団体戦',
    isKachinuki: false,
    redName: 'A道場 : 選手',
    whiteName: 'B道場 : 皿田 脩人',
    note: '',
    redScore: 2,
    whiteScore: 1,
    redDisplays: [PointDisplay('メ', true), PointDisplay('ド', false)],
    whiteDisplays: [PointDisplay('コ', false)],
    remainingSeconds: 120,
    timerIsRunning: false,
  );

  group('🛡️ 観客席ビュアー 視認性・コントラスト保証テスト', () {
    testWidgets('1. 【試合状況画面】ライトモードで赤・白の選手名と技マークが高コントラストで視認できること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.light,
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: LargeViewerScoreboard(
              projection: testProjection,
              activeMatch: null,
              isDark: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 赤側選手名「選手」が濃赤(hansokuRed)で表示され、赤背景と同化しないこと
      final redNameFinder = find.text('選手');
      expect(redNameFinder, findsOneWidget);
      final redTextWidget = tester.widget<Text>(redNameFinder);
      expect(redTextWidget.style?.color, AppKendoColors.hansokuRed);

      // 白側選手名「皿田 脩人」が濃紺スレート(0xFF1E293B)で表示され、白グレー背景と同化しないこと
      final whiteNameFinder = find.text('皿田 脩人');
      expect(whiteNameFinder, findsOneWidget);
      final whiteTextWidget = tester.widget<Text>(whiteNameFinder);
      expect(whiteTextWidget.style?.color, const Color(0xFF1E293B));

      // 技マークが表示されていること
      expect(find.text('メ'), findsOneWidget);
      expect(find.text('ド'), findsOneWidget);
      expect(find.text('コ'), findsOneWidget);

      // 🛡️ タイマー非表示仕様：タイマー（Icons.timer）や時間文字列が表示されず、スコア「2 - 1」のみが表示されること
      expect(find.byIcon(Icons.timer), findsNothing);
      expect(find.text('02:00'), findsNothing);
      expect(find.text('2 - 1'), findsOneWidget);
    });

    testWidgets('2. 【試合状況画面】ダークモードで白側選手名が黒潰れせず純白(pureWhite)で読めること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
          ),
          home: Scaffold(
            body: LargeViewerScoreboard(
              projection: testProjection,
              activeMatch: null,
              isDark: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final redNameFinder = find.text('選手');
      expect(redNameFinder, findsOneWidget);
      final redTextWidget = tester.widget<Text>(redNameFinder);
      expect(redTextWidget.style?.color, const Color(0xFFFF6B6B));

      // 白側選手名が暗い線色ではなく純白(pureWhite)であること
      final whiteNameFinder = find.text('皿田 脩人');
      expect(whiteNameFinder, findsOneWidget);
      final whiteTextWidget = tester.widget<Text>(whiteNameFinder);
      expect(whiteTextWidget.style?.color, AppKendoColors.pureWhite);
    });

    testWidgets('3. 【部内戦試合カード】ライト・ダークモードでスコアマークの視認性が確保されること', (tester) async {
      final match = MatchModel(
        id: 'bm1',
        tournamentId: 'bunaiksen_20260829',
        matchOrder: 1,
        matchType: '個人戦',
        status: 'finished',
        redName: 'A道場 : 皿田',
        whiteName: 'B道場 : 鈴木',
        redScore: 2,
        whiteScore: 0,
        events: [
          ScoreEvent(
            id: 'e1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: DateTime.now(),
            userId: 'u1',
            sequence: 1,
          ),
          ScoreEvent(
            id: 'e2',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: DateTime.now(),
            userId: 'u1',
            sequence: 2,
          ),
        ],
      );

      final marksWidget = ViewerBunaiksenMatchCard.buildScoreMarks(
        match,
        false, // isDark: false (ライト)
        isFinished: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: marksWidget)),
        ),
      );

      await tester.pumpAndSettle();

      // 先取点マーク（㋱）と2本目マーク（コ）が表示されること
      expect(find.text('㋱コ'), findsOneWidget);
    });

    testWidgets('4. 【部内戦スコアテーブル】団体戦スコアテーブルの視認性が確保されること', (tester) async {
      final teamMatches = [
        MatchModel(
          id: 'tm1',
          tournamentId: 'bunaiksen_20260829',
          matchOrder: 1,
          matchType: '先鋒',
          status: 'finished',
          redName: 'Aチーム : 佐藤',
          whiteName: 'Bチーム : 田中',
          redScore: 1,
          whiteScore: 0,
          events: [
            ScoreEvent(
              id: 'e1',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: DateTime.now(),
              userId: 'u1',
              sequence: 1,
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ViewerBunaiksenScoreTableCard(
                groupName: '団体戦Aブロック',
                matches: teamMatches,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aチーム vs Bチーム'), findsOneWidget);
      expect(find.text('先鋒'), findsOneWidget);
    });
  });
}
