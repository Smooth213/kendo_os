import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/new_match/new_match_heading_notes_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] NewMatchHeadingNotesCard ウィジェットテスト', () {
    testWidgets('見出しプリセットが表示されトグルおよびクリアが正しく動作すること', (
      WidgetTester tester,
    ) async {
      final courtController = TextEditingController();
      final noteController = TextEditingController();
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return NewMatchHeadingNotesCard(
                  courtController: courtController,
                  noteController: noteController,
                  isDark: false,
                  onClearCourt: () {
                    setState(() {
                      courtController.clear();
                    });
                  },
                  onHeadingPresetToggled: (preset) {
                    setState(() {
                      courtController.text = preset;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('試合場・進行見出しの設定'), findsOneWidget);
      expect(find.text('試合場'), findsOneWidget);
      expect(find.text('試合順'), findsOneWidget);
      expect(find.text('準決勝'), findsOneWidget);

      // 「準決勝」をタップ
      await tester.tap(find.text('準決勝'));
      await tester.pumpAndSettle();

      expect(courtController.text, contains('準決勝'));
      expect(find.text('クリア'), findsOneWidget);

      // 「クリア」をタップ
      await tester.tap(find.text('クリア'));
      await tester.pumpAndSettle();

      expect(courtController.text, '');

      // 運営メモのアコーディオン展開と動作確認
      expect(find.textContaining('運営メモ・特記事項'), findsOneWidget);
      await tester.tap(find.textContaining('運営メモ・特記事項'));
      await tester.pumpAndSettle();

      // TextField が表示されること
      expect(find.byType(TextField), findsWidgets);
    });
  });
}
