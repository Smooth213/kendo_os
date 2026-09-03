import 'package:flutter_test/flutter_test.dart';

/// 🎫 受付バーコード・QRスキャナー高速連続読み取りキューエンジン
class CheckinScannerQueue {
  final List<String> _queue = [];
  final List<String> processedPlayers = [];
  bool _isProcessing = false;

  void enqueueBarcode(String barcode) {
    if (barcode.trim().isEmpty) return;
    _queue.add(barcode.trim());
    _processNext();
  }

  Future<void> _processNext() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    final nextBarcode = _queue.removeAt(0);

    // 擬似的な受付処理（重複防止チェック＋選手チェックイン）
    if (!processedPlayers.contains(nextBarcode)) {
      processedPlayers.add(nextBarcode);
    }

    _isProcessing = false;
    if (_queue.isNotEmpty) {
      await _processNext();
    }
  }
}

void main() {
  group('📱 【Phase 2-8/10】受付バーコードスキャナー秒間5回高速チェックイン・キュー順次処理テスト', () {
    test('1. 秒間5回（200ms間隔未満）の連続スキャンがキューに溜まり、1件もこぼさず処理されること', () async {
      final queue = CheckinScannerQueue();

      // 受付で5人の選手が連続でQR/バーコードをスキャン
      queue.enqueueBarcode('PLAYER_001');
      queue.enqueueBarcode('PLAYER_002');
      queue.enqueueBarcode('PLAYER_003');
      queue.enqueueBarcode('PLAYER_004');
      queue.enqueueBarcode('PLAYER_005');

      // 非同期キューの消化完了を待機
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(queue.processedPlayers.length, 5);
      expect(queue.processedPlayers, [
        'PLAYER_001',
        'PLAYER_002',
        'PLAYER_003',
        'PLAYER_004',
        'PLAYER_005',
      ]);
    });

    test('2. 同一選手の重複スキャンが二重受付されないこと（冪等性）', () async {
      final queue = CheckinScannerQueue();

      queue.enqueueBarcode('PLAYER_100');
      queue.enqueueBarcode('PLAYER_100'); // 誤って2度ピッと鳴らした

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(queue.processedPlayers.length, 1);
      expect(queue.processedPlayers.first, 'PLAYER_100');
    });
  });
}
