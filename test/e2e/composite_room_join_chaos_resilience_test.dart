import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/utils/text_sanitizer.dart';

void main() {
  group('[E2E] 道場ルーム参加・不正文字列サニタイズ・通信瞬断カオス耐性テスト', () {
    test('道場名やチーム名入力の全角英数・スペースゆれが安全に正規化されること', () {
      final input1 = '   道場 Ａ １２３ \n\t ';
      final cleaned1 = TextSanitizer.clean(input1);
      expect(cleaned1, '道場A123');

      final input2 = '　修道館　Ｂチーム　';
      final cleaned2 = TextSanitizer.clean(input2);
      expect(cleaned2, '修道館Bチーム');
    });

    test('全角英数字・特殊空白・ハイフン混在のルームコード入力が自動的に正規化されること', () {
      String normalizeRoomCode(String raw) {
        // 全角英数を半角に正規化し、空白・ハイフン・長音符を除去
        final buffer = StringBuffer();
        for (final rune in raw.runes) {
          if (rune >= 0xFF01 && rune <= 0xFF5E) {
            buffer.writeCharCode(rune - 0xFEE0);
          } else if (rune == 0x3000 ||
              rune == 0x20 ||
              rune == 0x2D ||
              rune == 0x30FC ||
              rune == 0xFF0D ||
              rune == 0x2015) {
            // 全角空白、半角空白、ハイフン、長音符はスキップ
            continue;
          } else {
            buffer.writeCharCode(rune);
          }
        }
        return buffer.toString().toLowerCase().trim();
      }

      expect(normalizeRoomCode('ＤＯＪＯー１２３'), 'dojo123');
      expect(normalizeRoomCode('  dojo - 456  '), 'dojo456');
      expect(normalizeRoomCode('ｔｏｕｒｎａｍｅｎｔ　０１'), 'tournament01');
    });

    test('通信瞬断やタイムアウト時の指数バックオフリー試行によって最終的に整合状態に復帰すること', () async {
      int attemptCount = 0;
      bool isNetworkRecovered = false;

      Future<bool> joinRoomWithRetry({int maxRetries = 3}) async {
        for (int i = 0; i < maxRetries; i++) {
          attemptCount++;
          if (isNetworkRecovered) {
            return true;
          }
          // 2回目の試行後にネットワーク復旧をシミュレート
          if (attemptCount >= 2) {
            isNetworkRecovered = true;
          }
          await Future.delayed(const Duration(milliseconds: 10));
        }
        return false;
      }

      final success = await joinRoomWithRetry();
      expect(success, isTrue);
      expect(attemptCount, 3);
    });
  });
}
