import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/presentation/operate/providers/bunaiksen_provider.dart';
import 'package:kendo_os/presentation/operate/providers/settings_provider.dart';
import 'package:kendo_os/presentation/operate/screens/bunaiksen_official_record_screen.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/presentation/operate/providers/match_view_model_provider.dart';
import 'package:kendo_os/domain/entities/settings_model.dart';
import 'package:go_router/go_router.dart';

// モック用のSettingsNotifier
class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() => const SettingsModel(securityLevel: 1);
}

// Mock MatchModel creator
MatchModel createMockMatch({
  String id = 'm1',
  String tournamentId = 'bunaiksen_20250101',
  String category = '一般',
  String groupName = '団体戦A',
  String redName = 'チームA:先鋒',
  String whiteName = 'チームB:先鋒',
  int redScore = 0,
  int whiteScore = 0,
  String matchType = '先鋒',
  String status = 'finished',
  String note = '',
  double order = 1.0,
  MatchRule? rule,
}) {
  return MatchModel(
    id: id,
    tournamentId: tournamentId,
    category: category,
    groupName: groupName,
    redName: redName,
    whiteName: whiteName,
    redScore: redScore,
    whiteScore: whiteScore,
    matchType: matchType,
    status: status,
    order: order,
    note: note,
    events: const [],
    rule: rule ?? const MatchRule(),
  );
}

