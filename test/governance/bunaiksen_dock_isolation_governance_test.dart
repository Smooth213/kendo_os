import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/start_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() => const SettingsModel();
}

void main() {
  group('🛡️ 【部内戦ドック完全隔離・画面外残留ゼロ保証ガバナンス】', () {
    test('1. 静的コード規約: 部内戦対象画面以外に BunaiksenDockButton が1文字たりとも記述されていないこと', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      // 許可されたファイル（部内戦ホーム、部内戦成績、試合入力の部内戦分岐、ドック自身）
      final allowedFiles = {
        'bunaiksen_dock_button.dart',
        'bunaiksen_home_screen.dart',
        'bunaiksen_official_record_screen.dart',
        'match_screen.dart',
        'match_floating_dock_entry.dart',
      };

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final fileName = file.uri.pathSegments.last;
        if (allowedFiles.contains(fileName)) continue;

        final content = file.readAsStringSync();
        expect(
          content.contains('BunaiksenDockButton'),
          isFalse,
          reason:
              '🚨 【重大違反】部内戦以外のファイル (${file.path}) に BunaiksenDockButton が配置されています！\n'
              '部内戦ドックは部内戦画面以外に絶対に露出させてはなりません。',
        );
      }
    });

    testWidgets('2. スタート画面（トップ画面）に部内戦ドックが一切描画されないこと', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserRoleProvider.overrideWithValue(UserRole.admin),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
          ],
          child: const MaterialApp(home: StartScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // スタート画面に BunaiksenDockButton が一切存在しないこと
      expect(find.byType(BunaiksenDockButton), findsNothing);
      expect(find.text('部内戦をはじめる'), findsOneWidget);
    });

    testWidgets('3. 部内戦画面を離脱（Pop / 画面破棄）した際、表示中のドックシートが確実に自動破棄（close）されること', (
      tester,
    ) async {
      final viewDate = DateTime(2026, 9, 11);
      final dateId = 'bunaiksen_20260911';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserRoleProvider.overrideWithValue(UserRole.admin),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            permissionProvider.overrideWithValue(
              const PermissionState(role: UserRole.admin),
            ),
            bunaiksenViewDateProvider.overrideWith((ref) => viewDate),
            bunaiksenMatchesProvider(dateId).overrideWithValue([]),
            bunaiksenAvailableDatesProvider.overrideWith(
              (ref) => Stream.value({'20260911'}),
            ),
            matchListProvider.overrideWithValue([]),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BunaiksenHomeScreen(),
                      ),
                    );
                  },
                  child: const Text('Go to Bunaiksen'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 初期状態：ドックシートは開いていない
      expect(FloatingDockSheetManager.isOpen, isFalse);

      // 部内戦ホームへ遷移
      await tester.tap(find.text('Go to Bunaiksen'));
      await tester.pumpAndSettle();

      // 部内戦ホーム内ではドックボタンが存在する
      expect(find.byType(BunaiksenDockButton), findsOneWidget);

      // ドックシート（対戦一覧等）を開いた状態にする
      FloatingDockSheetManager.show(
        context: tester.element(find.byType(BunaiksenHomeScreen)),
        builder: (_) => const SizedBox(
          height: 300,
          child: Text('Bunaiksen Active Sheet Content'),
        ),
      );
      await tester.pumpAndSettle();

      expect(FloatingDockSheetManager.isOpen, isTrue);
      expect(find.text('Bunaiksen Active Sheet Content'), findsOneWidget);

      // 部内戦画面の戻るボタン（AppHeaderの戻る矢印）をタップして部内戦を出る
      final backButton = find.byType(IconButton).first;
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // ★ 検証: 部内戦を出たため、ドックシートは即座に自動破棄され、画面上に一切残っていないこと！
      expect(FloatingDockSheetManager.isOpen, isFalse);
      expect(find.text('Bunaiksen Active Sheet Content'), findsNothing);
      expect(find.byType(BunaiksenDockButton), findsNothing);
      expect(find.text('Go to Bunaiksen'), findsOneWidget);
    });

    testWidgets(
      '4. 観客（Viewer）モード時は部内戦画面内であっても BunaiksenDockButton が一切描画されないこと',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserRoleProvider.overrideWithValue(UserRole.viewer),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: BunaiksenDockButton(
                  tournamentId: 'bunaiksen_20260911',
                  isViewerMode: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BunaiksenDockButton), findsOneWidget);
        // SizedBox.shrink なので実体ボタンアイコンは見つからない
        expect(find.byIcon(Icons.dashboard_customize_rounded), findsNothing);
      },
    );
  });
}
