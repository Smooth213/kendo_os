import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🎨 【Phase 3-1/11】IMEソフトウェアキーボード出現時 自動スクロール隠蔽回避テスト', () {
    testWidgets(
      '1. キーボード出現（viewInsets.bottom: 300px）時、最下部の選手名入力欄が隠れずスクロール可能領域に保持されること',
      (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final scrollController = ScrollController();
        final targetKey = const Key('bottom_player_input_field');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              resizeToAvoidBottomInset: true,
              body: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    Container(
                      height: 300,
                      color: Colors.blue,
                      child: const Text('先鋒・次鋒'),
                    ),
                    Container(
                      height: 300,
                      color: Colors.green,
                      child: const Text('中堅・副鋒'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        key: targetKey,
                        decoration: const InputDecoration(
                          labelText: '大将 選手名入力',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // 初期描画
        await tester.pumpAndSettle();

        // キーボード出現をシミュレート（下部インセット 300px）
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();

        // スクロールによりTextFieldを可視領域へ移動
        await tester.ensureVisible(find.byKey(targetKey));
        await tester.pumpAndSettle();

        // 入力欄が画面内に存在し、キーボードの裏に隠れず操作可能であること
        expect(find.byKey(targetKey), findsOneWidget);
        final fieldRect = tester.getRect(find.byKey(targetKey));
        expect(fieldRect.top, greaterThanOrEqualTo(0.0));
        expect(
          fieldRect.bottom,
          lessThanOrEqualTo(300.0 + 1.0),
        ); // 600 - 300 = 300px 以内に収まる
      },
    );
  });
}
