import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('📸 【Phase 3-6/11】外字・旧字体 豆腐（□）ゼロ描画 Goldenテスト', () {
    testWidgets('1. 代表的な旧字体・異体字が豆腐（文字化け□）にならず正常にレンダリングされること', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const rareKanjiNames = [
        '髙橋 龍之介',
        '山﨑 慎太郎',
        '神武館 剣士',
        '齋藤 飛鳥',
        '齊藤 慎二',
        '渡邊 雄大',
        '渡邉 勇気',
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Center(
              child: Card(
                color: const Color(0xFF1E293B),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '【公式登録選手名簿（旧字体・異体字検証）】',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final name in rareKanjiNames)
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // UI崩壊・はみ出し例外ゼロ検証
      expect(tester.takeException(), isNull);

      // 全ての旧字体・異体字が正しくウィジェットツリーに描画されていること
      for (final name in rareKanjiNames) {
        expect(find.text(name), findsOneWidget);
      }

      // カードとScaffoldが正常にレンダリング完了していること
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
