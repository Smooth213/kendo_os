import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/band/presentation/providers/band_provider.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/shared/bootstrap/app_bootstrap_helper.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  testWidgets('SettingsScreen を内部 Navigator 化した際のサブシート・ダイアログ最前面動作検証', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  FloatingDockSheetManager.show(
                    context: context,
                    builder: (_) => const SettingsScreen(isBottomSheet: true),
                  );
                },
                child: const Text('Open Settings Dock'),
              ),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          settingsProvider.overrideWith(() => MockSettingsNotifier()),
          bandGroupsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // 1. ドックを開く
    await tester.tap(find.text('Open Settings Dock'));
    await tester.pumpAndSettle();

    expect(find.text('システム設定'), findsOneWidget);

    // 2. BAND設定タイルまでスクロール
    final bandTile = find.text('BAND連携・LIVE配信設定');
    await tester.scrollUntilVisible(
      bandTile,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // 3. BAND設定タイルをタップ
    await tester.tap(bandTile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('BANDグループ管理'), findsOneWidget);
    debugPrint('Successfully opened BANDグループ管理!');
  });
}
