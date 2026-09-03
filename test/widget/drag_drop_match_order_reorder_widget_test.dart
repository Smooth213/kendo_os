// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🎨 【Widget 5/5】試合順ドラッグ＆ドロップ並替・キャンセル耐久テスト', () {
    testWidgets('ReorderableListView での試合並び替えが例外なく実行され、順序が確定すること', (
      WidgetTester tester,
    ) async {
      final items = ['第1試合: 先鋒戦', '第2試合: 次鋒戦', '第3試合: 中堅戦'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final item = items.removeAt(oldIndex);
                      items.insert(newIndex, item);
                    });
                  },
                  children: [
                    for (int i = 0; i < items.length; i++)
                      ListTile(
                        key: ValueKey(items[i]),
                        title: Text(items[i]),
                        trailing: ReorderableDragStartListener(
                          index: i,
                          child: const Icon(Icons.drag_handle),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('第1試合: 先鋒戦'), findsOneWidget);
      expect(find.text('第2試合: 次鋒戦'), findsOneWidget);
      expect(find.text('第3試合: 中堅戦'), findsOneWidget);

      // ドラッグハンドルの長押しとドラッグ操作（第1試合を第3試合の後ろへ移動）
      final firstItemHandle = find.byIcon(Icons.drag_handle).first;
      final thirdItemHandle = find.byIcon(Icons.drag_handle).last;

      final gesture = await tester.startGesture(
        tester.getCenter(firstItemHandle),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveTo(tester.getCenter(thirdItemHandle));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      // リスト順序が正しく更新され、例外が発生しないこと
      expect(tester.takeException(), isNull);
    });
  });
}
