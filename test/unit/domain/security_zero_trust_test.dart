import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/entities/role_permission.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';

void main() {
  group('🔒 Zero Trust Security Tests', () {
    
    group('1. PermissionService (アクセス認可)', () {
      final permission = PermissionService();
      final viewer = const User(id: 'v1', role: Role.viewer, organizationId: 'o1');
      final scorer = const User(id: 's1', role: Role.scorer, organizationId: 'o1');
      final event = ScoreEventLegacyAdapter.fromLegacy(side: Side.red, type: PointType.men);

      test('Viewerはスコアを追加できないこと', () {
        expect(permission.canAppend(viewer, event), isFalse);
      });

      test('Scorerはスコアを追加できること', () {
        expect(permission.canAppend(scorer, event), isTrue);
      });
    });

    group('2. Event Signature (改ざん防止署名)', () {
      test('正規のルートで生成されたイベントは検証をパスすること', () {
        final event = ScoreEventLegacyAdapter.fromLegacy(side: Side.red, type: PointType.men, userId: 'u1');
        final isValid = ScoreEventLegacyAdapter.verifySignature(event, 'kendo_os_secret_key_v1');
        expect(isValid, isTrue);
      });

      test('他人のIDを騙って userId を改ざんすると署名検証に失敗すること', () {
        final event = ScoreEventLegacyAdapter.fromLegacy(side: Side.red, type: PointType.men, userId: 'u1');
        // ハッカーがIDを改ざん
        final tamperedEvent = event.copyWith(userId: 'hacker_999');
        
        final isValid = ScoreEventLegacyAdapter.verifySignature(tamperedEvent, 'kendo_os_secret_key_v1');
        expect(isValid, isFalse);
      });

      // ==========================================
      // ★ あえて仕込んだ「脆弱性検知」テスト
      // ==========================================
      test('【脆弱性検知】イベントの「技の種類」や「赤白」を改ざんした場合、署名検証に失敗するべき', () {
        final event = ScoreEventLegacyAdapter.fromLegacy(side: Side.red, type: PointType.men, userId: 'u1');
        
        // ハッカーが通信の途中で「赤のメン」を「白の反則」に改ざんして保存しようとしたとする
        final tamperedEvent = event.copyWith(side: Side.white, isHansoku: true);
        
        final isValid = ScoreEventLegacyAdapter.verifySignature(tamperedEvent, 'kendo_os_secret_key_v1');
        
        // 本来は改ざん検知されて false になるべき！
        expect(isValid, isFalse, reason: 'スコアの内容が改ざんされたら署名は無効になるべきです');
      });
    });
  });
}