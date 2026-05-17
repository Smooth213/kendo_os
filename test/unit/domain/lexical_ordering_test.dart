import 'package:flutter_test/flutter_test.dart';

// UI層（home_screen.dart等）で用いられている Lexical Ordering の中点計算ロジックをテスト用に抽出
double calculateNewOrder(List<double> list, int oldIndex, int newIndex) {
  if (oldIndex < newIndex) {
    newIndex -= 1;
  }
  
  if (oldIndex == newIndex) return list[oldIndex];
  
  double newOrder;
  if (newIndex == 0) {
    newOrder = list.first - 100.0;
  } else if (newIndex == list.length - 1) {
    newOrder = list.last + 100.0;
  } else {
    final prevOrder = list[newIndex > oldIndex ? newIndex : newIndex - 1];
    final nextOrder = list[newIndex > oldIndex ? newIndex + 1 : newIndex];
    newOrder = (prevOrder + nextOrder) / 2.0;
  }

  if (newOrder == list[newIndex]) {
    newOrder += 0.001;
  }

  return newOrder;
}

void main() {
  group('Lexical Ordering Test', () {
    test('先頭への移動: 先頭要素より100.0小さい値が生成されること', () {
      final list = [100.0, 200.0, 300.0, 400.0];
      final newOrder = calculateNewOrder(list, 1, 0);
      expect(newOrder, 0.0); // 100.0 - 100.0
    });

    test('末尾への移動: 末尾要素より100.0大きい値が生成されること', () {
      final list = [100.0, 200.0, 300.0, 400.0];
      final newOrder = calculateNewOrder(list, 1, 4);
      expect(newOrder, 500.0); // 400.0 + 100.0
    });

    test('要素間への移動（後方へ）: 前後の要素の中間値が生成されること', () {
      final list = [100.0, 200.0, 300.0, 400.0];
      final newOrder = calculateNewOrder(list, 0, 3);
      expect(newOrder, 350.0); // (300.0 + 400.0) / 2.0
    });

    test('要素間への移動（前方へ）: 前後の要素の中間値が生成されること', () {
      final list = [100.0, 200.0, 300.0, 400.0];
      final newOrder = calculateNewOrder(list, 3, 1);
      expect(newOrder, 150.0); // (100.0 + 200.0) / 2.0
    });
    
    test('重複回避ロジック: 既存要素と同じ値になった場合は+0.001されること', () {
      final list = [100.0, 100.0, 100.0];
      final newOrder = calculateNewOrder(list, 2, 1);
      expect(newOrder, 100.001);
    });
  });
}