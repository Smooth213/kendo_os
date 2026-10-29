import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_players_score_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_action_button_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_bottom_action_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_mini_log_undo_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_timer_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('[Widget] 試合操作画面 アクションボタン・操作バー・表示行統合検証テスト', () {
    testWidgets('MatchActionButtonRowにおいて シングルタップが正しく動作すること', (tester) async {
      bool singleTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchActionButtonRow(
              label: '試合終了',
              confirmBehavior: 'single',
              onAction: () => singleTriggered = true,
              isViewOnly: false,
              backgroundColor: AppKendoColors.blueAccent,
              promptMessage: 'タップしてください',
            ),
          ),
        ),
      );

      expect(find.text('試合終了'), findsOneWidget);
      await tester.tap(find.text('試合終了'));
      await tester.pump();
      expect(singleTriggered, isTrue);
    });

    testWidgets('MatchActionButtonRowにおいて ダブルタップ設定時にダブルタップへ応答すること', (
      tester,
    ) async {
      bool doubleTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchActionButtonRow(
              label: '記録を確定して次へ',
              icon: Icons.check_circle,
              confirmBehavior: 'double',
              onAction: () => doubleTriggered = true,
              isViewOnly: false,
              backgroundColor: AppKendoColors.blueAccent,
              promptMessage: 'もう一度タップで確定',
            ),
          ),
        ),
      );

      expect(find.text('記録を確定して次へ'), findsOneWidget);
      await tester.tap(find.text('記録を確定して次へ'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('記録を確定して次へ'));
      await tester.safePumpAndSettle();
      expect(doubleTriggered, isTrue);
    });

    testWidgets('MatchBottomActionSectionにおいて 確定済み状態が正しく表示されること', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        redName: 'A',
        whiteName: 'B',
        matchType: '団体戦',
        status: 'approved',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Scaffold(
              body: MatchBottomActionSection(
                match: match,
                rule: MatchRule(),
                isApproved: true,
                isViewOnly: false,
                isTie: false,
                isAllDone: true,
                isDark: false,
                myUserId: 'u1',
                teamMatches: [match],
                onAddRenseikaiNext: () {},
                onShowConfirmDialog: (title, content) async => true,
                onShowMatchFinishedDialog: (ctx, m, next) {},
                onShowHanteiDialog: (m) async => null,
              ),
            ),
          ),
        ),
      );

      expect(find.text('公式記録確定済み'), findsOneWidget);
    });

    testWidgets('MatchMiniLogUndoSectionにおいて 履歴表示とUndoコールバックが動作すること', (
      tester,
    ) async {
      bool undoTriggered = false;
      final events = [
        ScoreEvent(
          id: 'e1',
          side: Side.red,
          strikeType: StrikeType.men,
          timestamp: DateTime(2026, 8, 20, 10, 0, 0),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchMiniLogUndoSection(
              validEvents: events,
              canUndo: true,
              isDark: false,
              onUndo: () => undoTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('メン'), findsOneWidget);
      expect(find.text('１つ前の操作を取り消す'), findsOneWidget);

      await tester.tap(find.text('１つ前の操作を取り消す'));
      await tester.pump();
      expect(undoTriggered, isTrue);
    });

    testWidgets('MatchPlayersScoreRowにおいて 選手名と取得本数マークが正しく描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchPlayersScoreRow(
              redName: '塚本 大道',
              whiteName: '久安 智也',
              isRedOwn: true,
              isWhiteOwn: false,
              redPoints: [PointMark(mark: 'メ', isFirst: true)],
              whitePoints: [PointMark(mark: 'コ', isFirst: false)],
              isDraw: false,
              textColor: Colors.white,
              subTextColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('塚本 大道'), findsOneWidget);
      expect(find.text('久安 智也'), findsOneWidget);
      expect(find.text('メ'), findsOneWidget);
      expect(find.text('コ'), findsOneWidget);
      expect(find.text('ー'), findsOneWidget);
    });

    testWidgets('MatchTimerSectionにおいて タイマーセクションが正しく描画されること', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        redName: 'Red',
        whiteName: 'White',
        matchType: '個人戦',
      );
      final rule = MatchRule(matchTimeMinutes: 3.0);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            matchStreamProvider.overrideWith((ref) => Stream.value([match])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MatchTimerSection(
                match: match,
                rule: rule,
                isInputLocked: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MatchTimerSection), findsOneWidget);
    });
  });
}
