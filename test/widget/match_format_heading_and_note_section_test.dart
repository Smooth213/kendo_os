import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_heading_and_note_section.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  testWidgets(
    'MatchFormatHeadingAndNoteSection renders preset chips and text fields',
    (tester) async {
      final courtCtrl = TextEditingController(text: '第1試合場');
      final noteCtrl = TextEditingController(text: '特記事項なし');
      String? toggledPreset;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFormatHeadingAndNoteSection(
              themeColors: AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              courtController: courtCtrl,
              noteController: noteCtrl,
              onToggleHeadingPreset: (preset) {
                toggledPreset = preset;
              },
              isDark: false,
              buildTextFieldDecoration:
                  ({
                    required String labelText,
                    required String hintText,
                    Widget? prefixIcon,
                  }) {
                    return InputDecoration(
                      labelText: labelText,
                      hintText: hintText,
                      prefixIcon: prefixIcon,
                    );
                  },
            ),
          ),
        ),
      );

      expect(find.text('試合場・進行見出しの一括設定'), findsOneWidget);
      expect(find.text('第1試合場'), findsWidgets);
      expect(find.text('1回戦'), findsOneWidget);

      await tester.tap(find.text('1回戦'));
      await tester.pump();

      expect(toggledPreset, '1回戦');
    },
  );
}
