import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_app.dart';

class FakeBatteryNotifier extends BatteryNotifier {
  final BatteryStateData data;
  FakeBatteryNotifier(this.data);

  @override
  Future<BatteryStateData> build() async => data;
}

class FakeSettingsNotifier extends SettingsNotifier {
  SettingsModel settings;
  FakeSettingsNotifier(this.settings);

  @override
  SettingsModel build() {
    state = settings;
    return settings;
  }

  @override
  Future<void> updateSettings(SettingsModel newSettings) async {
    state = newSettings;
    settings = newSettings;
  }
}

void main() {
  group('🔋 Eco Mode & Battery Auto-Saver Tests', () {
    setUpAll(() async {
      await setupTestFirebase();
    });

    test('Should return isEcoMode=true when enableLiquidGlass is disabled', () {
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(
            () => FakeSettingsNotifier(
              const SettingsModel(enableLiquidGlass: false),
            ),
          ),
          batteryStateProvider.overrideWith(
            () => FakeBatteryNotifier(
              const BatteryStateData(
                batteryLevel: 100,
                isInPowerSaveMode: false,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isEcoModeProvider), isTrue);
    });

    test(
      'Should return isEcoMode=true when battery level is low (<= 20%)',
      () async {
        final container = ProviderContainer(
          overrides: [
            settingsProvider.overrideWith(
              () => FakeSettingsNotifier(
                const SettingsModel(enableLiquidGlass: true),
              ),
            ),
            batteryStateProvider.overrideWith(
              () => FakeBatteryNotifier(
                const BatteryStateData(
                  batteryLevel: 20,
                  isInPowerSaveMode: false,
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Await future resolution for async notifier provider
        await container.read(batteryStateProvider.future);
        expect(container.read(isEcoModeProvider), isTrue);
      },
    );

    test(
      'Should return isEcoMode=true when OS power saver mode is active',
      () async {
        final container = ProviderContainer(
          overrides: [
            settingsProvider.overrideWith(
              () => FakeSettingsNotifier(
                const SettingsModel(enableLiquidGlass: true),
              ),
            ),
            batteryStateProvider.overrideWith(
              () => FakeBatteryNotifier(
                const BatteryStateData(
                  batteryLevel: 80,
                  isInPowerSaveMode: true,
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Await future resolution for async notifier provider
        await container.read(batteryStateProvider.future);
        expect(container.read(isEcoModeProvider), isTrue);
      },
    );

    test(
      'Should return isEcoMode=false when settings are normal and battery is high',
      () async {
        final container = ProviderContainer(
          overrides: [
            settingsProvider.overrideWith(
              () => FakeSettingsNotifier(
                const SettingsModel(enableLiquidGlass: true),
              ),
            ),
            batteryStateProvider.overrideWith(
              () => FakeBatteryNotifier(
                const BatteryStateData(
                  batteryLevel: 80,
                  isInPowerSaveMode: false,
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Await future resolution for async notifier provider
        await container.read(batteryStateProvider.future);
        expect(container.read(isEcoModeProvider), isFalse);
      },
    );

    testWidgets(
      'LiquidBackground should render static layout when Eco Mode is active',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(
                () => FakeSettingsNotifier(
                  const SettingsModel(enableLiquidGlass: true),
                ),
              ),
              batteryStateProvider.overrideWith(
                () => FakeBatteryNotifier(
                  const BatteryStateData(
                    batteryLevel: 15,
                    isInPowerSaveMode: false,
                  ), // Low battery -> Eco Mode
                ),
              ),
            ],
            child: const MaterialApp(
              home: LiquidBackground(
                child: Text('Content inside LiquidBackground'),
              ),
            ),
          ),
        );

        // Let microtasks run and re-pump to render target state after future resolves
        await tester.pump();

        // Verify that the child is built
        expect(find.text('Content inside LiquidBackground'), findsOneWidget);

        // In Eco Mode, a simple container is returned (no backdrop filter blur is created)
        expect(find.byType(BackdropFilter), findsNothing);
        expect(find.text('エコモード'), findsOneWidget);
      },
    );

    testWidgets(
      'LiquidBackground should render animated layout with blur when Eco Mode is inactive',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(
                () => FakeSettingsNotifier(
                  const SettingsModel(enableLiquidGlass: true),
                ),
              ),
              batteryStateProvider.overrideWith(
                () => FakeBatteryNotifier(
                  const BatteryStateData(
                    batteryLevel: 85,
                    isInPowerSaveMode: false,
                  ), // Normal battery -> No Eco Mode
                ),
              ),
            ],
            child: const MaterialApp(
              home: LiquidBackground(
                child: Text('Content inside LiquidBackground'),
              ),
            ),
          ),
        );

        // Let microtasks run and re-pump to render target state after future resolves
        await tester.pump();

        // Verify that the child is built
        expect(find.text('Content inside LiquidBackground'), findsOneWidget);

        // In Normal Mode, BackdropFilter and Positioned orbs must be rendered
        expect(find.byType(BackdropFilter), findsOneWidget);
        expect(find.text('エコモード'), findsNothing);
      },
    );

    testWidgets(
      'SettingsScreen should display Eco Mode switch and toggle settings correctly',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});

        final fakeSettingsNotifier = FakeSettingsNotifier(
          const SettingsModel(
            enableLiquidGlass: true,
          ), // Starts with Normal/Full graphics (Eco Mode OFF)
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(() => fakeSettingsNotifier),
              isarProvider.overrideWithValue(null),
              batteryStateProvider.overrideWith(
                () => FakeBatteryNotifier(
                  const BatteryStateData(
                    batteryLevel: 100,
                    isInPowerSaveMode: false,
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );

        await tester.pump();

        // Verify settings screen is rendered and has the correct title
        expect(find.text('省エネモード（背景アニメーション停止）'), findsOneWidget);

        // Find the specific switch tile by using descendant finders
        final ecoModeTileFinder = find.ancestor(
          of: find.text('省エネモード（背景アニメーション停止）'),
          matching: find.byType(ListTile),
        );
        final switchInTileFinder = find.descendant(
          of: ecoModeTileFinder,
          matching: find.byType(Switch),
        );

        // Verify the switch is initially OFF (value == false since settings.enableLiquidGlass is true)
        Switch ecoSwitch = tester.widget<Switch>(switchInTileFinder);
        expect(ecoSwitch.value, isFalse);

        // Tap the switch to turn Eco Mode ON
        await tester.tap(switchInTileFinder);
        await tester.pump(const Duration(milliseconds: 100));

        // Verify that updateField was called and enableLiquidGlass is now false (Eco Mode is ON)
        expect(fakeSettingsNotifier.state.enableLiquidGlass, isFalse);

        // Re-read switch value (which should now be true)
        ecoSwitch = tester.widget<Switch>(switchInTileFinder);
        expect(ecoSwitch.value, isTrue);
      },
    );
  });
}
