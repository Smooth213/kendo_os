import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_court_and_group_tab.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ MatchEditCourtAndGroupTab Widget Tests', () {
    late TextEditingController courtController;
    late TextEditingController noteController;
    late AppThemeColors themeColors;

    setUp(() {
      courtController = TextEditingController(text: '第1試合場, 1回戦');
      noteController = TextEditingController(text: '注意事項テスト');
      themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    });

    tearDown(() {
      courtController.dispose();
      noteController.dispose();
    });

    testWidgets('Renders court and round preset chips and triggers selection', (
      tester,
    ) async {
      String toggledPreset = '';
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchEditCourtAndGroupTab(
              themeColors: themeColors,
              courtController: courtController,
              noteController: noteController,
              isDark: false,
              textColor: Colors.black87,
              onToggleHeadingPreset: (preset) {
                toggledPreset = preset;
              },
              onClearCourt: () {
                cleared = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('試合場・進行見出しの一括設定'), findsOneWidget);
      expect(find.text('第1試合場'), findsOneWidget);
      expect(find.text('1回戦'), findsOneWidget);
      expect(find.text('決勝戦'), findsOneWidget);

      await tester.tap(find.text('決勝戦'));
      await tester.pump();
      expect(toggledPreset, '決勝戦');

      await tester.tap(find.text('クリア'));
      await tester.pump();
      expect(cleared, isTrue);
    });

    testWidgets('Tapping comma chip and comma button inserts comma correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchEditCourtAndGroupTab(
              themeColors: themeColors,
              courtController: courtController,
              noteController: noteController,
              isDark: false,
              textColor: Colors.black87,
              onToggleHeadingPreset: (_) {},
              onClearCourt: () {},
            ),
          ),
        ),
      );

      // カンマチップが見つかること
      expect(find.text('， (カンマ)'), findsOneWidget);
      // メモ横のカンマ追加ボタンが見つかること
      expect(find.text('カンマ（,）'), findsOneWidget);

      // カンマチップをタップして見出しにカンマが入ることを確認
      await tester.tap(find.text('， (カンマ)'));
      await tester.pump();
      expect(courtController.text, '第1試合場, 1回戦, ');

      // カンマボタンをタップしてメモにカンマが入ることを確認
      await tester.tap(find.text('カンマ（,）'));
      await tester.pump();
      expect(noteController.text, '注意事項テスト, ');
    });
  });
}
