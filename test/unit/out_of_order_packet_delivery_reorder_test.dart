import 'package:flutter_test/flutter_test.dart';

/// 🌐 パケット順序逆転自動整列バッファ
class OutOfOrderReorderBuffer<T extends Object> {
  final Map<int, T> _buffer = {};
  int _expectedSequence = 1;
  final List<T> processedItems = [];

  void receivePacket(int sequence, T data) {
    _buffer[sequence] = data;
    _drain();
  }

  void _drain() {
    while (_buffer.containsKey(_expectedSequence)) {
      final item = _buffer.remove(_expectedSequence);
      if (item != null) {
        processedItems.add(item);
      }
      _expectedSequence++;
    }
  }
}

void main() {
  group('👁️ 【Phase 6-9/12】ネットワークパケット順序逆転（Out-of-Order）自動整列テスト', () {
    test(
      '1. パケットが [3, 1, 4, 2] の順序でバラバラに到着しても、[1, 2, 3, 4] の順序で正しく処理されること',
      () {
        final buffer = OutOfOrderReorderBuffer<String>();

        // 3番が先に届く
        buffer.receivePacket(3, '第3イベント: 白胴');
        expect(buffer.processedItems.isEmpty, isTrue); // まだ1番がないので待機

        // 1番が届く
        buffer.receivePacket(1, '第1イベント: 開始');
        expect(buffer.processedItems, ['第1イベント: 開始']); // 1番のみ処理

        // 4番が届く
        buffer.receivePacket(4, '第4イベント: 赤面勝ち');
        expect(buffer.processedItems.length, 1); // 2番がまだないので待機

        // 最後に2番が届く！
        buffer.receivePacket(2, '第2イベント: 赤面');

        // 2, 3, 4番が一気に連鎖して完全整列処理されること！
        expect(buffer.processedItems, [
          '第1イベント: 開始',
          '第2イベント: 赤面',
          '第3イベント: 白胴',
          '第4イベント: 赤面勝ち',
        ]);
      },
    );
  });
}
