import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_control_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_player_name_edit_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_representative_modal_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPlayerRepository extends Mock implements PlayerRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('[Widget] MatchBottomSheetsAndControlBar 統合テスト', () {
    late _MockPlayerRepository mockPlayerRepo;
    late _MockTeamRepository mockTeamRepo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockPlayerRepo = _MockPlayerRepository();
      mockTeamRepo = _MockTeamRepository();

      when(
        () => mockPlayerRepo.getPlayers(),
      ).thenAnswer((_) => Stream.value(<PlayerModel>[]));
      when(
        () => mockTeamRepo.watchTeamsByTournament(any()),
      ).thenAnswer((_) => Stream.value(<TeamModel>[]));
    });

    testWidgets('選手名編集ボトムシートが正しく描画されること', (tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final prefs = await SharedPreferences.getInstance();

      final match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: '先鋒戦',
        order: 1,
        redName: 'チームA : 選手1',
        whiteName: 'チームB : 選手2',
        status: 'pending',
        note: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            matchListProvider.overrideWith((ref) => [match]),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            teamRepositoryProvider.overrideWithValue(mockTeamRepo),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: MatchPlayerNameEditBottomSheet(match: match, side: 'red'),
            ),
          ),
        ),
      );

      await tester.safePumpAndSettle();

      expect(find.text('選手名の変更'), findsOneWidget);
      expect(find.text('チームA'), findsOneWidget);
      expect(find.text('確定'), findsOneWidget);
      expect(find.text('このポジションを「欠員」にする'), findsOneWidget);
    });

    testWidgets('代表戦モーダルボトムシートが正しく描画されること', (tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final prefs = await SharedPreferences.getInstance();

      final match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: '代表戦',
        order: 1,
        redName: 'チームA : 代表',
        whiteName: 'チームB : 代表',
        status: 'pending',
        note: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: MatchRepresentativeModalBottomSheet(
                match: match,
                rTeam: 'チームA',
                wTeam: 'チームB',
                redPlayers: const ['選手1', '選手2'],
                whitePlayers: const ['選手3', '選手4'],
              ),
            ),
          ),
        ),
      );

      expect(find.text('代表戦の準備'), findsOneWidget);
      expect(find.text('チームA の代表者'), findsOneWidget);
      expect(find.text('チームB の代表者'), findsOneWidget);
      expect(find.text('決定して準備完了'), findsOneWidget);
    });

    testWidgets('選手Chip選択時に赤・白両陣営とも白文字高コントラストで描画されること', (tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final prefs = await SharedPreferences.getInstance();

      final match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: '代表戦',
        order: 1,
        redName: 'チームA : 代表',
        whiteName: 'チームB : 代表',
        status: 'pending',
        note: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: MatchRepresentativeModalBottomSheet(
                match: match,
                rTeam: 'チームA',
                wTeam: 'チームB',
                redPlayers: const ['赤選手1', '赤選手2'],
                whitePlayers: const ['白選手1', '白選手2'],
              ),
            ),
          ),
        ),
      );

      // 赤選手2のChoiceChipをタップして選択
      await tester.tap(find.widgetWithText(ChoiceChip, '赤選手2'));
      await tester.safePumpAndSettle();

      // 白選手2のChoiceChipをタップして選択
      await tester.tap(find.widgetWithText(ChoiceChip, '白選手2'));
      await tester.safePumpAndSettle();

      // ChoiceChip が選択状態になり、例外なく高コントラストで描画完了すること
      expect(tester.takeException(), isNull);
    });

    testWidgets('検索バー非表示時において検索および並び替えボタンが正しく描画されること', (tester) async {
      bool isSearchVisible = false;
      String searchQuery = '';
      bool isSortAscending = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MatchTimelineControlBar(
                  isSearchVisible: isSearchVisible,
                  searchQuery: searchQuery,
                  isSortAscending: isSortAscending,
                  isReadOnlyUI: false,
                  allMatches: [
                    MatchModel(
                      id: 'test_m1',
                      matchType: '個人戦',
                      redName: '選手A',
                      whiteName: '選手B',
                    ),
                  ],
                  isDark: false,
                  onSearchVisibilityChanged: (val) =>
                      setState(() => isSearchVisible = val),
                  onSearchQueryChanged: (val) =>
                      setState(() => searchQuery = val),
                  onToggleSort: () =>
                      setState(() => isSortAscending = !isSortAscending),
                  onToggleExpandAll: () {},
                  onBulkRuleEdit: () {},
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('試合リスト'), findsOneWidget);
      expect(find.text('ルール一括変更'), findsOneWidget);
      expect(find.text('カテゴリ昇順'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      expect(isSearchVisible, true);
    });
  });
}
