import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_markdown_view.dart';

void main() {
  group('[Widget] ManualMarkdownView ウィジェットテスト', () {
    testWidgets('Renders markdown content correctlyであること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManualMarkdownView(
              markdownContent: '# テスト見出し\n\nこれはテスト本文です。',
              currentFilePath: 'manuals/quickstart/index.md',
              isLoading: false,
              onLinkTapped: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('テスト見出し'), findsOneWidget);
      expect(find.text('これはテスト本文です。'), findsOneWidget);
    });

    testWidgets('【isLoading is true】読み込み中 indicatorが正しく描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManualMarkdownView(
              markdownContent: '',
              currentFilePath: 'manuals/quickstart/index.md',
              isLoading: true,
              onLinkTapped: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
