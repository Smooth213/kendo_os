import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// 🛡️ ブロックチェーン型 監査ハッシュチェーンブロック
class AuditLogBlock {
  final int index;
  final String action;
  final String prevHash;
  final String hash;

  AuditLogBlock({
    required this.index,
    required this.action,
    required this.prevHash,
  }) : hash = calculateHash(index, action, prevHash);

  static String calculateHash(int index, String action, String prevHash) {
    final payload = '$index:$action:$prevHash';
    return sha256.convert(utf8.encode(payload)).toString();
  }
}

/// チェーン完全性検証ヘルパー
bool verifyChain(List<AuditLogBlock> blocks) {
  for (int i = 1; i < blocks.length; i++) {
    final current = blocks[i];
    final prev = blocks[i - 1];
    if (current.prevHash != prev.hash) {
      return false;
    }
    if (current.hash !=
        AuditLogBlock.calculateHash(
          current.index,
          current.action,
          current.prevHash,
        )) {
      return false;
    }
  }
  return true;
}

void main() {
  group('👁️ 【Phase 6-10/12】監査ログハッシュチェーン 事後改ざん不可逆検知テスト', () {
    test('1. 正常なハッシュチェーンが検証に合格すること', () {
      final chain = <AuditLogBlock>[];

      // Genesis Block
      chain.add(AuditLogBlock(index: 0, action: '大会開始', prevHash: '0'));
      // Block 1
      chain.add(
        AuditLogBlock(index: 1, action: '赤面一本', prevHash: chain.last.hash),
      );
      // Block 2
      chain.add(
        AuditLogBlock(index: 2, action: '白小手一本', prevHash: chain.last.hash),
      );

      expect(verifyChain(chain), isTrue);
    });

    test('2. 過去ログ（赤面 ➔ 赤胴）が改ざんされた場合、即座に不一致が検知されること', () {
      final chain = <AuditLogBlock>[];
      chain.add(AuditLogBlock(index: 0, action: '大会開始', prevHash: '0'));
      chain.add(
        AuditLogBlock(index: 1, action: '赤面一本', prevHash: chain.last.hash),
      );
      chain.add(
        AuditLogBlock(index: 2, action: '試合終了', prevHash: chain.last.hash),
      );

      // 🚨 悪意あるユーザーがBlock 1の内容を「赤胴一本」に改ざん！
      final tamperedBlock1 = AuditLogBlock(
        index: 1,
        action: '赤胴一本（改ざん）',
        prevHash: chain[0].hash,
      );

      final tamperedChain = [chain[0], tamperedBlock1, chain[2]];

      // 改ざんされたチェーンの検証が偽（不整合）を返すこと
      expect(verifyChain(tamperedChain), isFalse);
      expect(chain[2].prevHash == tamperedBlock1.hash, isFalse);
    });
  });
}
