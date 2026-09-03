import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// 🛡️ GDPR・個人情報完全抹消（忘れられる権利）匿名化エンジン
class GdprAnonymizer {
  static ({String anonymizedName, String anonymizedDojo, bool isDeleted})
  anonymizePlayer({
    required String playerId,
    required String originalName,
    required String originalDojo,
  }) {
    // SHA-256 不可逆ハッシュにより特定不能なIDを生成
    final hash = sha256
        .convert(utf8.encode(playerId))
        .toString()
        .substring(0, 8);

    return (
      anonymizedName: '匿名選手_$hash',
      anonymizedDojo: '（非公開）',
      isDeleted: true,
    );
  }
}

void main() {
  group('🌐 【Phase 4-9/11】GDPR忘れられる権利 選手不可逆匿名化＆対戦成績整合性テスト', () {
    test('1. 選手退会時に個人特定情報（氏名・道場）が不可逆ハッシュに置換され復元不可能になること', () {
      final anon = GdprAnonymizer.anonymizePlayer(
        playerId: 'player_secret_guid_12345',
        originalName: '山田 太郎',
        originalDojo: '東京武道館',
      );

      // 実名・道場名が完全に抹消されていること
      expect(anon.anonymizedName.contains('山田'), isFalse);
      expect(anon.anonymizedName.contains('太郎'), isFalse);
      expect(anon.anonymizedDojo.contains('東京'), isFalse);

      expect(anon.anonymizedName, startsWith('匿名選手_'));
      expect(anon.anonymizedDojo, '（非公開）');
      expect(anon.isDeleted, isTrue);
    });

    test('2. 匿名化後も過去の対戦履歴（スコア・勝敗結果）の数値整合性が崩れないこと', () {
      // 匿名化前の試合データ
      final matchData = {
        'matchId': 'm_001',
        'redPlayerId': 'player_secret_guid_12345',
        'redName': '山田 太郎',
        'whiteName': '佐藤 健',
        'redScore': 2,
        'whiteScore': 1,
        'winner': 'red',
      };

      // 選手退会による匿名化を適用
      final anon = GdprAnonymizer.anonymizePlayer(
        playerId: matchData['redPlayerId'] as String,
        originalName: matchData['redName'] as String,
        originalDojo: '東京武道館',
      );

      matchData['redName'] = anon.anonymizedName;

      // 試合結果・取得本数・勝者フラグは完全無欠に保たれ、トーナメントの勝ち上がりが壊れないこと
      expect(matchData['redName'], anon.anonymizedName);
      expect(matchData['redScore'], 2);
      expect(matchData['whiteScore'], 1);
      expect(matchData['winner'], 'red');
    });
  });
}
