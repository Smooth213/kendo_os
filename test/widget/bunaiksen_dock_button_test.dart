import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_parent_button.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_timer_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/contrast_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] BunaiksenDockButton ウィジェットテスト', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget createTestWidget({
      required bool isViewerMode,
      UserRole role = UserRole.admin,
      bool isDark = false,
      List<Override> additionalOverrides = const [],
    }) {
      final themeColors = AppThemeColors.ofMode(
        isDark: isDark,
        mode: 'bunaiksen',
      );
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserRoleProvider.overrideWith((ref) => role),
          ...additionalOverrides,
        ],
        child: MaterialApp(
          theme: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            extensions: [themeColors],
          ),
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                const Center(child: Text('部内戦メイン画面')),
                BunaiksenDockButton(
                  tournamentId: 'test_bunaiksen_tournament',
                  isViewerMode: isViewerMode,
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('管理者・オペレーター時は部内戦ドックボタンが正常に描画されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(isViewerMode: false, role: UserRole.admin),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BunaiksenDockButton), findsOneWidget);
      expect(find.byType(DockParentButton), findsOneWidget);
    });

    testWidgets(
      'findsNothingにおいて ガバナンス第6条: isViewerMode=true の場合は画面上に一切描画されないこと',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(isViewerMode: true, role: UserRole.admin),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DockParentButton), findsNothing);
      },
    );

    testWidgets(
      'findsNothingにおいて ガバナンス第6条: UserRole.viewer の場合は画面上に一切描画されないこと',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(isViewerMode: false, role: UserRole.viewer),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DockParentButton), findsNothing);
      },
    );

    testWidgets('タップで展開され、全6つの機能アイテム（対戦・成績・日付・メモ・タイマー・設定）が表示されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(isViewerMode: false, role: UserRole.admin),
      );
      await tester.pumpAndSettle();

      // 初回はスピードダイヤルの子アイテムは未展開、親ボタンは盾（Icons.shield_rounded）
      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted_rounded), findsNothing);
      expect(find.byIcon(Icons.leaderboard_rounded), findsNothing);

      // 親ボタンをタップして展開
      await tester.tap(find.byIcon(Icons.shield_rounded));
      await tester.pumpAndSettle();

      // 純粋アイコン仕様: タイトルラベルは一切表示されないこと
      expect(find.text('対戦一覧'), findsNothing);
      expect(find.text('成績・星取表'), findsNothing);
      expect(find.text('カレンダー'), findsNothing);
      expect(find.text('クイックメモ'), findsNothing);

      // 全6アイテムのアイコンが表示されること（大会ホームと同一シンボルに統一：タイマー停止時はtimer_outlined）
      expect(find.byIcon(Icons.format_list_bulleted_rounded), findsOneWidget);
      expect(find.byIcon(Icons.leaderboard_rounded), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
      expect(find.byIcon(Icons.brush_rounded), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    });

    testWidgets(
      '大会ホームと同一において タイマー動作時は親ボタンにタイマーバッジが表示され、展開時はIcons.timer_roundedとなること',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createTestWidget(isViewerMode: false, role: UserRole.admin),
        );
        await tester.pumpAndSettle();

        // タイマーを開始
        final element = tester.element(find.byType(BunaiksenDockButton));
        final container = ProviderScope.containerOf(element);
        container.read(dockTimerProvider.notifier).start();
        await tester.pump();

        // 親ボタンにタイマーバッジ (03:00) が表示されること
        expect(find.text('03:00'), findsOneWidget);

        // 親ボタンをタップして展開
        await tester.tap(find.byIcon(Icons.shield_rounded));
        await tester.pumpAndSettle();

        // 展開時のタイマーアイテムは Icons.timer_rounded（大会ホームと同一）になること
        expect(find.byIcon(Icons.timer_rounded), findsOneWidget);
        expect(find.byIcon(Icons.timer_outlined), findsNothing);
      },
    );

    testWidgets('部内戦親ドックボタンに白銀プラチナ枠・角丸八角形（八角鍔）・盾アイコンが適用されていること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(isViewerMode: false, role: UserRole.admin),
      );
      await tester.pumpAndSettle();

      // 盾アイコンが表示されていること
      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);

      // 親ボタンのAnimatedContainerのdecorationが八角鍔（ShapeDecoration / StarBorder.polygon sides: 8）であること
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      final decoration = animatedContainer.decoration as ShapeDecoration;
      expect(decoration.shape, isA<StarBorder>());
      final starBorder = decoration.shape as StarBorder;
      expect(starBorder.points, 8.0);
      expect(
        starBorder.side.color.toARGB32(),
        const Color(0xFF94A3B8).withValues(alpha: 0.95).toARGB32(),
      );
    });

    testWidgets(
      '部内戦親ドックボタンの背景（gradientColors）とアイコン色（iconColor）のコントラスト比がライト/ダーク両方で3.0:1以上であること',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        for (final isDark in [false, true]) {
          await tester.pumpWidget(
            createTestWidget(
              isViewerMode: false,
              role: UserRole.admin,
              isDark: isDark,
            ),
          );
          await tester.pumpAndSettle();

          final animatedContainer = tester.widget<AnimatedContainer>(
            find.byType(AnimatedContainer).first,
          );
          final decoration = animatedContainer.decoration as ShapeDecoration;
          final gradient = decoration.gradient as LinearGradient;
          final iconWidget = tester.widget<Icon>(
            find.byIcon(Icons.shield_rounded),
          );

          expectFloatingDockContrast(
            iconColor: iconWidget.color!,
            backgroundColors: gradient.colors,
            minRatio: 3.0,
            label: '部内戦親ドック (${isDark ? "ダークモード" : "ライトモード"})',
          );
        }
      },
    );

    test(
      'ガバナンス第6条 静的検証: lib/features/viewer/ 配下に BunaiksenDockButton が一切存在しないこと',
      () {
        final viewerDir = Directory('lib/features/viewer');
        expect(viewerDir.existsSync(), isTrue);

        final dartFiles = viewerDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        for (final file in dartFiles) {
          final content = file.readAsStringSync();
          expect(
            content.contains('BunaiksenDockButton'),
            isFalse,
            reason:
                '🚨 閲覧専用ビュアー (${file.path}) に BunaiksenDockButton が検出されました！',
          );
        }
      },
    );
  });
}
