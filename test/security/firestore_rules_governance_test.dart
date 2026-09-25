import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔒 【ガバナンス第4条】Firestore セキュリティルール＆ロール権限 監査テスト', () {
    late String rulesContent;

    setUpAll(() {
      final file = File('firestore.rules');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'firestore.rules がプロジェクトルートに存在すること',
      );
      rulesContent = file.readAsStringSync();
    });

    test('1. Firestore Security Rules Version 2 が宣言されていること', () {
      expect(rulesContent.contains("rules_version = '2';"), isTrue);
    });

    test('2. 道場マルチテナント (/organizations/{dojoId}) による空間隔離が定義されていること', () {
      expect(rulesContent.contains('match /organizations/{dojoId}'), isTrue);
    });

    test('3. ロール権限解決関数 getUserRole() が定義され、未認証リクエストを遮断していること', () {
      expect(rulesContent.contains('function getUserRole()'), isTrue);
      expect(rulesContent.contains('request.auth != null'), isTrue);
    });

    test('4. 危険な全開放ルール (if true;) が存在しないこと', () {
      expect(rulesContent.contains('if true;'), isFalse);
      expect(rulesContent.contains('if true ;'), isFalse);
    });

    test('5. 監査ログ (/audit_logs/{logId}) の閲覧が管理者ロールに制限されていること', () {
      expect(rulesContent.contains('match /audit_logs/{logId}'), isTrue);
      expect(
        rulesContent.contains(
          "getUserRole() in ['admin', 'Admin', 'owner', 'Owner']",
        ),
        isTrue,
      );
    });
  });
}
