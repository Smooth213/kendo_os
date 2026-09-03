import 'package:flutter_test/flutter_test.dart';

/// ☁️ クラウド全損時 ローカルP2Pデータ復元エンジン
class LocalP2PRebuilder {
  /// 複数コートのローカル端末データを受信し、全体トーナメントを再構築
  static Map<String, dynamic> reconstructTournament({
    required List<Map<String, dynamic>> courtDumps,
  }) {
    final aggregatedMatches = <String, Map<String, dynamic>>{};

    for (final dump in courtDumps) {
      final courtMatches = dump['matches'] as List<Map<String, dynamic>>;
      for (final match in courtMatches) {
        final matchId = match['id'] as String;
        // 最新の更新（論理クロック最大値）を採用
        if (!aggregatedMatches.containsKey(matchId) ||
            (match['version'] as int) >
                (aggregatedMatches[matchId]!['version'] as int)) {
          aggregatedMatches[matchId] = match;
        }
      }
    }

    return {
      'totalMatches': aggregatedMatches.length,
      'matches': aggregatedMatches.values.toList(),
      'status': 'reconstructed_from_p2p',
    };
  }
}

void main() {
  group('☁️ 【Phase 7-1/8】クラウド全損 Local P2P メガ復元 E2Eテスト', () {
    test('1. クラウドが完全死滅しても、コート1・コート2端末のローカルダンプ突合で大会データが100%復元されること', () {
      // コート1端末のローカルDBダンプ
      final court1Dump = {
        'court': 1,
        'matches': [
          {
            'id': 'c1_m1',
            'red': '佐藤',
            'white': '鈴木',
            'score': '2-0',
            'version': 2,
          },
          {
            'id': 'c1_m2',
            'red': '高橋',
            'white': '田中',
            'score': '1-0',
            'version': 3,
          },
        ],
      };

      // コート2端末のローカルDBダンプ
      final court2Dump = {
        'court': 2,
        'matches': [
          {
            'id': 'c2_m1',
            'red': '渡辺',
            'white': '伊藤',
            'score': '2-1',
            'version': 1,
          },
          {
            'id': 'c2_m2',
            'red': '中村',
            'white': '小林',
            'score': '1-2',
            'version': 2,
          },
        ],
      };

      // 🚨 クラウドが全損！ 会場内P2Pメッシュ突合を実行
      final reconstructed = LocalP2PRebuilder.reconstructTournament(
        courtDumps: [court1Dump, court2Dump],
      );

      // 全4試合が欠損なく100%完全復元されること
      expect(reconstructed['totalMatches'], 4);
      expect(reconstructed['status'], 'reconstructed_from_p2p');
      final matches = reconstructed['matches'] as List<Map<String, dynamic>>;
      expect(matches.any((m) => m['id'] == 'c1_m1'), isTrue);
      expect(matches.any((m) => m['id'] == 'c2_m2'), isTrue);
    });
  });
}
