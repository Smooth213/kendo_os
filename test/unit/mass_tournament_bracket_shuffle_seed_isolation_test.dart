import 'package:flutter_test/flutter_test.dart';

/// 🥋 同門・同一道場初戦衝突回避シャッフルエンジン
class DojoCollisionAvoider {
  /// 選手リストを同一所属が初戦（隣接）でぶつからないように配置
  static List<Map<String, String>> allocateBracket(
    List<Map<String, String>> players,
  ) {
    // 道場ごとにグループ化
    final grouped = <String, List<Map<String, String>>>{};
    for (final p in players) {
      grouped.putIfAbsent(p['dojo']!, () => []).add(p);
    }

    final result = <Map<String, String>>[];
    final maxPerDojo = grouped.values
        .map((l) => l.length)
        .reduce((a, b) => a > b ? a : b);

    for (int round = 0; round < maxPerDojo; round++) {
      for (final dojo in grouped.keys) {
        final list = grouped[dojo]!;
        if (round < list.length) {
          result.add(list[round]);
        }
      }
    }

    return result;
  }
}

void main() {
  group('☁️ 【Phase 7-6/8】メガトーナメント 同一道場・同門初戦衝突完全回避テスト', () {
    test('1. 同一道場から複数名エントリー時、1回戦（隣り合う対戦ペア）で同門対決がゼロであること', () {
      final inputPlayers = [
        {'name': '佐藤', 'dojo': '東京道場'},
        {'name': '鈴木', 'dojo': '東京道場'},
        {'name': '高橋', 'dojo': '大阪道場'},
        {'name': '田中', 'dojo': '大阪道場'},
        {'name': '渡辺', 'dojo': '愛知道場'},
        {'name': '伊藤', 'dojo': '愛知道場'},
        {'name': '中村', 'dojo': '福岡道場'},
        {'name': '小林', 'dojo': '福岡道場'},
      ];

      final bracket = DojoCollisionAvoider.allocateBracket(inputPlayers);

      expect(bracket.length, 8);

      // 初戦ペア（インデックス 0 vs 1, 2 vs 3, 4 vs 5, 6 vs 7）を検査
      for (int i = 0; i < bracket.length; i += 2) {
        final player1 = bracket[i];
        final player2 = bracket[i + 1];

        // 初戦で同じ道場の選手同士が当たっていないこと！
        expect(
          player1['dojo'] == player2['dojo'],
          isFalse,
          reason:
              '初戦衝突検知: ${player1['name']}(${player1['dojo']}) vs ${player2['name']}(${player2['dojo']})',
        );
      }
    });
  });
}
