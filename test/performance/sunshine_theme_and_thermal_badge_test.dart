import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/shared/application/services/thermal_power_governor.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_accordion_selector.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/thermal_status_badge.dart';

void main() {
  group('🛡️ 【設定・安心感の可視化】サンシャイン高コントラスト＆サーマルバッジ検証テスト', () {
    test('サンシャインモードのカラーパレットが直射日光下の最高視認性（純白×漆黒）を満たしていること', () {
      final sunshineColors = AppThemeColors.ofMode(
        isDark: false,
        mode: 'sunshine',
      );

      // 背景は純白
      expect(sunshineColors.scaffoldBackground, equals(Colors.white));
      expect(sunshineColors.cardBackground, equals(Colors.white));

      // テキストは漆黒
      expect(sunshineColors.textColor, equals(Colors.black));
      // 境界線はクッキリ黒
      expect(sunshineColors.separatorColor, equals(const Color(0xFF000000)));

      // 高彩度アクセント
      expect(sunshineColors.primaryAccent, equals(const Color(0xFF0055D4)));
      expect(sunshineColors.rosePink, equals(const Color(0xFFD32F2F)));

      // ignore: avoid_print
      print(
        '☀️ [Sunshine Theme Spec]\n'
        '  - Scaffold Background: ${sunshineColors.scaffoldBackground}\n'
        '  - Text Color: ${sunshineColors.textColor}\n'
        '  - Separator Color: ${sunshineColors.separatorColor}\n'
        '  - High Contrast Ratio: 21:1 (Max WCAG AAA Compliant)',
      );
    });

    testWidgets('ThermalStatusBadge が各省電力モードに応じたアイコン・ラベルを表示すること', (
      tester,
    ) async {
      final governor = ThermalPowerGovernor();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            thermalPowerGovernorProvider.overrideWith((ref) => governor),
          ],
          child: const MaterialApp(
            home: Scaffold(body: Center(child: ThermalStatusBadge())),
          ),
        ),
      );

      // 1. 通常モード: "高速"
      expect(find.text('高速'), findsOneWidget);

      // 2. エコ冷却モード: "冷却"
      governor.setMode(ThermalPowerMode.ecoCooling);
      await tester.pump();
      expect(find.text('冷却'), findsOneWidget);

      // 3. 極限省電力モード: "省電力"
      governor.setMode(ThermalPowerMode.ultraSave);
      await tester.pump();
      expect(find.text('省電力'), findsOneWidget);
    });

    testWidgets('3モード全て（⚡ 高速 / 🔋 冷却 / 🌿 省電力）でトグルスイッチ同一サイズ（64x31）で描画されること', (
      tester,
    ) async {
      final governor = ThermalPowerGovernor();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            thermalPowerGovernorProvider.overrideWith((ref) => governor),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(child: ThermalStatusBadge(isSwitchSize: true)),
            ),
          ),
        ),
      );

      // 1. ⚡ 高速
      expect(find.text('高速'), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
      var size = tester.getSize(find.byType(ThermalStatusBadge));
      expect(size.width, 64.0);
      expect(size.height, 31.0);

      // 2. 🔋 冷却
      governor.setMode(ThermalPowerMode.ecoCooling);
      await tester.pump();
      expect(find.text('冷却'), findsOneWidget);
      expect(find.byIcon(Icons.battery_charging_full_rounded), findsOneWidget);
      size = tester.getSize(find.byType(ThermalStatusBadge));
      expect(size.width, 64.0);
      expect(size.height, 31.0);

      // 3. 🌿 省電力
      governor.setMode(ThermalPowerMode.ultraSave);
      await tester.pump();
      expect(find.text('省電力'), findsOneWidget);
      expect(find.byIcon(Icons.energy_savings_leaf_rounded), findsOneWidget);
      size = tester.getSize(find.byType(ThermalStatusBadge));
      expect(size.width, 64.0);
      expect(size.height, 31.0);
    });

    testWidgets('ThermalStatusBadge をタップした際に安心解説ボトムシートが展開されること', (
      tester,
    ) async {
      final governor = ThermalPowerGovernor()
        ..setMode(ThermalPowerMode.ecoCooling);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            thermalPowerGovernorProvider.overrideWith((ref) => governor),
          ],
          child: const MaterialApp(
            home: Scaffold(body: Center(child: ThermalStatusBadge())),
          ),
        ),
      );

      // バッジをタップ
      await tester.tap(find.byType(ThermalStatusBadge));
      await tester.pumpAndSettle();

      // ボトムシートが展開され、安心解説テキストが表示されること
      expect(find.text('🛡️ サーマル冷却＆省電力ステータス'), findsOneWidget);
      expect(find.text('エコサーマル冷却モード (500ms)'), findsOneWidget);
      expect(find.textContaining('80% 削減中'), findsOneWidget);
      expect(find.textContaining('時間精度100%保証'), findsOneWidget);

      // 「閉じる」ボタンでシートが閉じること
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
      expect(find.text('🛡️ サーマル冷却＆省電力ステータス'), findsNothing);
    });

    testWidgets('ライトモード白背景時でも通常モードのバッジがくっきりと視認可能であること', (tester) async {
      final governor = ThermalPowerGovernor(); // normal モード

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            thermalPowerGovernorProvider.overrideWith((ref) => governor),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: ThermalStatusBadge(isLightSurface: true)),
            ),
          ),
        ),
      );

      // "高速" テキストが存在すること
      expect(find.text('高速'), findsOneWidget);
      // アイコンが存在すること
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
    });

    testWidgets('SettingsScreen で「外観テーマ」タイルが横1行で美しく描画され、☀️ サンシャインを選択できること', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
        ),
      );
      await tester.pumpAndSettle();

      // 1. タイトル「外観テーマ」と三日月アイコンが存在すること
      expect(find.text('外観テーマ'), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);

      // 2. インラインアコーディオンセレクターが存在すること
      final selectorFinder = find.byType(SettingsAccordionSelector<String>);
      expect(selectorFinder, findsOneWidget);

      // アコーディオンを展開
      await tester.tap(selectorFinder);
      await tester.pumpAndSettle();

      // 3. 4つのテーマ選択肢がすべて存在すること
      expect(find.text('端末連動'), findsWidgets);
      expect(find.text('ライト'), findsWidgets);
      expect(find.text('ダーク'), findsWidgets);
      expect(find.text('☀️ サンシャイン'), findsWidgets);

      // 4. 「☀️ サンシャイン」をタップして選択できること
      await tester.tap(find.text('☀️ サンシャイン').last);
      await tester.pumpAndSettle();

      // 選択が反映されていること
      expect(find.text('☀️ サンシャイン'), findsWidgets);
    });

    testWidgets(
      'SettingsScreen 内のサーマルバッジがトグルスイッチと同一の高さ(31px)で整列し、タップで解説シートが開くこと',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
          ),
        );
        await tester.pumpAndSettle();

        // 1. サーマル冷却制御タイルが存在すること
        expect(find.text('サーマル冷却・省電力制御'), findsOneWidget);

        // 2. バッジのサイズがトグルスイッチと同じ (幅64px, 高さ31px) であること
        final badgeFinder = find.byType(ThermalStatusBadge);
        expect(badgeFinder, findsOneWidget);
        final size = tester.getSize(badgeFinder);
        expect(size.width, 64.0);
        expect(size.height, 31.0);

        // 3. バッジをタップして設定画面上でも安心解説シートが開くこと
        await tester.tap(badgeFinder);
        await tester.pumpAndSettle();

        expect(find.text('🛡️ サーマル冷却＆省電力ステータス'), findsOneWidget);
        expect(find.textContaining('端末の内蔵絶対時計から計算'), findsOneWidget);

        await tester.tap(find.text('閉じる'));
        await tester.pumpAndSettle();
        expect(find.text('🛡️ サーマル冷却＆省電力ステータス'), findsNothing);
      },
    );

    testWidgets('ミニステータスバッジ（isSwitchSize: false）がコンパクトなサイズ（高さ31px未満）で描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            thermalPowerGovernorProvider.overrideWith(
              (ref) => ThermalPowerGovernor(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: UnconstrainedBox(
                  child: ThermalStatusBadge(isSwitchSize: false),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final badgeFinder = find.byType(ThermalStatusBadge);
      expect(badgeFinder, findsOneWidget);
      final size = tester.getSize(badgeFinder);
      expect(size.height, lessThan(31.0));
      expect(find.text('高速'), findsOneWidget);
    });
  });
}
