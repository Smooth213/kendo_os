import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_matches_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_parent_gesture_detector.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_calendar_sheet.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp({
    required SharedPreferences prefs,
    required Set<String> availableDates,
    required Map<String, List<MatchModel>> matchesByDateId,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUserRoleProvider.overrideWithValue(UserRole.admin),
        currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
        bunaiksenAvailableDatesProvider.overrideWith(
          (ref) => Stream.value(availableDates),
        ),
        // 各日付の試合データをオーバーライド
        for (final entry in matchesByDateId.entries)
          bunaiksenMatchesProvider(entry.key).overrideWithValue(entry.value),
      ],
      child: const MaterialApp(home: BunaiksenHomeScreen()),
    );
  }

  testWidgets('【パート3】部内戦ドック ➔ カレンダー ➔ 試合日アクティブ表示 ➔ 日付ジャンプ ➔ 今日復帰 完全連動保証テスト', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final prefs = await SharedPreferences.getInstance();

    final today = DateTime.now();
    final todayStr = DateFormat('yyyyMMdd').format(today);
    final todayDisplay = DateFormat('yyyy/MM/dd').format(today);
    final todayDateId = 'bunaiksen_$todayStr';

    // 過去の試合日（5日前）
    final pastDate = today.subtract(const Duration(days: 5));
    final pastDateStr = DateFormat('yyyyMMdd').format(pastDate);
    final pastDateDisplay = DateFormat('yyyy/MM/dd').format(pastDate);
    final pastDateId = 'bunaiksen_$pastDateStr';

    final pastMatch = MatchModel(
      id: 'past_match_001',
      tournamentId: pastDateId,
      order: 1,
      matchType: '個人戦',
      redName: '山田 太郎',
      whiteName: '佐藤 次郎',
      status: 'finished',
    );

    final availableDates = <String>{pastDateStr};
    final matchesByDateId = <String, List<MatchModel>>{
      todayDateId: <MatchModel>[],
      pastDateId: <MatchModel>[pastMatch],
    };

    await tester.pumpWidget(
      buildTestApp(
        prefs: prefs,
        availableDates: availableDates,
        matchesByDateId: matchesByDateId,
      ),
    );
    await tester.pumpAndSettle();

    // 1. 初期表示：今日の部内戦
    expect(find.text('$todayDisplay 部内戦'), findsOneWidget);
    expect(find.text('本日の試合はまだありません'), findsOneWidget);

    // 2. 部内戦ドック親ボタンをタップして展開
    final dockButtonFinder = find.byType(DockParentGestureDetector);
    expect(dockButtonFinder, findsOneWidget);
    await tester.tap(dockButtonFinder);
    await tester.pumpAndSettle();

    // 3. カレンダーアイコンをタップ
    final calendarFinder = find.byIcon(Icons.calendar_month_rounded);
    expect(calendarFinder, findsWidgets);
    await tester.tap(calendarFinder.first);
    await tester.pumpAndSettle();

    // 4. BunaiksenDockCalendarSheet が表示されたことを確認
    expect(find.byType(BunaiksenDockCalendarSheet), findsOneWidget);
    expect(find.text('部内戦カレンダー・稽古日'), findsOneWidget);

    // バナーに今日の日付が表示されている
    final todayBannerText = DateFormat('yyyy年MM月dd日 (E)', 'ja').format(today);
    expect(find.text(todayBannerText), findsOneWidget);

    // 5. カレンダー内の過去の試合日をタップしてジャンプ
    // pastDate の日番号のテキスト（例: pastDate.day）を探す
    // CalendarDatePicker 内の該当日のText
    final dayFinder = find.descendant(
      of: find.byType(CalendarDatePicker),
      matching: find.text(pastDate.day.toString()),
    );
    expect(dayFinder, findsWidgets);
    await tester.tap(dayFinder.first);
    await tester.pumpAndSettle();

    // 6. バナーが過去の試合日に更新されたことを確認
    final pastBannerText = DateFormat('yyyy年MM月dd日 (E)', 'ja').format(pastDate);
    expect(find.text(pastBannerText), findsOneWidget);

    // 「今日に戻る」ボタンが出現していることを確認
    expect(find.text('今日に戻る'), findsOneWidget);

    // 7. シートを一度閉じて、部内戦ホーム画面のタイトルと該当日の試合リストの反映を完全検証
    await FloatingDockSheetManager.close(immediate: true);
    await tester.pumpAndSettle();

    // ホーム画面のタイトルが過去日の日付に更新されている
    expect(find.text('$pastDateDisplay 部内戦'), findsOneWidget);
    // 過去日の試合（山田 太郎 vs 佐藤 次郎）がリストに表示されている
    expect(find.text('山田 太郎'), findsOneWidget);
    expect(find.text('佐藤 次郎'), findsOneWidget);

    // 8. 再びドックからカレンダーを開く
    await tester.tap(dockButtonFinder);
    await tester.pumpAndSettle();
    await tester.tap(calendarFinder.first);
    await tester.pumpAndSettle();

    expect(find.byType(BunaiksenDockCalendarSheet), findsOneWidget);
    expect(find.text('今日に戻る'), findsOneWidget);

    // 9. 「今日に戻る」ボタンをタップして今日に復帰
    await tester.tap(find.text('今日に戻る'));
    await tester.pumpAndSettle();

    // 日付が今日に戻ったことを確認
    final BuildContext homeContext = tester.element(
      find.byType(BunaiksenHomeScreen),
    );
    final container = ProviderScope.containerOf(homeContext);
    final restoredViewDate = container.read(bunaiksenViewDateProvider);
    expect(restoredViewDate.year, equals(today.year));
    expect(restoredViewDate.month, equals(today.month));
    expect(restoredViewDate.day, equals(today.day));

    // バナーも今日に戻っている
    expect(find.text(todayBannerText), findsOneWidget);

    // 10. シートを閉じてホーム画面も今日（試合なし）に戻っていることを確認
    await FloatingDockSheetManager.close(immediate: true);
    await tester.pumpAndSettle();

    expect(find.text('$todayDisplay 部内戦'), findsOneWidget);
    expect(find.text('本日の試合はまだありません'), findsOneWidget);
  });
}
