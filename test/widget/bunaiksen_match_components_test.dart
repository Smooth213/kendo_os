import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_custom_time_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_score_marks.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_team_member_list.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] 部内戦試合運用・設定コンポーネント統合テスト', () {
    group('BunaiksenCustomTimeDialog ウィジェットテスト', () {
      testWidgets('分と秒のテキストフィールドが初期値とともに正しく描画されること', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => BunaiksenCustomTimeDialog.show(
                    context,
                    currentTime: 2.5,
                    isDark: false,
                    primaryAccent: Colors.blue,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.safePumpAndSettle();

        expect(find.text('任意の試合時間'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);
        expect(find.text('キャンセル'), findsOneWidget);
        expect(find.text('設定する'), findsOneWidget);
      });

      testWidgets('送信時に値が更新され計算された合計分が正しく返却されること', (WidgetTester tester) async {
        double? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await BunaiksenCustomTimeDialog.show(
                      context,
                      currentTime: 1.0,
                      isDark: true,
                      primaryAccent: Colors.deepPurple,
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.safePumpAndSettle();

        final minField = find.widgetWithText(TextField, '1');
        await tester.enterText(minField, '3');

        final secField = find.widgetWithText(TextField, '0');
        await tester.enterText(secField, '45');

        await tester.tap(find.text('設定する'));
        await tester.safePumpAndSettle();

        expect(result, equals(3.75));
      });
    });

    group('BunaiksenTeamMemberList ウィジェットテスト', () {
      testWidgets('ポジションとメンバーが描画されタップ時にクリアが正常に実行されること', (tester) async {
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );
        int? clearedIndex;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: BunaiksenTeamMemberList(
                teamSize: 3,
                teamMembers: const ['先鋒選手', null, '大将選手'],
                positions: const ['先鋒', '中堅', '大将'],
                teamColor: AppKendoColors.hansokuRed,
                isDark: false,
                onMemberAssigned: (index, name) {},
                onMemberCleared: (index) => clearedIndex = index,
              ),
            ),
          ),
        );

        expect(find.text('先鋒選手'), findsOneWidget);
        expect(find.text('未定'), findsOneWidget);
        expect(find.text('大将選手'), findsOneWidget);

        await tester.tap(find.text('先鋒選手'));
        await tester.pump();
        expect(clearedIndex, 0);
      });
    });

    group('BunaiksenScoreMarks ウィジェットテスト', () {
      testWidgets('両者スコアが0の場合は引き分けマークが表示されること', (WidgetTester tester) async {
        const match = MatchModel(
          id: 'm1',
          tournamentId: 't1',
          matchType: '先鋒',
          redScore: 0,
          whiteScore: 0,
          redName: '選手A',
          whiteName: '選手B',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: BunaiksenScoreMarks(
                match: match,
                isDark: false,
                isFinished: true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('打突種別と引き分けアイコンが状態に応じて正しく描画されること', (
        WidgetTester tester,
      ) async {
        final now = DateTime.now();
        final events = [
          ScoreEvent(
            id: 'e1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: now,
          ),
          ScoreEvent(
            id: 'e2',
            side: Side.white,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: now.add(const Duration(seconds: 10)),
          ),
        ];

        final match = MatchModel(
          id: 'm2',
          tournamentId: 't1',
          matchType: '先鋒',
          redScore: 1,
          whiteScore: 1,
          redName: '選手A',
          whiteName: '選手B',
          events: events,
          rule: const MatchRule(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BunaiksenScoreMarks(
                match: match,
                isDark: true,
                isFinished: true,
              ),
            ),
          ),
        );

        expect(find.textContaining('㋱'), findsOneWidget);
        expect(find.textContaining('コ'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('勝利試合で打突マークとハイフンアイコンが正しく描画されること', (
        WidgetTester tester,
      ) async {
        final now = DateTime.now();
        final events = [
          ScoreEvent(
            id: 'e1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: now,
          ),
          ScoreEvent(
            id: 'e2',
            side: Side.red,
            strikeType: StrikeType.dou,
            isIppon: true,
            timestamp: now.add(const Duration(seconds: 10)),
          ),
        ];

        final match = MatchModel(
          id: 'm3',
          tournamentId: 't1',
          matchType: '先鋒',
          redScore: 2,
          whiteScore: 0,
          redName: '選手A',
          whiteName: '選手B',
          events: events,
          rule: const MatchRule(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BunaiksenScoreMarks(
                match: match,
                isDark: false,
                isFinished: true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.remove), findsOneWidget);
        expect(find.textContaining('㋱'), findsOneWidget);
        expect(find.textContaining('ド'), findsOneWidget);
      });
    });
  });
}
