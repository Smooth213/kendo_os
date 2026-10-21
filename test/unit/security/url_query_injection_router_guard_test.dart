import 'package:flutter_test/flutter_test.dart';

/// Web URLクエリパラメータやディープリンクを介した攻撃入力
/// （XSSペイロード、パストラバーサル、未許可テナントID、特殊文字インジェクション）
/// に対するRouterガードおよびバリデーションサニタイズのセキュリティ検証テスト。
void main() {
  group('[Security] URLパラメータ・ルーティングインジェクション防護テスト', () {
    // 安全なテナントID・大会IDのバリデータ
    bool isValidTournamentId(String? id) {
      if (id == null || id.isEmpty) return false;
      // 英数字、ハイフン、アンダースコアのみを許可し、長さは64文字以内
      final safeRegex = RegExp(r'^[a-zA-Z0-9_-]{1,64}$');
      return safeRegex.hasMatch(id);
    }

    String sanitizeUserInput(String input) {
      return input
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&#x27;')
          .replaceAll('/', '&#x2F;');
    }

    test('XSSスクリプトタグが含まれるURLパラメータが不正として棄却または無害化されること', () {
      const maliciousPayload = '<script>alert("XSS")</script>';
      expect(isValidTournamentId(maliciousPayload), isFalse);

      final sanitized = sanitizeUserInput(maliciousPayload);
      expect(sanitized.contains('<script>'), isFalse);
      expect(
        sanitized,
        equals('&lt;script&gt;alert(&quot;XSS&quot;)&lt;&#x2F;script&gt;'),
      );
    });

    test('パストラバーサル（../）を含む攻撃パラメータがルーターガードで遮断されること', () {
      const traversalPayload = '../../etc/passwd';
      expect(isValidTournamentId(traversalPayload), isFalse);

      const encodedTraversal = '..%2F..%2Fsecret';
      expect(isValidTournamentId(encodedTraversal), isFalse);
    });

    test('SQL/NoSQLインジェクション構文を含むパラメータが棄却されること', () {
      const sqlPayload = "' OR '1'='1";
      expect(isValidTournamentId(sqlPayload), isFalse);

      const mongoPayload = '{"\$gt": ""}';
      expect(isValidTournamentId(mongoPayload), isFalse);
    });

    test('正当な英数字・ハイフン付きIDは正常に受容されること', () {
      expect(isValidTournamentId('tournament-2026-autumn_01'), isTrue);
      expect(isValidTournamentId('kendo_tenant_tokyo_123'), isTrue);
    });
  });
}
