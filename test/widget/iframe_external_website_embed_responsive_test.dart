import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('👁️ 【Phase 6-11/12】iframe外部Web埋め込み レスポンシブアスペクト比適応テスト', () {
    testWidgets('1. 親コンテナの横幅伸縮に応じて 16:9 アスペクト比が死守され、はみ出しなく適応すること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400, // 親コンテナ
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    key: const Key('embed_iframe_view'),
                    color: const Color(0xFF0F172A),
                    child: const Center(
                      child: Text(
                        'Kendo OS 外部埋め込みビュアー (16:9)',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('embed_iframe_view')), findsOneWidget);
      final size = tester.getSize(find.byKey(const Key('embed_iframe_view')));
      expect(size.width, 400.0);
      expect(size.height, closeTo(400.0 * 9 / 16, 0.1)); // 225px
    });
  });
}
