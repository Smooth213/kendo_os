import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/band/domain/entities/band_group_model.dart';
import 'package:kendo_os/features/band/presentation/providers/band_provider.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class _FakeSettingsNotifier extends SettingsNotifier {
  final SettingsModel _initial;
  _FakeSettingsNotifier([SettingsModel? initial])
    : _initial = initial ?? const SettingsModel();

  @override
  SettingsModel build() {
    state = _initial;
    return _initial;
  }

  @override
  Future<void> updateSettings(SettingsModel newSettings) async {
    state = newSettings;
  }
}

final _testBandOverrides = [
  settingsProvider.overrideWith(() => _FakeSettingsNotifier()),
  bandGroupsStreamProvider.overrideWith(
    (ref) => Stream.value([
      const BandGroupModel(
        id: 'band_1',
        name: '低学年チーム',
        url: 'https://band.us/band/12345',
        order: 0,
      ),
    ]),
  ),
];

void main() {
  group('🥋 ドックから開くシステム設定ボトムシート 各種ボタン動作保証テスト', () {
    tearDown(() async {
      if (FloatingDockSheetManager.isOpen) {
        await FloatingDockSheetManager.close(immediate: true);
      }
    });

    testWidgets('1. ドックから開いた設定シートで「ログアウト」を押すとダイアログが前面に開き、キャンセルで戻れること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: _testBandOverrides,
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      FloatingDockSheetManager.show(
                        context: context,
                        builder: (_) =>
                            const SettingsScreen(isBottomSheet: true),
                      );
                    },
                    child: const Text('Open Settings Dock'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // ドックを開く
      await tester.tap(find.text('Open Settings Dock'));
      await tester.pumpAndSettle();

      expect(FloatingDockSheetManager.isOpen, isTrue);
      expect(find.text('システム設定'), findsOneWidget);

      // 下へスクロールしてログアウトを表示
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1000));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1000));
      await tester.pumpAndSettle();

      final logoutTile = find.text('ログアウト');
      expect(logoutTile, findsOneWidget);
      await tester.tap(logoutTile);
      await tester.pumpAndSettle();

      // ★ ログアウト確認ダイアログが最前面に表示されていること！
      expect(find.text('ログアウトしますか？'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);

      // キャンセルを押すとダイアログが閉じ、設定シートがそのまま残っていること
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.text('ログアウトしますか？'), findsNothing);
      expect(FloatingDockSheetManager.isOpen, isTrue);
      expect(find.text('システム設定'), findsOneWidget);
    });

    testWidgets('2. ドックから開いた設定シートで「サーマル冷却・省電力制御」を押すと詳細シートが前面に開くこと', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: _testBandOverrides,
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      FloatingDockSheetManager.show(
                        context: context,
                        builder: (_) =>
                            const SettingsScreen(isBottomSheet: true),
                      );
                    },
                    child: const Text('Open Settings Dock'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // ドックを開く
      await tester.tap(find.text('Open Settings Dock'));
      await tester.pumpAndSettle();

      // 「サーマル冷却・省電力制御」をタップ
      final thermalTile = find.text('サーマル冷却・省電力制御');
      expect(thermalTile, findsOneWidget);
      await tester.tap(thermalTile);
      await tester.pumpAndSettle();

      // ★ サーマル詳細ボトムシートが最前面に表示されていること！
      expect(find.textContaining('サーマル冷却＆省電力ステータス'), findsOneWidget);

      // ダイアログ外または閉じるタップ（ボトムシート外枠タップで閉じる、あるいはNavigator.pop）
      // useRootNavigator: true で開かれたシートを閉じる
      final closeButton = find.text('閉じる');
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton, warnIfMissed: false);
      } else {
        // バリアタップ
        await tester.tapAt(const Offset(100, 100));
      }
      await tester.pumpAndSettle();

      // 閉じたか、バリアタップで閉じたことの確認
      if (find.textContaining('サーマル冷却＆省電力ステータス').evaluate().isNotEmpty) {
        await tester.tapAt(const Offset(100, 100));
        await tester.pumpAndSettle();
      }

      expect(FloatingDockSheetManager.isOpen, isTrue);
      expect(find.text('システム設定'), findsOneWidget);
    });

    testWidgets('3. ドックから開いた設定シートで「BAND連携・LIVE配信設定」を押すとBAND管理シートが前面に開くこと', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: _testBandOverrides,
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      FloatingDockSheetManager.show(
                        context: context,
                        builder: (_) =>
                            const SettingsScreen(isBottomSheet: true),
                      );
                    },
                    child: const Text('Open Settings Dock'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // ドックを開く
      await tester.tap(find.text('Open Settings Dock'));
      await tester.pumpAndSettle();

      // 下へドラッグしてスクロール
      await tester.drag(find.text('システム設定'), const Offset(0, -300));
      await tester.pumpAndSettle();

      // 「BAND連携・LIVE配信設定」をタップ
      final bandTile = find.text('BAND連携・LIVE配信設定');
      expect(bandTile, findsOneWidget);
      await tester.tap(bandTile);
      await tester.pumpAndSettle();

      // ★ BAND管理ボトムシートが最前面に表示されていること！
      expect(find.text('BANDグループ管理'), findsOneWidget);
    });
  });
}
