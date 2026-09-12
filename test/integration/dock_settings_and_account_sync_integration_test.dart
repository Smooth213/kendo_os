import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kendo_os/features/auth/application/google_auth_service.dart';
import 'package:kendo_os/features/band/presentation/components/band_settings_section.dart';
import 'package:kendo_os/features/band/presentation/providers/band_provider.dart';
import 'package:kendo_os/features/band/domain/entities/band_group_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_parent_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_program_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_ui_tiles.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_matches_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGoogleAuthService extends Mock implements GoogleAuthService {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences mockPrefs;
  late MockGoogleAuthService mockGoogleAuth;

  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
    mockGoogleAuth = MockGoogleAuthService();
  });

  tearDown(() async {
    if (FloatingDockSheetManager.isOpen) {
      await FloatingDockSheetManager.close(immediate: true);
    }
  });

  Widget createTestContainer({
    required Widget child,
    void Function(WidgetRef)? onRefCaptured,
    bool isGoogleLinked = true,
  }) {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        currentUserRoleProvider.overrideWithValue(UserRole.admin),
        googleAuthServiceProvider.overrideWithValue(mockGoogleAuth),
        isGoogleLinkedProvider.overrideWithValue(isGoogleLinked),
        linkedGoogleEmailProvider.overrideWithValue('kendo.master@example.com'),
        linkedGoogleUidProvider.overrideWithValue('google_uid_998877'),
        bunaiksenMatchesProvider('bunaiksen_test').overrideWithValue([]),
        bandGroupsStreamProvider.overrideWith(
          (ref) => Stream.value(<BandGroupModel>[]),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [themeColors]),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              onRefCaptured?.call(ref);
              return child;
            },
          ),
        ),
      ),
    );
  }

  group('🥋 【パート2】ドック ➔ システム設定 ➔ 設定値変更・Google同期/解除・BAND・ログアウト保証', () {
    testWidgets('1. 大会ホームドックから設定を開き、設定トグル変更がsettingsProviderに即時反映されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        createTestContainer(
          onRefCaptured: (ref) => capturedRef = ref,
          child: const Stack(
            children: [
              Center(child: Text('大会ホーム')),
              FloatingProgramDockButton(tournamentId: 'tourney_settings_test'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ドック展開
      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();

      // 設定アイコンタップ
      final settingsIcon = find.byIcon(Icons.settings_rounded);
      expect(settingsIcon, findsOneWidget);
      await tester.tap(settingsIcon);
      await tester.pumpAndSettle();

      expect(FloatingDockSheetManager.isOpen, isTrue);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('システム設定'), findsOneWidget);

      // スリープ防止設定の切り替え検証
      final initialSleep = capturedRef.read(settingsProvider).sleepPrevent;
      final sleepTile = find.widgetWithText(SettingsSwitchTile, 'スリープ(画面消灯)防止');
      expect(sleepTile, findsOneWidget);

      final sleepSwitch = find.descendant(
        of: sleepTile,
        matching: find.byType(Switch),
      );
      await tester.tap(sleepSwitch);
      await tester.pumpAndSettle();

      final updatedSleep = capturedRef.read(settingsProvider).sleepPrevent;
      expect(updatedSleep, !initialSleep);

      // 記録修正ロックの切り替え検証（スクロールして表示）
      await tester.scrollUntilVisible(
        find.text('記録確定後の修正ロック'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final initialLock = capturedRef.read(settingsProvider).isLocked;
      final lockTile = find.widgetWithText(SettingsSwitchTile, '記録確定後の修正ロック');
      expect(lockTile, findsOneWidget);

      final lockSwitch = find.descendant(
        of: lockTile,
        matching: find.byType(Switch),
      );
      await tester.tap(lockSwitch);
      await tester.pumpAndSettle();

      final updatedLock = capturedRef.read(settingsProvider).isLocked;
      expect(updatedLock, !initialLock);

      await FloatingDockSheetManager.close(immediate: true);
      await tester.pumpAndSettle();
    });

    testWidgets('2. 部内戦ドックからも同一の設定画面が開き、Google連携中表示・解除ダイアログフローが動作すること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockGoogleAuth.unlinkGoogle()).thenAnswer((_) async {});

      await tester.pumpWidget(
        createTestContainer(
          child: const Stack(
            children: [
              Center(child: Text('部内戦ホーム')),
              BunaiksenDockButton(tournamentId: 'bunaiksen_test'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 部内戦ドック展開
      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();

      final settingsIcon = find.byIcon(Icons.settings_rounded);
      expect(settingsIcon, findsOneWidget);
      await tester.tap(settingsIcon);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);

      // スクロールしてGoogle連携タイルを表示
      await tester.scrollUntilVisible(
        find.text('Google連携中'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Google連携中表示の確認
      expect(find.text('Google連携中'), findsOneWidget);
      expect(find.text('kendo.master@example.com'), findsOneWidget);
      expect(find.text('クラウド同期有効（メモ・既読共有中）'), findsOneWidget);

      // 解除ボタンタップ ➔ 確認ダイアログ
      final unlinkBtn = find.widgetWithText(TextButton, '解除');
      expect(unlinkBtn, findsOneWidget);
      await tester.tap(unlinkBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AppDialog), findsOneWidget);
      expect(find.text('Google連携を解除しますか？'), findsOneWidget);

      // ダイアログ内の「連携解除」ボタン押下
      final confirmUnlinkBtn = find.widgetWithText(TextButton, '連携解除');
      expect(confirmUnlinkBtn, findsOneWidget);
      await tester.tap(confirmUnlinkBtn);
      await tester.pumpAndSettle();

      verify(() => mockGoogleAuth.unlinkGoogle()).called(1);

      await FloatingDockSheetManager.close(immediate: true);
      await tester.pumpAndSettle();
    });

    testWidgets('3. 設定内のBAND連携タイルタップでBANDグループ管理画面が開くこと', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestContainer(
          onRefCaptured: (ref) {},
          child: const Stack(
            children: [
              FloatingProgramDockButton(tournamentId: 'tourney_settings_test'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      // スクロールしてBAND連携タイルを表示
      await tester.scrollUntilVisible(
        find.text('BAND連携・LIVE配信設定'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // BAND連携タイル
      final bandTile = find.text('BAND連携・LIVE配信設定');
      expect(bandTile, findsOneWidget);
      await tester.tap(bandTile);
      await tester.pumpAndSettle();

      expect(find.byType(BandSettingsManagementSheet), findsOneWidget);
      expect(find.text('BANDグループ管理'), findsOneWidget);

      await FloatingDockSheetManager.close(immediate: true);
      await tester.pumpAndSettle();
    });

    testWidgets('4. 設定内のログアウトタップで確認ダイアログが表示されること', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestContainer(
          onRefCaptured: (ref) {},
          child: const Stack(
            children: [
              FloatingProgramDockButton(tournamentId: 'tourney_settings_test'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      // スクロールしてログアウトタイルを表示
      await tester.scrollUntilVisible(
        find.text('ログアウト'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // ログアウトタイル
      final logoutTile = find.text('ログアウト');
      expect(logoutTile, findsOneWidget);
      await tester.tap(logoutTile);
      await tester.pumpAndSettle();

      expect(find.byType(AppDialog), findsOneWidget);
      expect(find.text('ログアウトしますか？'), findsOneWidget);

      // キャンセルタップで閉じる
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.byType(AppDialog), findsNothing);

      await FloatingDockSheetManager.close(immediate: true);
      await tester.pumpAndSettle();
    });
  });
}
