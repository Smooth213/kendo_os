import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_search_app_bar_actions.dart';

void main() {
  group('[Widget] ManualSearchAppBarActions ウィジェットテスト', () {
    testWidgets(
      'showSearch is true and isSearching is falseにおいて search iconが正しく描画されること',
      (tester) async {
        bool searchStarted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: [
                  ManualSearchAppBarActions(
                    showSearch: true,
                    isSearching: false,
                    isPdfMode: false,
                    searchQuery: '',
                    onPreviousPressed: () {},
                    onNextPressed: () {},
                    onClearPressed: () {},
                    onStartSearchPressed: () => searchStarted = true,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.search), findsOneWidget);
        await tester.tap(find.byIcon(Icons.search));
        expect(searchStarted, isTrue);
      },
    );

    testWidgets(
      'searching with queryにおいて navigation and clear buttonsが正しく描画されること',
      (tester) async {
        bool prevPressed = false;
        bool nextPressed = false;
        bool clearPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: [
                  ManualSearchAppBarActions(
                    showSearch: true,
                    isSearching: true,
                    isPdfMode: true,
                    searchQuery: 'query',
                    onPreviousPressed: () => prevPressed = true,
                    onNextPressed: () => nextPressed = true,
                    onClearPressed: () => clearPressed = true,
                    onStartSearchPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.navigate_before), findsOneWidget);
        expect(find.byIcon(Icons.navigate_next), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);

        await tester.tap(find.byIcon(Icons.navigate_before));
        expect(prevPressed, isTrue);

        await tester.tap(find.byIcon(Icons.navigate_next));
        expect(nextPressed, isTrue);

        await tester.tap(find.byIcon(Icons.close));
        expect(clearPressed, isTrue);
      },
    );
  });
}
