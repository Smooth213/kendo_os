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
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🥋 BunaiksenDockButton Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget createTestWidget({
      required bool isViewerMode,
      UserRole role = UserRole.admin,
      List<Override> additionalOverrides = const [],
    }) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserRoleProvider.overrideWith((ref) => role),
          ...additionalOverrides,
        ],
        child: MaterialApp(
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

    testWidgets('1. 管理者・オペレーター時は部内戦ドックボタンが正常に描画されること', (tester) async {
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
      '2. 🛡️ ガバナンス第6条: isViewerMode=true の場合は画面上に一切描画されないこと (findsNothing)',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(isViewerMode: true, role: UserRole.admin),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DockParentButton), findsNothing);
      },
    );

    testWidgets(
      '3. 🛡️ ガバナンス第6条: UserRole.viewer の場合は画面上に一切描画されないこと (findsNothing)',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(isViewerMode: false, role: UserRole.viewer),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DockParentButton), findsNothing);
      },
    );

    testWidgets('4. タップで展開され、全6つの機能アイテム（対戦・成績・日付・メモ・タイマー・設定）が表示されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(isViewerMode: false, role: UserRole.admin),
      );
      await tester.pumpAndSettle();

      // 初回はスピードダイヤルの子アイテムは未展開
      expect(find.byIcon(Icons.format_list_bulleted_rounded), findsNothing);
      expect(find.byIcon(Icons.leaderboard_rounded), findsNothing);

      // 親ボタンをタップして展開
      await tester.tap(find.byIcon(Icons.widgets_rounded));
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
      '5. タイマー動作時は親ボタンにタイマーバッジが表示され、展開時はIcons.timer_roundedとなること（大会ホームと同一）',
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
        await tester.tap(find.byIcon(Icons.widgets_rounded));
        await tester.pumpAndSettle();

        // 展開時のタイマーアイテムは Icons.timer_rounded（大会ホームと同一）になること
        expect(find.byIcon(Icons.timer_rounded), findsOneWidget);
        expect(find.byIcon(Icons.timer_outlined), findsNothing);
      },
    );

    test(
      '6. 🛡️ ガバナンス第6条 静的検証: lib/features/viewer/ 配下に BunaiksenDockButton が一切存在しないこと',
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
