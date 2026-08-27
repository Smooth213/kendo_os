import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/application/projections/tournament_projection.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'; // for customTeamNamesProvider
import 'package:kendo_os/features/viewer/providers/viewer_view_state_provider.dart';
import 'package:kendo_os/features/viewer/screens/viewer_official_record_screen.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() => const SettingsModel(securityLevel: 1);
}

class MockTournamentProjection implements TournamentProjection {
  @override
  final TournamentModel tournament;
  @override
  final Map<String, TeamMatchProjection> teamMatches;
  @override
  final Map<String, List<String>> categoryToGroupKeys;
  @override
  final List<MatchListProjection> allMatches;

  MockTournamentProjection({
    TournamentModel? tournament,
    required this.teamMatches,
    required this.categoryToGroupKeys,
    this.allMatches = const [],
  }) : tournament =
           tournament ??
           TournamentModel(
             id: 'test-tournament',
             name: 'テスト大会',
             date: DateTime(2025, 1, 1),
             venue: '武道館',
             categories: categoryToGroupKeys.keys.toList(),
             organizationId: 'org_1',
           );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ViewerOfficialRecordScreen should display empty cell for "欠員"', (
    WidgetTester tester,
  ) async {
    final matches = [
      MatchListProjection(
        id: 'm1',
        tournamentId: 'test-tournament',
        groupName: 'groupA',
        redName: 'チームA:山田太郎',
        whiteName: 'チームB:(欠員)',
        redScore: 0,
        whiteScore: 0,
        matchType: '先鋒',
        status: 'finished',
        matchOrder: 1,
        note: '',
        isKachinuki: false,
        firstPointSide: '',
        redPointMarks: const [],
        whitePointMarks: const [],
      ),
    ];

    final teamMatchProjection = TeamMatchProjection(
      groupName: 'groupA',
      redTeamName: 'チームA',
      whiteTeamName: 'チームB',
      matchType: '団体戦',
      note: '',
      matches: matches,
      isKachinuki: false,
      isLeague: false,
      result: TeamMatchResult(
        teamWinner: 'red',
        redWins: 1,
        whiteWins: 0,
        redPoints: 0,
        whitePoints: 0,
        allFinished: true,
        isTie: false,
        hasDaihyo: false,
      ),
      leagueStandings: [],
    );

    final tournamentProjection = MockTournamentProjection(
      teamMatches: {'groupA': teamMatchProjection},
      categoryToGroupKeys: {
        '一般': ['groupA'],
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          viewerTournamentProjectionProvider(
            'test-tournament',
          ).overrideWithValue(AsyncValue.data(tournamentProjection)),
          customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
          settingsProvider.overrideWith(() => MockSettingsNotifier()),
          tournamentProvider(
            'test-tournament',
          ).overrideWith((ref) => Stream.value(null)),
        ],
        child: MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: const ViewerOfficialRecordScreen(
            tournamentId: 'test-tournament',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the table
    final tableWidget = tester.widget<Table>(find.byType(Table).first);
    // Row for white player names
    final whiteNameRow = tableWidget.children[3];

    // The cell for the white player name
    final nameCellWidget = whiteNameRow.children[1] as Container;

    // It should be an empty container, not a widget with text "(欠員)"
    expect(nameCellWidget.child, isNull);
    expect(find.text('(欠員)'), findsNothing);
  });

  testWidgets(
    'ViewerOfficialRecordScreen should display initial for same last names',
    (WidgetTester tester) async {
      final matches = [
        MatchListProjection(
          id: 'm1',
          tournamentId: 'test-tournament',
          groupName: 'groupA',
          redName: 'チームA:山田 太郎',
          whiteName: 'チームB:佐藤 一',
          redScore: 0,
          whiteScore: 0,
          matchType: '先鋒',
          status: 'finished',
          matchOrder: 1,
          note: '',
          isKachinuki: false,
          firstPointSide: '',
          redPointMarks: const [],
          whitePointMarks: const [],
        ),
        MatchListProjection(
          id: 'm2',
          tournamentId: 'test-tournament',
          groupName: 'groupA',
          redName: 'チームA:山田 花子',
          whiteName: 'チームB:鈴木 二',
          redScore: 0,
          whiteScore: 0,
          matchType: '次鋒',
          status: 'finished',
          matchOrder: 2,
          note: '',
          isKachinuki: false,
          firstPointSide: '',
          redPointMarks: const [],
          whitePointMarks: const [],
        ),
      ];

      final teamMatchProjection = TeamMatchProjection(
        groupName: 'groupA',
        redTeamName: 'チームA',
        whiteTeamName: 'チームB',
        matchType: '団体戦',
        note: '',
        matches: matches,
        isKachinuki: false,
        isLeague: false,
        result: TeamMatchResult(
          teamWinner: 'draw',
          redWins: 0,
          whiteWins: 0,
          redPoints: 0,
          whitePoints: 0,
          allFinished: true,
          isTie: true,
          hasDaihyo: false,
        ),
        leagueStandings: [],
      );

      final tournamentProjection = MockTournamentProjection(
        teamMatches: {'groupA': teamMatchProjection},
        categoryToGroupKeys: {
          '一般': ['groupA'],
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            viewerTournamentProjectionProvider(
              'test-tournament',
            ).overrideWithValue(AsyncValue.data(tournamentProjection)),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            tournamentProvider(
              'test-tournament',
            ).overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            home: ViewerOfficialRecordScreen(tournamentId: 'test-tournament'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final initialTaroFinder = find.text('太');
      expect(initialTaroFinder, findsOneWidget);
      final rowTaroFinder = find.ancestor(
        of: initialTaroFinder,
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: rowTaroFinder, matching: find.text('山')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: rowTaroFinder, matching: find.text('田')),
        findsOneWidget,
      );

      final initialHanakoFinder = find.text('花');
      expect(initialHanakoFinder, findsOneWidget);
      final rowHanakoFinder = find.ancestor(
        of: initialHanakoFinder,
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: rowHanakoFinder, matching: find.text('山')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: rowHanakoFinder, matching: find.text('田')),
        findsOneWidget,
      );

      expect(find.text('一'), findsNothing);
      expect(find.text('二'), findsNothing);
    },
  );

  testWidgets(
    'ViewerOfficialRecordScreen should show and hide loading dialog on PDF export',
    (WidgetTester tester) async {
      final matches = [
        MatchListProjection(
          id: 'm1',
          tournamentId: 'test-tournament',
          groupName: 'groupA',
          redName: 'チームA:山田 太郎',
          whiteName: 'チームB:佐藤 一',
          redScore: 0,
          whiteScore: 0,
          matchType: '先鋒',
          status: 'finished',
          matchOrder: 1,
          note: '',
          isKachinuki: false,
          firstPointSide: '',
          redPointMarks: const [],
          whitePointMarks: const [],
        ),
      ];

      final teamMatchProjection = TeamMatchProjection(
        groupName: 'groupA',
        redTeamName: 'チームA',
        whiteTeamName: 'チームB',
        matchType: '団体戦',
        note: '',
        matches: matches,
        isKachinuki: false,
        isLeague: false,
        result: TeamMatchResult(
          teamWinner: 'draw',
          redWins: 0,
          whiteWins: 0,
          redPoints: 0,
          whitePoints: 0,
          allFinished: true,
          isTie: true,
          hasDaihyo: false,
        ),
        leagueStandings: [],
      );

      final tournamentProjection = MockTournamentProjection(
        teamMatches: {'groupA': teamMatchProjection},
        categoryToGroupKeys: {
          '一般': ['groupA'],
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            viewerTournamentProjectionProvider(
              'test-tournament',
            ).overrideWithValue(AsyncValue.data(tournamentProjection)),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            tournamentProvider(
              'test-tournament',
            ).overrideWith((ref) => Stream.value(null)),
          ],
          child: MaterialApp(
            theme: ThemeData(splashFactory: NoSplash.splashFactory),
            home: const ViewerOfficialRecordScreen(
              tournamentId: 'test-tournament',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pdfButton = find.text('PDF印刷').first;
      await tester.tap(pdfButton);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'ViewerOfficialRecordScreen matches should be sorted by matchOrder',
    (WidgetTester tester) async {
      final matches = [
        MatchListProjection(
          id: 'm2',
          tournamentId: 'test-tournament',
          groupName: 'groupA',
          redName: 'チームA:山田花子',
          whiteName: 'チームB:鈴木二',
          redScore: 0,
          whiteScore: 0,
          matchType: '大将',
          status: 'finished',
          matchOrder: 2, // order is larger
          note: '',
          isKachinuki: false,
          firstPointSide: '',
          redPointMarks: const [],
          whitePointMarks: const [],
        ),
        MatchListProjection(
          id: 'm1',
          tournamentId: 'test-tournament',
          groupName: 'groupA',
          redName: 'チームA:山田太郎',
          whiteName: 'チームB:佐藤一',
          redScore: 0,
          whiteScore: 0,
          matchType: '先鋒',
          status: 'finished',
          matchOrder: 1, // order is smaller
          note: '',
          isKachinuki: false,
          firstPointSide: '',
          redPointMarks: const [],
          whitePointMarks: const [],
        ),
      ];

      final teamMatchProjection = TeamMatchProjection(
        groupName: 'groupA',
        redTeamName: 'チームA',
        whiteTeamName: 'チームB',
        matchType: '団体戦',
        note: '',
        matches: matches,
        isKachinuki: false,
        isLeague: false,
        result: TeamMatchResult(
          teamWinner: 'draw',
          redWins: 0,
          whiteWins: 0,
          redPoints: 0,
          whitePoints: 0,
          allFinished: true,
          isTie: true,
          hasDaihyo: false,
        ),
        leagueStandings: [],
      );

      final tournamentProjection = MockTournamentProjection(
        teamMatches: {'groupA': teamMatchProjection},
        categoryToGroupKeys: {
          '一般': ['groupA'],
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            viewerTournamentProjectionProvider(
              'test-tournament',
            ).overrideWithValue(AsyncValue.data(tournamentProjection)),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            tournamentProvider(
              'test-tournament',
            ).overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            home: ViewerOfficialRecordScreen(tournamentId: 'test-tournament'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tableWidget = tester.widget<Table>(find.byType(Table).first);
      final headerRow = tableWidget.children[0];

      final firstMatchText =
          (((headerRow.children[1] as Container).child as Center).child
                      as Padding)
                  .child
              as Text;
      final secondMatchText =
          (((headerRow.children[2] as Container).child as Center).child
                      as Padding)
                  .child
              as Text;

      expect(firstMatchText.data, '先鋒');
      expect(secondMatchText.data, '大将');
    },
  );

  testWidgets(
    'ViewerOfficialRecordScreen should NEVER display "成績サマリー" (観客専用仕様)',
    (WidgetTester tester) async {
      final teamMatchProjection = TeamMatchProjection(
        groupName: 'groupA',
        redTeamName: 'チームA',
        whiteTeamName: 'チームB',
        matchType: '団体戦',
        note: '',
        matches: [
          MatchListProjection(
            id: 'm1',
            tournamentId: 'test-tournament',
            groupName: 'groupA',
            redName: 'チームA:山田太郎',
            whiteName: 'チームB:佐藤二朗',
            redScore: 1,
            whiteScore: 0,
            matchType: '先鋒',
            status: 'finished',
            matchOrder: 1,
            note: '',
            isKachinuki: false,
            firstPointSide: 'red',
            redPointMarks: const ['M'],
            whitePointMarks: const [],
          ),
        ],
        isKachinuki: false,
        isLeague: false,
        result: TeamMatchResult(
          teamWinner: 'red',
          redWins: 1,
          whiteWins: 0,
          redPoints: 1,
          whitePoints: 0,
          allFinished: true,
          isTie: false,
          hasDaihyo: false,
        ),
        leagueStandings: [],
      );

      final tournamentProjection = MockTournamentProjection(
        teamMatches: {'groupA': teamMatchProjection},
        categoryToGroupKeys: {
          '一般': ['groupA'],
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            viewerTournamentProjectionProvider(
              'test-tournament',
            ).overrideWithValue(AsyncValue.data(tournamentProjection)),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            tournamentProvider(
              'test-tournament',
            ).overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            home: ViewerOfficialRecordScreen(tournamentId: 'test-tournament'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 観客用画面に「成績サマリー」が表示されないことを厳密に検証
      expect(find.text('成績サマリー'), findsNothing);
      expect(find.text('遠征・大会 成績サマリー'), findsNothing);
    },
  );

  testWidgets(
    'ViewerOfficialRecordScreen should display category tabs correctly (小学生の部 / 中学生の部 / 一般の部)',
    (WidgetTester tester) async {
      TeamMatchProjection makeTeamMatch(String groupName, String cat) =>
          TeamMatchProjection(
            groupName: groupName,
            redTeamName: '赤チーム',
            whiteTeamName: '白チーム',
            matchType: '団体戦',
            note: '',
            matches: [
              MatchListProjection(
                id: 'm_$groupName',
                tournamentId: 'test-tournament',
                groupName: groupName,
                redName: '赤チーム:選手A',
                whiteName: '白チーム:選手B',
                redScore: 1,
                whiteScore: 0,
                matchType: '先鋒',
                status: 'finished',
                matchOrder: 1,
                note: '',
                isKachinuki: false,
                firstPointSide: 'red',
                redPointMarks: const ['M'],
                whitePointMarks: const [],
              ),
            ],
            isKachinuki: false,
            isLeague: false,
            result: TeamMatchResult(
              teamWinner: 'red',
              redWins: 1,
              whiteWins: 0,
              redPoints: 1,
              whitePoints: 0,
              allFinished: true,
              isTie: false,
              hasDaihyo: false,
            ),
            leagueStandings: [],
          );

      final tournamentProjection = MockTournamentProjection(
        teamMatches: {
          'group_elem': makeTeamMatch('group_elem', '小学生の部'),
          'group_jh': makeTeamMatch('group_jh', '中学生の部'),
          'group_gen': makeTeamMatch('group_gen', '一般の部'),
        },
        categoryToGroupKeys: {
          '小学生の部': ['group_elem'],
          '中学生の部': ['group_jh'],
          '一般の部': ['group_gen'],
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            viewerTournamentProjectionProvider(
              'test-tournament',
            ).overrideWithValue(AsyncValue.data(tournamentProjection)),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            tournamentProvider(
              'test-tournament',
            ).overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            home: ViewerOfficialRecordScreen(tournamentId: 'test-tournament'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 各カテゴリタブが正しく表示されていること
      expect(find.text('小学生の部'), findsOneWidget);
      expect(find.text('中学生の部'), findsOneWidget);
      expect(find.text('一般の部'), findsOneWidget);
      // 「全カテゴリ」固定タブになっていないこと
      expect(find.text('全カテゴリ'), findsNothing);
    },
  );

  testWidgets(
    'ViewerOfficialRecordExportBar maintains visible text and high contrast in Dark Mode (no whiteout)',
    (WidgetTester tester) async {
      TeamMatchProjection makeTeamMatch(String groupName) =>
          TeamMatchProjection(
            groupName: groupName,
            redTeamName: '赤チーム',
            whiteTeamName: '白チーム',
            matchType: '団体戦',
            note: '',
            matches: [
              MatchListProjection(
                id: 'm1',
                tournamentId: 'test-tournament',
                groupName: groupName,
                redName: '赤チーム:選手A',
                whiteName: '白チーム:選手B',
                redScore: 1,
                whiteScore: 0,
                matchType: '先鋒',
                status: 'finished',
                matchOrder: 1,
                note: '',
                isKachinuki: false,
                firstPointSide: 'red',
                redPointMarks: const ['M'],
                whitePointMarks: const [],
              ),
            ],
            isKachinuki: false,
            isLeague: false,
            result: TeamMatchResult(
              teamWinner: 'red',
              redWins: 1,
              whiteWins: 0,
              redPoints: 1,
              whitePoints: 0,
              allFinished: true,
              isTie: false,
              hasDaihyo: false,
            ),
            leagueStandings: [],
          );

      final tournamentProjection = MockTournamentProjection(
        teamMatches: {'groupA': makeTeamMatch('groupA')},
        categoryToGroupKeys: {
          '一般': ['groupA'],
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            viewerTournamentProjectionProvider(
              'test-tournament',
            ).overrideWithValue(AsyncValue.data(tournamentProjection)),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            tournamentProvider(
              'test-tournament',
            ).overrideWith((ref) => Stream.value(null)),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const ViewerOfficialRecordScreen(
              tournamentId: 'test-tournament',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // PDF印刷ボタンと画像シェアボタンのテキストが確実に視認できること
      expect(find.text('PDF印刷'), findsOneWidget);
      expect(find.text('画像シェア'), findsOneWidget);

      final pdfButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('viewer_export_pdf_button')),
      );
      final pdfBg = pdfButton.style?.backgroundColor?.resolve({});
      final pdfFg = pdfButton.style?.foregroundColor?.resolve({});

      // 背景色と文字色が同一（白×白による白潰れ）になっていないこと
      expect(pdfBg, isNotNull);
      expect(pdfFg, isNotNull);
      expect(pdfBg, isNot(equals(pdfFg)));
    },
  );
}
