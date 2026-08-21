import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_sticky_bottom_action.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const dummyThemeColors = AppThemeColors(
    primaryAccent: Colors.indigo,
    softAccent: Colors.indigoAccent,
    cardBackground: Colors.white,
    scaffoldBackground: Colors.white,
    textColor: Colors.black,
    subTextColor: Colors.grey,
    separatorColor: Colors.grey,
    inputBackground: Colors.white,
    hintColor: Colors.grey,
    rosePink: Colors.pink,
    successColor: Colors.green,
    warningColor: Colors.orange,
    errorColor: Colors.red,
    infoColor: Colors.blue,
  );

  testWidgets('MatchFormatStickyBottomAction renders page 0 correctly', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: ThemeData(extensions: const [dummyThemeColors]),
          home: Scaffold(
            body: MatchFormatStickyBottomAction(
              currentPage: 0,
              isLastPage: false,
              themeColors: dummyThemeColors,
              onPrevious: () {},
              onNextOrComplete: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GlassButton), findsOneWidget);
    expect(find.text('次へ進む'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
  });

  testWidgets('MatchFormatStickyBottomAction renders last page correctly', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: ThemeData(extensions: const [dummyThemeColors]),
          home: Scaffold(
            body: MatchFormatStickyBottomAction(
              currentPage: 1,
              isLastPage: true,
              themeColors: dummyThemeColors,
              onPrevious: () {},
              onNextOrComplete: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GlassButton), findsOneWidget);
    expect(find.text('このルールで枠を作成'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
  });
}
