import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_search_app_bar_title.dart';

void main() {
  group('[Widget] ManualSearchAppBarTitle ウィジェットテスト', () {
    testWidgets('【isSearching is false】normal titleが正しく描画されること', (
      tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: ManualSearchAppBarTitle(
                isSearching: false,
                searchController: controller,
                onSearchChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('ヘルプ・マニュアル'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('【isSearching is true】search inputが正しく描画されること', (tester) async {
      final controller = TextEditingController();
      String changedText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: ManualSearchAppBarTitle(
                isSearching: true,
                searchController: controller,
                onSearchChanged: (val) => changedText = val,
              ),
            ),
          ),
        ),
      );

      expect(find.text('ヘルプ・マニュアル'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), '検索キーワード');
      expect(changedText, '検索キーワード');
    });
  });
}
