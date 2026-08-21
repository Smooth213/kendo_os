import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_match_list_search_bar.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  testWidgets(
    'ViewerMatchListSearchBar renders search button and sort button',
    (tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      bool toggledSort = false;
      bool openedSearch = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: ViewerMatchListSearchBar(
              isSearchVisible: false,
              searchQuery: '',
              isSortAscending: true,
              onSearchQueryChanged: (_) {},
              onOpenSearch: () => openedSearch = true,
              onCloseSearch: () {},
              onToggleSort: () => toggledSort = true,
            ),
          ),
        ),
      );

      expect(find.text('試合リスト'), findsOneWidget);
      expect(find.text('カテゴリ昇順'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      await tester.tap(find.text('カテゴリ昇順'));
      await tester.pump();
      expect(toggledSort, isTrue);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      expect(openedSearch, isTrue);
    },
  );
}
