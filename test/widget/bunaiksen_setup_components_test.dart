import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_infinite_tab.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_league_tab.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/smart_player_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('🛡️ BunaiksenSetup Components Widget Tests', () {
    testWidgets('BunaiksenInfiniteTab renders queue and start button', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final themeColors = AppThemeColors.ofMode(
        isDark: false,
        mode: 'bunaiksen',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            bunaiksenPlayerMasterProvider.overrideWith(
              (ref) => Stream<List<PlayerModel>>.value([]),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [themeColors]),
            home: Scaffold(
              body: SizedBox(
                height: 600,
                child: BunaiksenInfiniteTab(themeColors: themeColors),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('待機列 (0人)'), findsOneWidget);
      expect(find.text('無限稽古スタート'), findsOneWidget);
    });

    testWidgets(
      'BunaiksenLeagueTab renders multi player selector and create league button',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'bunaiksen',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              bunaiksenPlayerMasterProvider.overrideWith(
                (ref) => Stream<List<PlayerModel>>.value([]),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(extensions: [themeColors]),
              home: Scaffold(
                body: SizedBox(
                  height: 600,
                  child: BunaiksenLeagueTab(themeColors: themeColors),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('選手を追加してください'), findsOneWidget);
        expect(find.text('総当たり対戦表を作成（0人）'), findsOneWidget);
      },
    );
  });
}
