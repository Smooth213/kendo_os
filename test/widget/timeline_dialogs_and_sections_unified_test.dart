import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/timeline_category_filter_chips_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_individual_player_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_inner_comment_widget.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_league_title_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_rename_team_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_status_message_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_summary_input_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_team_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_tie_break_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_unified_announce_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_app.dart';

class _DummyTeam {
  final String name;
  _DummyTeam(this.name);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] タイムライン ダイアログ・セクション・コンポーネント統合検証テスト', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('タイムラインサマリー入力ダイアログが正しく描画されること', (tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final prefs = await SharedPreferences.getInstance();

      final matches = [
        MatchModel(
          id: 'm1',
          tournamentId: 't1',
          matchType: '先鋒戦',
          order: 1,
          redName: '赤心館 : 選手1',
          whiteName: '白龍会 : 選手2',
          status: 'pending',
          note: '',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () {
                      TimelineSummaryInputDialog.show(context, ref, matches);
                    },
                    child: const Text('簡易入力ダイアログを開く'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('簡易入力ダイアログを開く'));
      await tester.pumpAndSettle();

      expect(find.text('他コートの簡易入力'), findsOneWidget);
      expect(find.text('赤心館'), findsOneWidget);
      expect(find.text('白龍会'), findsOneWidget);
      expect(find.text('記録を確定する'), findsOneWidget);
    });

    testWidgets('タイブレークダイアログが正しく描画されること', (tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final prefs = await SharedPreferences.getInstance();

      final firstMatch = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: '先鋒戦',
        order: 1,
        redName: 'チームA : 選手1',
        whiteName: 'チームB : 選手2',
        status: 'pending',
        note: '',
      );

      final tieTeams = [_DummyTeam('チームA'), _DummyTeam('チームB')];
      final baseRule = MatchRule();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () {
                      TimelineTieBreakDialog.show(
                        context,
                        ref,
                        firstMatch,
                        tieTeams,
                        baseRule,
                      );
                    },
                    child: const Text('決定戦ダイアログを開く'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('決定戦ダイアログを開く'));
      await tester.pumpAndSettle();

      expect(find.text('決定戦の形式を選択'), findsOneWidget);
      expect(find.text('代表戦（1名）'), findsOneWidget);
      expect(find.text('チーム再試合'), findsOneWidget);
      expect(find.text('何もしない'), findsOneWidget);
    });

    testWidgets('TimelineCategoryFilterChipsBar でチップが表示されタップできること', (
      tester,
    ) async {
      final m1 = MatchModel(
        id: 'm1',
        category: '小学生低学年',
        matchType: '団体戦',
        redName: '道場A',
        whiteName: '道場B',
        groupName: 'group_A',
      );
      final m2 = MatchModel(
        id: 'm2',
        category: '小学生高学年',
        matchType: '団体戦',
        redName: '道場A',
        whiteName: '道場C',
        groupName: 'group_B',
      );

      final entries = [
        MapEntry('小学生低学年', [m1]),
        MapEntry('小学生高学年', [m2]),
      ];

      await tester.pumpWidget(
        createTestApp(
          Theme(
            data: ThemeData.light().copyWith(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            child: Scaffold(
              body: TimelineCategoryFilterChipsBar(
                categoryEntries: entries,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('すべて'), findsOneWidget);
      expect(find.text('小学生低学年'), findsOneWidget);
      expect(find.text('小学生高学年'), findsOneWidget);

      await tester.tap(find.text('小学生低学年'));
      await tester.pumpAndSettle();
    });

    testWidgets('TimelineDialogAndHelper 各種ヘルパーおよびシートが正しく動作すること', (
      tester,
    ) async {
      final matches = [
        const MatchModel(
          id: 'm1',
          tournamentId: 't1',
          order: 1,
          redName: 'Aチーム',
          whiteName: 'Bチーム',
          matchType: 'team',
        ),
        const MatchModel(
          id: 'm2',
          tournamentId: 't1',
          order: 2,
          redName: 'Bチーム',
          whiteName: 'Cチーム',
          matchType: 'team',
        ),
      ];

      final title = TimelineLeagueTitleHelper.generateDescriptiveLeagueTitle(
        matches,
        ['Aチーム'],
      );
      expect(title, contains('Aチーム'));
      expect(title, contains('3チームリーグ'));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TimelineRenameTeamSheet(
                  tournamentId: 't1',
                  oldName: '旧チーム名',
                  ref: ref,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('チーム名の修正・統合'), findsOneWidget);
      expect(find.text('一括修正して統合する'), findsOneWidget);

      const comment = MatchCommentModel(
        id: 'c1',
        tournamentId: 't1',
        text: 'テスト見出しコメント',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TimelineInnerCommentWidget(
                  comment: comment,
                  permissions: const PermissionState(canManageTournament: true),
                  isDark: false,
                  ref: ref,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('テスト見出しコメント'), findsOneWidget);
    });

    testWidgets('TimelineStatusMessageSectionにおいて 状態に応じたメッセージが表示されること', (
      tester,
    ) async {
      const SafeTimelineResult errorResult = (
        entries: [],
        isLoading: false,
        hasError: true,
        errorMessage: 'Network error',
        matchedMatchIds: {},
        matchedGroupNames: {},
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimelineStatusMessageSection(
              timelineResult: errorResult,
              sanitizedQuery: '',
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('データの取得に失敗しました'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);

      const SafeTimelineResult emptyResult = (
        entries: [],
        isLoading: false,
        hasError: false,
        errorMessage: null,
        matchedMatchIds: {},
        matchedGroupNames: {},
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimelineStatusMessageSection(
              timelineResult: emptyResult,
              sanitizedQuery: 'test_query',
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('該当する試合が見つかりません'), findsOneWidget);
    });

    testWidgets('Timeline Extracted Components 個人・団体カードが正しく描画されること', (
      tester,
    ) async {
      final indivMatch = MatchModel(
        id: 'm1',
        matchOrder: 1,
        redName: '佐藤',
        whiteName: '鈴木',
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
        matchType: 'individual',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TimelineIndividualPlayerCard(
                playerName: '佐藤',
                playerMatches: [indivMatch],
                playerComments: const [],
                categoryName: '一般の部',
                teamName: 'A道場',
                isReadOnlyUI: false,
                isDark: false,
                permissions: const PermissionState(
                  isReadOnly: false,
                  canManageTournament: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('佐'), findsOneWidget);
      expect(find.text('終了'), findsOneWidget);

      final teamMatch = MatchModel(
        id: 'm2',
        matchOrder: 1,
        redName: 'A道場 : 佐藤',
        whiteName: 'B道場 : 鈴木',
        redScore: 0,
        whiteScore: 0,
        status: 'waiting',
        matchType: 'team',
        groupName: '第1試合場',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TimelineTeamCard(
                  teamName: 'A道場',
                  teamMatchesList: [teamMatch],
                  categoryName: '一般の部',
                  tournamentId: 't1',
                  sanitizedQuery: '',
                  matchedMatchIds: const {},
                  matchedGroupNames: const {},
                  ownTeams: const ['A道場'],
                  comments: const [],
                  isReadOnlyUI: false,
                  canManageTournamentUI: true,
                  isDark: false,
                  permissions: const PermissionState(
                    isReadOnly: false,
                    canManageTournament: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('A道場'), findsOneWidget);
    });

    testWidgets('公式アナウンスシートにおいて、ダイヤルPickerおよびクイックチップが正常に表示・操作できること', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () {
                      TimelineUnifiedAnnounceDialog.show(
                        context,
                        ref,
                        't1',
                        '小学生の部',
                        '道上剣友会',
                        100.0,
                      );
                    },
                    child: const Text('アナウンスを開く'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ダイアログを開く
      await tester.tap(find.text('アナウンスを開く'));
      await tester.pumpAndSettle();

      // 1. ヘッダーおよびカテゴリタブが表示されていること
      expect(find.text('公式アナウンス・コメントの一斉発信'), findsOneWidget);
      expect(find.text('☕ 進行・休憩'), findsOneWidget);
      expect(find.text('⚖️ 審判・役員'), findsOneWidget);
      expect(find.text('📍 会場・移動'), findsOneWidget);
      expect(find.text('📢 呼出・緊急'), findsOneWidget);
      expect(find.text('🏆 回戦・ラウンド'), findsOneWidget);

      // 2. 「☕ 進行・休憩」カテゴリタブをタップしてアコーディオンを開く
      await tester.tap(find.text('☕ 進行・休憩'));
      await tester.pumpAndSettle();

      // 進行・休憩のチップが表示されていること
      expect(find.text('昼休憩'), findsOneWidget);
      expect(find.text('小休止'), findsOneWidget);

      // 3. チップ「昼休憩」をタップするとタイトルに【昼休憩】が反映され、本文が自動補完されること
      await tester.tap(find.text('昼休憩'));
      await tester.pumpAndSettle();
      expect(find.text('【昼休憩】'), findsOneWidget);
      expect(find.text('昼休憩に入ります。'), findsOneWidget);

      // 4. Undoボタンが表示され、タップすると取り消されること
      expect(
        find.byKey(const Key('timeline_title_undo_button')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('timeline_title_undo_button')));
      await tester.pumpAndSettle();

      // 5. 変更先展開ボタン（＋ 変更先（➔）を指定）を押すと変更先スロットが展開されること
      expect(
        find.byKey(const Key('timeline_toggle_destination_button')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('timeline_toggle_destination_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('【変更元】'), findsOneWidget);
      expect(find.text('【変更先】'), findsOneWidget);
      expect(find.text('変更先を取り消す'), findsOneWidget);

      // 6. ダイヤルPickerの「＋」アイコンをタップすると本文に試合場がリアルタイム反映されること
      // MatchCourtSlotPickerの「＋」アイコンをタップ
      final plusIcons = find.byIcon(Icons.add);
      if (plusIcons.evaluate().isNotEmpty) {
        await tester.tap(plusIcons.first);
        await tester.pumpAndSettle();
        // 本文に第1試合場が入ること
        expect(find.textContaining('第1試合場'), findsWidgets);

        // もう一度タップしても重複せず数字が更新されること（第2試合場）
        await tester.tap(plusIcons.first);
        await tester.pumpAndSettle();
        expect(find.textContaining('第2試合場'), findsWidgets);
      }
    });
  });
}
