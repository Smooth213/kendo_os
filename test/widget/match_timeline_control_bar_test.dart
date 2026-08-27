import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_control_bar.dart';

void main() {
  group('🛡️ MatchTimelineControlBar Widget Tests', () {
    testWidgets('Renders search and sort buttons when search is not visible', (
      tester,
    ) async {
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
