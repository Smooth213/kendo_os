import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/new_match/new_match_heading_notes_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ NewMatchHeadingNotesCard Widget Tests', () {
    testWidgets(
      'Renders heading presets and triggers preset toggle and clear',
      (WidgetTester tester) async {
        final courtController = TextEditingController();
        final noteController = TextEditingController();
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

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
        expect(find.text('第1試合場'), findsOneWidget);
        expect(find.text('準決勝'), findsOneWidget);

        // 「第1試合場」をタップ
        await tester.tap(find.text('第1試合場'));
        await tester.pumpAndSettle();

        expect(courtController.text, '第1試合場');
        expect(find.text('クリア'), findsOneWidget);

        // 「クリア」をタップ
        await tester.tap(find.text('クリア'));
        await tester.pumpAndSettle();

        expect(courtController.text, '');
      },
    );
  });
}
