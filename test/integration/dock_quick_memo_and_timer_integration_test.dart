import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_storage_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_timer_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_timer_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences mockPrefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    if (FloatingDockSheetManager.isOpen) {
      await FloatingDockSheetManager.close(immediate: true);
    }
  });

  group('🥋 【パート4】ドック ➔ クイックメモ 書き込み・保存・復元・独立性 完全保証テスト', () {
    testWidgets('クイックメモを開く ➔ テキスト入力 ➔ 保存・閉じる ➔ 再展開で内容復元 ＆ 大会IDと部内戦IDで独立管理を保証', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const tourneyId = 'taikai_memo_test';
      const bunaiksenId = 'bunaiksen_memo_test';

      // 1. 大会メモシートを展開
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockPrefs),
            currentUserRoleProvider.overrideWithValue(UserRole.admin),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: QuickMemoBottomSheet(
                key: ValueKey(tourneyId),
                tournamentId: tourneyId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // クイックメモシートが表示されていることを確認
      expect(find.text('クイックメモ'), findsOneWidget);

      // 2. テキストモードに切り替え
      final textModeTab = find.text('テキストメモ');
      expect(textModeTab, findsOneWidget);
      await tester.tap(textModeTab);
      await tester.pumpAndSettle();

      // 3. テキストを入力
      final textFieldFinder = find.byType(AppTextField);
      expect(textFieldFinder, findsOneWidget);
      const tourneyMemoText = '【大会本部連絡】第2試合場の審判交代：午後13時';
      await tester.enterText(textFieldFinder, tourneyMemoText);
      await tester.pumpAndSettle();

      // 4. ストレージに保存されたことを確認
      final savedTourneyData = await QuickMemoStorageService.instance.loadMemo(
        tourneyId,
      );
      expect(savedTourneyData.text, equals(tourneyMemoText));

      // 5. 部内戦用の別IDでメモシートを開く
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockPrefs),
            currentUserRoleProvider.overrideWithValue(UserRole.admin),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: QuickMemoBottomSheet(
                key: ValueKey(bunaiksenId),
                tournamentId: bunaiksenId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 部内戦側では大会のメモが混ざらず、独立して初期状態であることを確認
      final bunaiksenData = await QuickMemoStorageService.instance.loadMemo(
        bunaiksenId,
      );
      expect(bunaiksenData.text, isEmpty);

      // 部内戦側のテキストを入力
      await tester.tap(find.text('テキストメモ'));
      await tester.pumpAndSettle();
      const bunaiksenMemoText = '【部内戦メモ】次回稽古日：9月20日 18:00開始';
      await tester.enterText(find.byType(AppTextField), bunaiksenMemoText);
      await tester.pumpAndSettle();

      final savedBunaiksenData = await QuickMemoStorageService.instance
          .loadMemo(bunaiksenId);
      expect(savedBunaiksenData.text, equals(bunaiksenMemoText));

      // 6. 再度大会メモを開いたときに大会メモが完全に復元されていることを検証
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockPrefs),
            currentUserRoleProvider.overrideWithValue(UserRole.admin),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: QuickMemoBottomSheet(
                key: ValueKey(tourneyId),
                tournamentId: tourneyId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final reloadedTourneyData = await QuickMemoStorageService.instance
          .loadMemo(tourneyId);
      expect(reloadedTourneyData.text, equals(tourneyMemoText));
      expect(find.text(tourneyMemoText), findsOneWidget);
    });
  });

  group('🥋 【パート5】ドック ➔ 試合タイマー 計時スタート・一時停止・リセット 完全保証テスト', () {
    testWidgets('タイマーシート展開 ➔ プリセット選択(5分) ➔ スタート(一時停止に切り替わり計時) ➔ 一時停止 ➔ リセット', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
          currentUserRoleProvider.overrideWithValue(UserRole.admin),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: DockTimerBottomSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. タイマー初期表示確認（デフォルトは3分=180秒）
      expect(find.text('独立型タイマー'), findsOneWidget);
      expect(find.text('スタート'), findsOneWidget);
      expect(find.text('リセット'), findsOneWidget);

      final initialTimerState = container.read(dockTimerProvider);
      expect(initialTimerState.initialSeconds, equals(180));
      expect(initialTimerState.isRunning, isFalse);

      // 2. 5分プリセットをタップ
      final fiveMinPreset = find.text('5分');
      expect(fiveMinPreset, findsOneWidget);
      await tester.tap(fiveMinPreset);
      await tester.pumpAndSettle();

      final fiveMinState = container.read(dockTimerProvider);
      expect(fiveMinState.initialSeconds, equals(300));
      expect(fiveMinState.remainingSeconds, equals(300));

      // 3. スタートボタンをタップ
      final startBtn = find.text('スタート');
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      // 計時が開始され、ボタンが「一時停止」に切り替わる
      expect(container.read(dockTimerProvider).isRunning, isTrue);
      expect(find.text('一時停止'), findsOneWidget);

      // 1秒進行
      await tester.pump(const Duration(seconds: 1));
      expect(container.read(dockTimerProvider).remainingSeconds, lessThan(300));

      // 4. 一時停止ボタンをタップ
      final pauseBtn = find.text('一時停止');
      await tester.tap(pauseBtn);
      await tester.pumpAndSettle();

      // 停止され、ボタンが「スタート」に戻る
      expect(container.read(dockTimerProvider).isRunning, isFalse);
      expect(find.text('スタート'), findsOneWidget);

      // 5. リセットボタンをタップ
      final resetBtn = find.text('リセット');
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // 5分の初期時間（300秒）に安全にリセットされる
      final resetState = container.read(dockTimerProvider);
      expect(resetState.remainingSeconds, equals(300));
      expect(resetState.isRunning, isFalse);
    });
  });
}
