import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/presentation/operate/providers/bunaiksen_provider.dart';
import 'package:kendo_os/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/presentation/operate/screens/bunaiksen_official_record_screen.dart';
import 'package:kendo_os/presentation/operate/screens/home_screen.dart' show customTeamNamesProvider;

void main() {
  group('部内戦 成績一覧 UIの表示テスト (Widget Test)', () {
    final mockDate = DateTime(2026, 4, 29);

    Widget createTestableWidget(List<MatchModel> mockMatches) {
      return ProviderScope(
        overrides: [
          bunaiksenViewDateProvider.overrideWith((ref) => mockDate),
          matchListProvider.overrideWith((ref) => mockMatches),
          customTeamNamesProvider.overrideWith((ref) => Stream.value(<String>[])),
        ],
        child: const MaterialApp(
          home: BunaiksenOfficialRecordScreen(),
        ),
      );
    }

    testWidgets('団体戦の場合、チーム名が「赤」「白」に固定されていること', (WidgetTester tester) async {
      final mockMatches = [
        const MatchModel(
          id: 'm1',
          tournamentId: 'bunaiksen_20260429',
          matchType: '先鋒',
          groupName: 'group1',
          redName: 'Aチーム: 剣道太郎',
          whiteName: 'Bチーム: 剣道次郎',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          note: '団体戦',
        )
      ];

      await tester.pumpWidget(createTestableWidget(mockMatches));
      await tester.pumpAndSettle();

      expect(find.text('赤'), findsWidgets);
      expect(find.text('白'), findsWidgets);
      expect(find.text('Aチーム'), findsNothing);
    });

    testWidgets('個人戦の場合、選手名が表示されること', (WidgetTester tester) async {
      final mockIndividualMatch = [
        const MatchModel(
          id: 'm2',
          tournamentId: 'bunaiksen_20260429',
          matchType: '個人戦',
          groupName: 'group2',
          redName: '道場A: 剣道太郎',
          whiteName: '道場B: 剣道花子',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          note: '個人戦',
        )
      ];

      await tester.pumpWidget(createTestableWidget(mockIndividualMatch));
      await tester.pumpAndSettle();

      expect(find.textContaining('剣道太郎'), findsWidgets);
      expect(find.textContaining('剣道花子'), findsWidgets);
    });

    testWidgets('引き分けの場合、スコアに✕が表示されること', (WidgetTester tester) async {
      final mockDrawMatch = [
        const MatchModel(
          id: 'm3',
          tournamentId: 'bunaiksen_20260429',
          matchType: '個人戦',
          groupName: 'group3',
          redName: '赤選手',
          whiteName: '白選手',
          redScore: 1,
          whiteScore: 1,
          status: 'finished',
          note: '個人戦',
        )
      ];
      
      await tester.pumpWidget(createTestableWidget(mockDrawMatch));
      await tester.pumpAndSettle();

      final xTextFinder = find.text('✕');
      expect(xTextFinder, findsWidgets);
    });
  });
}