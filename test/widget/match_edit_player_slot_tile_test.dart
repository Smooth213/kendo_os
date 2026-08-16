import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_player_slot_tile.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ MatchEditPlayerSlotTile Widget Tests', () {
    testWidgets(
      'Renders position label, red and white player fields with text',
      (WidgetTester tester) async {
        final redController = TextEditingController(text: '山田 太郎');
        final whiteController = TextEditingController(text: '佐藤 次郎');
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [themeColors]),
            home: Scaffold(
              body: MatchEditPlayerSlotTile(
                posLabel: '先鋒',
                redController: redController,
                whiteController: whiteController,
                primaryAccent: Colors.blue,
                isDark: false,
                textColor: Colors.black,
              ),
            ),
          ),
        );

        expect(find.text('先鋒'), findsOneWidget);
        expect(find.text('山田 太郎'), findsOneWidget);
        expect(find.text('佐藤 次郎'), findsOneWidget);
        expect(find.text('vs'), findsOneWidget);

        await tester.enterText(find.byType(TextField).first, '山田 三郎');
        expect(redController.text, '山田 三郎');
      },
    );

    testWidgets(
      'Renders in dark mode with styled backgrounds without assertion errors',
      (WidgetTester tester) async {
        final redController = TextEditingController();
        final whiteController = TextEditingController();
        final themeColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: Brightness.dark,
              extensions: [themeColors],
            ),
            home: Scaffold(
              body: MatchEditPlayerSlotTile(
                posLabel: '中堅',
                redController: redController,
                whiteController: whiteController,
                primaryAccent: Colors.purple,
                isDark: true,
                textColor: Colors.white,
              ),
            ),
          ),
        );

        expect(find.text('中堅'), findsOneWidget);
        expect(find.text('赤 選手名'), findsOneWidget);
        expect(find.text('白 選手名'), findsOneWidget);
      },
    );
  });
}
