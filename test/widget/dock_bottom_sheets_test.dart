import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/manual_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_bottom_sheet.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_settings_bottom_sheet.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('🥋 ドック内全機能ボトムシート ウィジェットテスト', () {
    testWidgets('DockBottomSheetHeader がタイトル、アイコン、全画面ボタンを表示すること', (
      tester,
    ) async {
      bool fullScreenTapped = false;
      bool closeTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DockBottomSheetHeader(
              title: 'テスト機能',
              icon: Icons.star_rounded,
              onFullScreen: () => fullScreenTapped = true,
              onClose: () => closeTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('テスト機能'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byIcon(Icons.open_in_full_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.open_in_full_rounded));
      expect(fullScreenTapped, isTrue);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(closeTapped, isTrue);
    });

    testWidgets('QuickMemoBottomSheet がボトムシートとして起動し、全画面ボタンが表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: QuickMemoBottomSheet(tournamentId: 'test_t1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('クイックメモ'), findsOneWidget);
      expect(find.byIcon(Icons.brush_rounded), findsWidgets);
      expect(find.byIcon(Icons.open_in_full_rounded), findsOneWidget);
      expect(find.text('手書きメモ'), findsOneWidget);
      expect(find.text('テキストメモ'), findsOneWidget);
    });

    testWidgets('ManualBottomSheet がボトムシートとして起動し、マニュアルタイトルと全画面ボタンが表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ManualBottomSheet(isViewerMode: false)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('操作マニュアル・ヘルプ'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_full_rounded), findsWidgets);
    });

    testWidgets('ViewerSettingsBottomSheet が表示設定とテーマ切り替えを表示すること', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(
            home: Scaffold(body: ViewerSettingsBottomSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('表示設定'), findsOneWidget);
      expect(find.text('テーマの切り替え'), findsOneWidget);
    });

    testWidgets('DockDraggableSheet の拡大ボタンをタップすると全開になり、再タップで半分に戻ること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DockDraggableSheet(
              initialChildSize: 0.58,
              maxChildSize: 0.95,
              builder: (context, controller) => Column(
                children: [
                  DockBottomSheetHeader(
                    title: '伸縮テスト',
                    icon: Icons.info_outline,
                    onFullScreen: () {},
                  ),
                  const Expanded(child: Text('コンテンツ')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 初期状態では expand_less_rounded（上に広げる）アイコンが表示されている
      expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);

      // タップして最大化
      await tester.tap(find.byIcon(Icons.expand_less_rounded));
      await tester.pumpAndSettle();

      // 全開になると expand_more_rounded（半分に戻す）アイコンに変わる
      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);

      // もう一度タップして半分に戻す
      await tester.tap(find.byIcon(Icons.expand_more_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);
    });

    testWidgets('DockDraggableSheet を上にドラッグすると全開へスムーズに拡大すること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DockDraggableSheet(
              initialChildSize: 0.58,
              maxChildSize: 0.95,
              builder: (context, controller) => Column(
                children: [
                  DockBottomSheetHeader(
                    title: 'ドラッグテスト',
                    icon: Icons.touch_app,
                    onFullScreen: () {},
                  ),
                  const Expanded(child: Text('コンテンツ')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ドラッグ前は半分（expand_less_rounded）
      expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);

      // タイトル行を上方向に大きくドラッグ
      await tester.drag(find.text('ドラッグテスト'), const Offset(0, -300));
      await tester.pumpAndSettle();

      // 上にドラッグした後は最大化され expand_more_rounded（半分に戻す）に切り替わる
      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
    });
  });
}