void main() {
  final testDate = DateTime(2025, 1, 1);
  final testTournamentId = 'bunaiksen_${DateFormat('yyyyMMdd').format(testDate)}';

  testWidgets('BunaiksenOfficialRecordScreen team score table should display "赤" and "白"', (WidgetTester tester) async {
    final matches = [
      createMockMatch(
        redName: 'チームRed:選手1',
        whiteName: 'チームWhite:選手1',
      ),
    ];

    final categoryGroups = {
      '一般': {
        '団体戦A': matches,
      }
    };

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const BunaiksenOfficialRecordScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bunaiksenViewDateProvider.overrideWith((ref) => testDate),
          bunaiksenRecordCategoryGroupsProvider(testTournamentId).overrideWith((ref) => categoryGroups),
          settingsProvider.overrideWith(() => MockSettingsNotifier()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    // Wait for providers to load
    await tester.pumpAndSettle();

    // Find the score table
    expect(find.byType(Table), findsOneWidget);

    // Check for "赤" and "白" labels
    expect(find.text('赤'), findsOneWidget);
    expect(find.text('白'), findsOneWidget);

    // Ensure team names are NOT used as row labels
    expect(find.text('チームRed'), findsNothing);
    expect(find.text('チームWhite'), findsNothing);
  });

  testWidgets('BunaiksenOfficialRecordScreen league table should use BunaiksenHelper for points', (WidgetTester tester) async {
    final matches = [
      createMockMatch(
        id: 'm1',
        redName: '選手A',
        whiteName: '選手B',
        redScore: 1,
        whiteScore: 0,
        note: '[リーグ戦]',
        matchType: 'individual',
        groupName: '個人リーグ',
        rule: const MatchRule(isLeague: true, winPoint: 3, drawPoint: 1, lossPoint: 0),
      ),
      createMockMatch(
        id: 'm2',
        redName: '選手A',
        whiteName: '選手C',
        redScore: 0,
        whiteScore: 0,
        note: '[リーグ戦]',
        matchType: 'individual',
        groupName: '個人リーグ',
        rule: const MatchRule(isLeague: true, winPoint: 3, drawPoint: 1, lossPoint: 0),
      ),
      createMockMatch(
        id: 'm3',
        redName: '選手B',
        whiteName: '選手C',
        redScore: 2,
        whiteScore: 0,
        note: '[リーグ戦]',
        matchType: 'individual',
        groupName: '個人リーグ',
        rule: const MatchRule(isLeague: true, winPoint: 3, drawPoint: 1, lossPoint: 0),
      ),
    ];

    final categoryGroups = {
      '一般': {
        '個人リーグ': matches,
      }
    };

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const BunaiksenOfficialRecordScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bunaiksenViewDateProvider.overrideWith((ref) => testDate),
          bunaiksenRecordCategoryGroupsProvider(testTournamentId).overrideWith((ref) => categoryGroups),
          settingsProvider.overrideWith(() => MockSettingsNotifier()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Player A: 1 win, 1 draw -> custom points = 3 + 1 = 4
    // Player B: 1 win, 1 loss -> custom points = 3 + 0 = 3
    // Player C: 1 draw, 1 loss -> custom points = 1 + 0 = 1

    final tableWidget = tester.widget<Table>(find.byType(Table).first);
    final playerARowWidget = tableWidget.children[1];
    expect(((playerARowWidget.children[playerARowWidget.children.length - 2] as Container).child as Text).data, '4');

    final playerBRowWidget = tableWidget.children[2];
    expect(((playerBRowWidget.children[playerBRowWidget.children.length - 2] as Container).child as Text).data, '3');

    final playerCRowWidget = tableWidget.children[3];
    expect(((playerCRowWidget.children[playerCRowWidget.children.length - 2] as Container).child as Text).data, '1');
  });

  testWidgets('BunaiksenOfficialRecordScreen should display empty cell for "欠員"', (WidgetTester tester) async {
    final matches = [
      createMockMatch(
        redName: 'チームA:山田太郎',
        whiteName: 'チームB:(欠員)',
        matchType: '先鋒',
      ),
    ];

    final categoryGroups = {
      '一般': {
        '団体戦A': matches,
      }
    };

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const BunaiksenOfficialRecordScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bunaiksenViewDateProvider.overrideWith((ref) => testDate),
          bunaiksenRecordCategoryGroupsProvider(testTournamentId).overrideWith((ref) => categoryGroups),
          settingsProvider.overrideWith(() => MockSettingsNotifier()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final tableWidget = tester.widget<Table>(find.byType(Table).first);
    final whiteNameRow = tableWidget.children[3]; // 0:header, 1:red names, 2:scores, 3:white names
    final nameCellWidget = whiteNameRow.children[1] as Container;

    // It should be an empty container, not a widget with text "(欠員)"
    expect(nameCellWidget.child, isNull);
    expect(find.text('(欠員)'), findsNothing);
  });

  testWidgets('BunaiksenOfficialRecordScreen should display initial for same last names', (WidgetTester tester) async {
    final matches = [
      createMockMatch(
        id: 'm1',
        order: 1,
        matchType: '先鋒',
        redName: 'チームA:山田 太郎',
        whiteName: 'チームB:佐藤 一',
      ),
      createMockMatch(
        id: 'm2',
        order: 2,
        matchType: '次鋒',
        redName: 'チームA:山田 花子',
        whiteName: 'チームB:鈴木 二',
      ),
    ];

    final categoryGroups = {
      '一般': {
        '団体戦A': matches,
      }
    };

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const BunaiksenOfficialRecordScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bunaiksenViewDateProvider.overrideWith((ref) => testDate),
          bunaiksenRecordCategoryGroupsProvider(testTournamentId).overrideWith((ref) => categoryGroups),
          settingsProvider.overrideWith(() => MockSettingsNotifier()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final initialTaroFinder = find.text('太');
    expect(initialTaroFinder, findsOneWidget);
    final rowTaroFinder = find.ancestor(of: initialTaroFinder, matching: find.byType(Row));
    expect(find.descendant(of: rowTaroFinder, matching: find.text('山')), findsOneWidget);
    expect(find.descendant(of: rowTaroFinder, matching: find.text('田')), findsOneWidget);

    final initialHanakoFinder = find.text('花');
    expect(initialHanakoFinder, findsOneWidget);
    final rowHanakoFinder = find.ancestor(of: initialHanakoFinder, matching: find.byType(Row));
    expect(find.descendant(of: rowHanakoFinder, matching: find.text('山')), findsOneWidget);
    expect(find.descendant(of: rowHanakoFinder, matching: find.text('田')), findsOneWidget);

    expect(find.text('一'), findsNothing);
    expect(find.text('二'), findsNothing);
  });
}