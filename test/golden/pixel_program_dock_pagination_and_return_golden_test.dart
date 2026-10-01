import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_sheet_pagination_bar.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] ドックプログラム ページネーションおよび先頭ページ復帰UI視覚整合性テスト', () {
    Widget buildPaginationTestWidget({
      required int currentPage,
      required int pageCount,
      required bool isDark,
    }) {
      final themeColors = AppThemeColors.ofMode(
        isDark: isDark,
        mode: isDark ? 'dark' : 'normal',
      );

      return MaterialApp(
        theme: isDark
            ? ThemeData.dark().copyWith(extensions: [themeColors])
            : ThemeData.light().copyWith(extensions: [themeColors]),
        home: Scaffold(
          body: Center(
            child: ProgramSheetPaginationBar(
              currentPage: currentPage,
              pageCount: pageCount,
              themeColors: themeColors,
              isDark: isDark,
              onPageChanged: (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('複数ページPDFの閲覧中（中間ページ）において先頭復帰ボタンと前後ナビが正しく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildPaginationTestWidget(currentPage: 5, pageCount: 12, isDark: false),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ProgramSheetPaginationBar), findsOneWidget);
      expect(find.text('5 / 12'), findsOneWidget);
      expect(find.byIcon(Icons.first_page), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('1ページ目表示時において先頭復帰ボタンおよび前ページボタンが無効化スタイルで描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildPaginationTestWidget(currentPage: 1, pageCount: 10, isDark: true),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('1 / 10'), findsOneWidget);
      expect(find.byTooltip('最初のページに戻る'), findsOneWidget);
    });

    testWidgets('単一ページ（1ページのみ）のPDFではページネーションバーが非表示（SizedBox.shrink）となること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPaginationTestWidget(currentPage: 1, pageCount: 1, isDark: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 / 1'), findsNothing);
      expect(find.byIcon(Icons.first_page), findsNothing);
    });
  });
}
