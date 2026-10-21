import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Firebase Cloud Storage セキュリティルールの堅牢性とガバナンス遵守の検証テスト。
/// 未認証公開（if true）の脆弱性が存在しないこと、認証必須またはテナント防護が定義されていることを保証する。
void main() {
  group('[Security] Firebase Storage セキュリティルール・ガバナンス検証テスト', () {
    final rulesFile = File('storage.rules');

    test('storage.rules がプロジェクトルートに存在し、有効なバージョン定義を持つこと', () {
      expect(rulesFile.existsSync(), isTrue, reason: 'storage.rules が見つかりません');
      final content = rulesFile.readAsStringSync();
      expect(
        content.contains("rules_version = '2';"),
        isTrue,
        reason: 'ルールバージョン2が指定されていません',
      );
      expect(
        content.contains('service firebase.storage'),
        isTrue,
        reason: 'firebase.storageサービスが定義されていません',
      );
    });

    test('無認証での完全公開（if true）の脆弱性ルールが存在しないこと', () {
      final content = rulesFile.readAsStringSync();
      // "if true;" または "if true " が存在しないことを検証
      final lines = content.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('//')) continue;
        expect(
          trimmed.contains('if true;') || trimmed.contains('if true '),
          isFalse,
          reason: '無条件公開ルールが検知されました: $trimmed',
        );
      }
    });

    test('書き込みおよび読み取り操作に対して認証チェック（request.auth != null）が要求されていること', () {
      final content = rulesFile.readAsStringSync();
      expect(
        content.contains('request.auth != null') ||
            content.contains('request.auth.uid'),
        isTrue,
        reason: '認証ガード（request.auth != null）が設定されていません',
      );
    });
  });
}
