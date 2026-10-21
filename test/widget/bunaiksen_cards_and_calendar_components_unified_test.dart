import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_individual_matches_list.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_leaderboard_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_rule_settings_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_setup_screen.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/smart_player_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockStreakNotifier extends BunaiksenInfiniteStreakNotifier {
  _MockStreakNotifier(Map<String, int> initial) {
    state = initial;
  }
}

class _FakeBunaiksenGuestNotifier extends StateNotifier<List<String>>
    implements BunaiksenGuestNotifier {
  _FakeBunaiksenGuestNotifier() : super([]);

  @override
  Future<void> addGuest(String name) async {
    state = [...state, name];
  }

  @override
  void update(List<String> Function(List<String> p1) fn) {
    state = fn(state);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] 部内戦 カレンダー・一覧・カード・セットアップ統合検証テスト', () {
    testWidgets('部内戦カレンダーピッカーで初期日付が選択可能範囲外でもクラッシュしないこと', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final viewDate = DateTime(2026, 6, 22);
      final Set<String> availableDates = {};

      final container = ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          bunaiksenViewDateProvider.overrideWith((ref) => viewDate),
          bunaiksenAvailableDatesProvider.overrideWith(
            (ref) => Stream.value(availableDates),
          ),
          bunaiksenMatchesProvider(
            'bunaiksen_20260622',
          ).overrideWithValue(<MatchModel>[]),
          currentDojoIdProvider.overrideWith((ref) => 'test203'),
        ],
        child: const MaterialApp(home: BunaiksenHomeScreen()),
      );

      await tester.pumpWidget(container);
      await tester.pumpAndSettle();

      final calendarFinder = find.byTooltip('日付選択');
      expect(calendarFinder, findsOneWidget);

      await tester.tap(calendarFinder);
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('BunaiksenHomeScreenにおいて 初期状態で本日の日付および「今日の部内戦」が表示されること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final today = DateTime.now();
      final yyyy = today.year.toString();
      final mm = today.month.toString().padLeft(2, '0');
      final dd = today.day.toString().padLeft(2, '0');
      final todayDateId = 'bunaiksen_$yyyy$mm$dd';

      final container = ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          bunaiksenAvailableDatesProvider.overrideWith(
            (ref) => Stream.value(<String>{}),
          ),
          bunaiksenMatchesProvider(
            todayDateId,
          ).overrideWithValue(<MatchModel>[]),
          currentDojoIdProvider.overrideWith((ref) => 'test203'),
        ],
        child: const MaterialApp(home: BunaiksenHomeScreen()),
      );

      await tester.pumpWidget(container);
      await tester.pumpAndSettle();

      final WidgetRef ref =
          tester.element(find.byType(BunaiksenHomeScreen)) as WidgetRef;
      final viewDate = ref.read(bunaiksenViewDateProvider);

      expect(viewDate.year, equals(today.year));
      expect(viewDate.month, equals(today.month));
      expect(viewDate.day, equals(today.day));

      final expectedTitle = '$yyyy/$mm/$dd 部内戦';
      expect(find.text(expectedTitle), findsOneWidget);
      expect(find.text('本日の試合はまだありません'), findsOneWidget);
    });

    testWidgets('BunaiksenIndividualMatchesListにおいて 選手名および試合行が正しく描画されること', (
      tester,
    ) async {
      final matches = [
        MatchModel(
          id: 'm1',
          tournamentId: 't1',
          matchType: 'individual',
          redName: '先鋒: 山田 太郎',
          whiteName: '先鋒: 佐藤 次郎',
          status: 'finished',
          redScore: 2,
          whiteScore: 0,
          order: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BunaiksenIndividualMatchesList(
              groupName: 'Aパート',
              matches: matches,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.textContaining('【個人戦】'), findsOneWidget);
      expect(find.textContaining('山田 太郎'), findsOneWidget);
      expect(find.textContaining('佐藤 次郎'), findsOneWidget);
    });

    testWidgets('BunaiksenLeaderboardCardにおいて 連勝記録が正しく描画されること', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bunaiksenInfiniteStreakProvider.overrideWith(
              (ref) => _MockStreakNotifier({'佐々木選手': 5, '宮本選手': 3}),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: const Scaffold(body: BunaiksenLeaderboardCard()),
          ),
        ),
      );

      expect(find.text('佐々木選手'), findsOneWidget);
      expect(find.text('5 連勝'), findsOneWidget);
      expect(find.text('宮本選手'), findsOneWidget);
      expect(find.text('3 連勝'), findsOneWidget);
    });

    testWidgets('BunaiksenRuleSettingsCardが正しく描画されること', (tester) async {
      final rule = MatchRule(matchTimeMinutes: 2.0, isIpponShobu: false);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BunaiksenRuleSettingsCard(
                  rule: rule,
                  isDark: false,
                  themeColors: AppThemeColors.ofMode(
                    isDark: false,
                    mode: 'normal',
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('部内戦ルール設定'), findsOneWidget);
    });

    testWidgets('BunaiksenSetupScreenにおいて 全タブとともに適切に描画されること', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            bunaiksenPlayerMasterProvider.overrideWith(
              (ref) => Stream<List<PlayerModel>>.value([]),
            ),
            bunaiksenGuestProvider.overrideWith(
              (ref) => _FakeBunaiksenGuestNotifier(),
            ),
          ],
          child: const MaterialApp(home: BunaiksenSetupScreen()),
        ),
      );

      expect(find.text('部内戦セットアップ'), findsOneWidget);
      expect(find.text('個人戦 (即スタート)'), findsOneWidget);
      expect(find.text('団体戦 (紅白戦)'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
      expect(find.text('試合開始'), findsOneWidget);
    });
  });
}
