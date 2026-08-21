import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_matchup_config_section.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  testWidgets(
    'OrderSetupMatchupConfigSection renders red/white options and opponent input',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: '相手剣道クラブ');
      final focusNode = FocusNode();
      bool isRed = true;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OrderSetupMatchupConfigSection(
                  themeColors: AppThemeColors.ofMode(
                    isDark: false,
                    mode: 'normal',
                  ),
                  isOwnTeamRed: isRed,
                  onIsOwnTeamRedChanged: (val) => isRed = val,
                  opponentTeamController: controller,
                  opponentTeamFocusNode: focusNode,
                  opponentTeamSuggestions: const ['相手剣道クラブ', 'ライバル高校'],
                  isDark: false,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('自チームの紅白（タスキ）'), findsOneWidget);
      expect(find.text('赤 (左側)'), findsOneWidget);
      expect(find.text('白 (右側)'), findsOneWidget);
      expect(find.text('相手チームの情報を入力'), findsOneWidget);
      expect(find.text('相手剣道クラブ'), findsOneWidget);
    },
  );
}
