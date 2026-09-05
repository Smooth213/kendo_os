import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';

void main() {
  group('🗺️ Googleマップ型フローティングボトムシート (背面操作保証) テスト', () {
    tearDown(() async {
      await FloatingDockSheetManager.close(immediate: true);
    });

    testWidgets('1. フローティングシート展開中も背後のボタンが自由にタップ可能であること (背面操作保証)', (
      tester,
    ) async {
      int backgroundTapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                // 背面のメイン画面 (スコア入力・ボタン)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: ElevatedButton(
                      onPressed: () {
                        backgroundTapCount++;
                      },
                      child: const Text('背面ボタン'),
                    ),
                  ),
                ),
                // フローティングシート起動ボタン
                Align(
                  alignment: Alignment.center,
                  child: Builder(
                    builder: (context) {
                      return ElevatedButton(
                        onPressed: () {
                          FloatingDockSheetManager.show(
                            context: context,
                            builder: (sheetContext) => DockDraggableSheet(
                              builder: (context, scrollController) => Column(
                                children: [
                                  DockBottomSheetHeader(
                                    title: 'クイックメモ',
                                    icon: Icons.brush_rounded,
                                  ),
                                  const Expanded(
                                    child: Center(child: Text('メモ描画エリア')),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: const Text('シートを開く'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // シートを開く
      await tester.tap(find.text('シートを開く'));
      await tester.pumpAndSettle();

      // シートが表示されていること
      expect(FloatingDockSheetManager.isOpen, isTrue);
      expect(find.text('クイックメモ'), findsOneWidget);
      expect(find.text('メモ描画エリア'), findsOneWidget);

      // 💡 最重要検証: シートが開いた状態で、背面のボタンをタップ！
      expect(backgroundTapCount, 0);
      await tester.tap(find.text('背面ボタン'));
      await tester.pump();

      // 背面のタップイベントが完全に発火すること（Googleマップ型操作保証！）
      expect(backgroundTapCount, 1);

      // もう一度タップして2回目も確実に届くこと
      await tester.tap(find.text('背面ボタン'));
      await tester.pump();
      expect(backgroundTapCount, 2);
    });

    testWidgets('2. シート右上の「×」ボタンタップでスムーズに閉じること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    FloatingDockSheetManager.show(
                      context: context,
                      builder: (sheetContext) => DockDraggableSheet(
                        builder: (context, scrollController) => Column(
                          children: [
                            DockBottomSheetHeader(
                              title: 'ヘルプ',
                              icon: Icons.help_outline_rounded,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('ヘルプを開く'),
                ),
              ),
            ),
          ),
        ),
      );

      // シートを開く
      await tester.tap(find.text('ヘルプを開く'));
      await tester.pumpAndSettle();
      expect(find.text('ヘルプ'), findsOneWidget);
      expect(FloatingDockSheetManager.isOpen, isTrue);

      // 右上の閉じるボタン（close_rounded）をタップ
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // シートが閉じていること
      expect(FloatingDockSheetManager.isOpen, isFalse);
      expect(find.text('ヘルプ'), findsNothing);
    });

    testWidgets('3. シート上部を下へ強くフリックすると閉じること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    FloatingDockSheetManager.show(
                      context: context,
                      builder: (sheetContext) => DockDraggableSheet(
                        builder: (context, scrollController) => Column(
                          children: [
                            DockBottomSheetHeader(
                              title: '対戦表',
                              icon: Icons.scoreboard_rounded,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('対戦表を開く'),
                ),
              ),
            ),
          ),
        ),
      );

      // シートを開く
      await tester.tap(find.text('対戦表を開く'));
      await tester.pumpAndSettle();
      expect(find.text('対戦表'), findsOneWidget);

      // シートのタイトル行を下へ大きくドラッグ＆フリック
      await tester.fling(find.text('対戦表'), const Offset(0, 500), 1000);
      await tester.pumpAndSettle();

      // シートが消えていること
      expect(FloatingDockSheetManager.isOpen, isFalse);
      expect(find.text('対戦表'), findsNothing);
    });
  });
}
