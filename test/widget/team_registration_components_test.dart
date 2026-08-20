import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_app_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_autocomplete_field.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_dynamic_header.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ TeamRegistration Components Widget Tests', () {
    testWidgets(
      'TeamRegistrationAppBar renders back button and manual button',
      (tester) async {
        bool backPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TeamRegistrationAppBar(onBack: () => backPressed = true),
            ),
          ),
        );

        expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
        expect(backPressed, isTrue);
      },
    );

    testWidgets(
      'TeamRegistrationDynamicHeader renders header title and progress',
      (tester) async {
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TeamRegistrationDynamicHeader(
                currentPage: 0,
                themeColors: themeColors,
              ),
            ),
          ),
        );

        expect(find.text('チームとオーダー登録'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'TeamRegistrationAutocompleteField renders text field with suggestions',
      (tester) async {
        final controller = TextEditingController();
        final focusNode = FocusNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TeamRegistrationAutocompleteField(
                controller: controller,
                focusNode: focusNode,
                suggestions: const ['赤チーム', '白チーム'],
                labelText: 'チーム名',
                hintText: 'チーム名を入力',
                fillColor: Colors.white,
                borderColor: Colors.grey,
                textColor: Colors.black,
                subTextColor: Colors.grey,
                isDark: false,
              ),
            ),
          ),
        );

        expect(find.text('チーム名'), findsOneWidget);
        expect(find.byIcon(Icons.shield), findsOneWidget);
      },
    );
  });
}
