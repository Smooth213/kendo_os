import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('📸 【Phase 3-10/11】モーダルダイアログ背面暗転（Scrim）Goldenテスト', () {
    testWidgets('1. ダイアログ表示時に背景が確実に暗転（Scrim）され、中央の確認カードが浮かび上がること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Stack(
              children: [
                // 背景のスコアボード画面
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('【第1コート 準決勝】', style: TextStyle(fontSize: 24)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 60,
                            color: Colors.red.shade900,
                          ),
                          const SizedBox(width: 40),
                          Container(
                            width: 120,
                            height: 60,
                            color: Colors.white24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 🚨 モーダルScrim（暗転バリア: rgba(0, 0, 0, 0.6)）
                ModalBarrier(
                  color: Colors.black.withAlpha(160),
                  dismissible: false,
                ),

                // 中央の確認ダイアログ
                Center(
                  child: Card(
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.amber, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '【審判合議の宣告】',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('試合時計を停止し、直前の打突を取り消しますか？'),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () {},
                                child: const Text('戻る'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () {},
                                child: const Text('一本取り消し実行'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          '../goldens/modal_dialog_background_dimming_golden.png',
        ),
      );
    });
  });
}
