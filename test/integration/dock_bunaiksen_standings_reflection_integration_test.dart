import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_standings_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_parent_gesture_detector.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_matches_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences mockPrefs;

  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    if (FloatingDockSheetManager.isOpen) {
      await FloatingDockSheetManager.close(immediate: true);
    }
  });

  group('🥋 【パート6】部内戦ドック ➔ 成績・星取表 ➔ 白星/黒星・勝数ランキング集計描画 完全保証テスト', () {
    testWidgets('部内戦ドック展開 ➔ 成績・星取表タップ ➔ 各選手の勝敗・得本数集計 ＆ 無限勝ち抜き連勝ランキング描画完全保証', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final today = DateTime.now();
      final todayStr = DateFormat('yyyyMMdd').format(today);
      final dateId = 'bunaiksen_$todayStr';

      // テスト用対戦データ作成
      // 選手1 (皿田 唯人): 2勝0敗 (計3本奪取)
      // 選手2 (平岡): 1勝1敗 (計2本奪取)
      // 選手3 (佐藤): 0勝2敗 (計0本奪取)
      final match1 = MatchModel(
        id: 'm1',
        tournamentId: dateId,
        order: 1,
        matchType: '個人戦',
        redName: '皿田 唯人',
        whiteName: '平岡',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
      );

      final match2 = MatchModel(
        id: 'm2',
        tournamentId: dateId,
        order: 2,
        matchType: '個人戦',
        redName: '平岡',
        whiteName: '佐藤',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
      );

      final match3 = MatchModel(
        id: 'm3',
        tournamentId: dateId,
        order: 3,
        matchType: '個人戦',
        redName: '皿田 唯人',
        whiteName: '佐藤',
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
      );

      final testMatches = [match1, match2, match3];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockPrefs),
            currentUserRoleProvider.overrideWithValue(UserRole.admin),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
            bunaiksenAvailableDatesProvider.overrideWith(
              (ref) => Stream.value(<String>{todayStr}),
            ),
            bunaiksenMatchesProvider(dateId).overrideWithValue(testMatches),
            bunaiksenMatchesStreamProvider(
              dateId,
            ).overrideWith((ref) => Stream.value(testMatches)),
          ],
          child: const MaterialApp(home: BunaiksenHomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 1. 部内戦ホーム画面の表示確認
      expect(find.byType(BunaiksenHomeScreen), findsOneWidget);

      // 2. ドック親ボタンをタップして展開
      final dockParent = find.byType(DockParentGestureDetector);
      expect(dockParent, findsOneWidget);
      await tester.tap(dockParent);
      await tester.pumpAndSettle();

      // 3. 成績・星取表アイコンをタップ
      final standingsItem = find.byIcon(Icons.leaderboard_rounded);
      expect(standingsItem, findsWidgets);
      await tester.tap(standingsItem.first);
      await tester.pumpAndSettle();

      // 4. 成績シート（BunaiksenDockStandingsSheet）の表示確認
      expect(find.byType(BunaiksenDockStandingsSheet), findsOneWidget);
      expect(find.text('部内戦成績・リーダーボード'), findsOneWidget);
      expect(find.text('本日の個人勝敗・獲得本数'), findsOneWidget);

      // 5. 各選手の勝敗・得本数の集計描画を完全検証（シート内をスコープ指定して背景カードとの重複を回避）
      final sheetFinder = find.byType(BunaiksenDockStandingsSheet);

      // 皿田 唯人: 2勝 0敗 0分, 3本
      expect(
        find.descendant(of: sheetFinder, matching: find.text('皿田 唯人')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheetFinder, matching: find.text('2勝 0敗 0分')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheetFinder, matching: find.text('3本')),
        findsOneWidget,
      );

      // 平岡: 1勝 1敗 0分, 2本
      expect(
        find.descendant(of: sheetFinder, matching: find.text('平岡')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheetFinder, matching: find.text('1勝 1敗 0分')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheetFinder, matching: find.text('2本')),
        findsOneWidget,
      );

      // 佐藤: 0勝 2敗 0分, 0本
      expect(
        find.descendant(of: sheetFinder, matching: find.text('佐藤')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheetFinder, matching: find.text('0勝 2敗 0分')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheetFinder, matching: find.text('0本')),
        findsOneWidget,
      );

      // 6. シートを閉じる
      await FloatingDockSheetManager.close(immediate: true);
      await tester.pumpAndSettle();
      expect(find.byType(BunaiksenDockStandingsSheet), findsNothing);
    });

    testWidgets('連勝カウンターが存在する場合、勝ち抜き連勝ランキングセクションに連勝バッジが正しく描画される', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
          currentUserRoleProvider.overrideWithValue(UserRole.admin),
          bunaiksenMatchesStreamProvider(
            'bunaiksen_test',
          ).overrideWith((ref) => Stream.value(<MatchModel>[])),
        ],
      );
      addTearDown(container.dispose);

      // 連勝カウンターをセットアップ: 山田選手が4連勝中
      container
          .read(bunaiksenInfiniteStreakProvider.notifier)
          .incrementStreak('山田 太郎');
      container
          .read(bunaiksenInfiniteStreakProvider.notifier)
          .incrementStreak('山田 太郎');
      container
          .read(bunaiksenInfiniteStreakProvider.notifier)
          .incrementStreak('山田 太郎');
      container
          .read(bunaiksenInfiniteStreakProvider.notifier)
          .incrementStreak('山田 太郎');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: BunaiksenDockStandingsSheet(tournamentId: 'bunaiksen_test'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 連勝ランキングヘッダーと選手名、連勝バッジの描画を確認
      expect(find.text('勝ち抜き連勝ランキング'), findsOneWidget);
      expect(find.text('山田 太郎'), findsOneWidget);
      expect(find.text('4 連勝中'), findsOneWidget);
    });
  });
}
