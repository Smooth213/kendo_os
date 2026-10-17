import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_search_app_bar_actions.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_search_app_bar_title.dart';

void main() {
  group('[Widget] マニュアルAppBar（タイトル・検索入力・アクション）統合ウィジェットテスト', () {
    testWidgets('通常表示において タイトルと検索開始アイコンが正しく描画され検索開始できること', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      bool searchStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: ManualSearchAppBarTitle(
                isSearching: false,
                searchController: controller,
                onSearchChanged: (_) {},
              ),
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

      // 通常タイトルの表示と検索入力の非表示を確認
      expect(find.text('ヘルプ・マニュアル'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.search), findsOneWidget);

      // 検索開始アイコンタップ
      await tester.tap(find.byIcon(Icons.search));
      expect(searchStarted, isTrue);
    });

    testWidgets('検索モードにおいて 検索入力とナビゲーション・クリアボタンが正しく連動すること', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      String changedText = '';
      bool prevPressed = false;
      bool nextPressed = false;
      bool clearPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: ManualSearchAppBarTitle(
                isSearching: true,
                searchController: controller,
                onSearchChanged: (val) => changedText = val,
              ),
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

      // 通常タイトルは非表示、TextFieldが表示
      expect(find.text('ヘルプ・マニュアル'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);

      // テキスト入力
      await tester.enterText(find.byType(TextField), 'キーワード');
      expect(changedText, 'キーワード');

      // ナビゲーションおよびクリアボタン
      expect(find.byIcon(Icons.navigate_before), findsOneWidget);
      expect(find.byIcon(Icons.navigate_next), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.navigate_before));
      expect(prevPressed, isTrue);

      await tester.tap(find.byIcon(Icons.navigate_next));
      expect(nextPressed, isTrue);

      await tester.tap(find.byIcon(Icons.close));
      expect(clearPressed, isTrue);
    });
  });
}
