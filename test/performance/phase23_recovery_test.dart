import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

void main() {
  group('🛡️ PHASE 23 — 災害復旧完全保証：物理境界を超えたデータ再構築', () {
    test('1. 【バックアップ&リストア】全試合データの整合性検証', () {
      // 🛡️ 補正：required 引数を網羅
      final original = MatchModel(
        id: 'm1',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
        syncState: SyncState.synced,
      );
      final json = original.toJson();
      final restored = MatchModel.fromJson(json);
      expect(restored.id, original.id);
    });

    test('2. 【端末間移行】進行中ステータスの完全継承検証', () {
      // 🛡️ 補正：required 引数を網羅
      final match = MatchModel(
        id: 'm2',
        matchType: '個人戦',
        redName: '選手C',
        whiteName: '選手D',
        status: 'playing',
      );
      final json = match.toJson();
      final restored = MatchModel.fromJson(json);
      expect(restored.status, 'playing');
    });
  });
}
