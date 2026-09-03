// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🎨 【Phase 3-4/11】ドラッグ並び替え中断・画面外キャンセル時の順序ロールバックテスト', () {
    testWidgets(
      '1. ReorderableListView でのドラッグ中にポインタがキャンセルされた場合、元の順序が完全保持されること',
      (tester) async {
        final items = ['先鋒: 佐藤', '次鋒: 鈴木', '中堅: 田中'];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return ReorderableListView(
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = items.removeAt(oldIndex);
                        items.insert(newIndex, item);
                      });
                    },
                    children: [
                      for (final item in items)
                        ListTile(key: ValueKey(item), title: Text(item)),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        expect(items[0], '先鋒: 佐藤');
        expect(items[1], '次鋒: 鈴木');
        expect(items[2], '中堅: 田中');

        // 「先鋒: 佐藤」を長押しドラッグ開始
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('先鋒: 佐藤')),
        );
        await tester.pump(const Duration(milliseconds: 600)); // 長押し認識

        // 画面外（-100, -100）へ移動
        await gesture.moveTo(const Offset(-100, -100));
        await tester.pump();

        // 🚨 電話着信や画面外ドラッグ逸脱によるキャンセル発生！
        await gesture.cancel();
        await tester.pumpAndSettle();

        // 順序が崩れず、完全に元の状態が保全されていること
        expect(items[0], '先鋒: 佐藤');
        expect(items[1], '次鋒: 鈴木');
        expect(items[2], '中堅: 田中');
      },
    );
  });
}
