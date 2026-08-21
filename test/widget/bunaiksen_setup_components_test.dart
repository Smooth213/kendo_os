import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_rule_settings_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_setup_screen.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/smart_player_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeBunaiksenGuestNotifier extends StateNotifier<List<String>>
    implements BunaiksenGuestNotifier {
  FakeBunaiksenGuestNotifier() : super([]);

  @override
  Future<void> addGuest(String name) async {
    state = [...state, name];
  }

  @override
  void update(List<String> Function(List<String> p1) fn) {
    state = fn(state);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ Bunaiksen Setup Extracted Components Tests', () {
    testWidgets('1. BunaiksenRuleSettingsCard renders expansion tile', (
      tester,
    ) async {
      final rule = MatchRule(matchTimeMinutes: 2.0, isIpponShobu: false);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BunaiksenRuleSettingsCard(
                  rule: rule,
                  isDark: false,
                  themeColors: AppThemeColors.ofMode(
                    isDark: false,
                    mode: 'normal',
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('部内戦ルール設定'), findsOneWidget);
    });

    testWidgets('2. BunaiksenSetupScreen renders properly with all tabs', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            bunaiksenPlayerMasterProvider.overrideWith(
              (ref) => Stream<List<PlayerModel>>.value([]),
            ),
            bunaiksenGuestProvider.overrideWith(
              (ref) => FakeBunaiksenGuestNotifier(),
            ),
          ],
          child: const MaterialApp(home: BunaiksenSetupScreen()),
        ),
      );

      expect(find.text('部内戦セットアップ'), findsOneWidget);
      expect(find.text('個人戦 (即スタート)'), findsOneWidget);
      expect(find.text('団体戦 (紅白戦)'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
      expect(find.text('試合開始'), findsOneWidget);
    });
  });
}
