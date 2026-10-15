import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

void main() {
  group('[Governance] 永続化モデル・スキーママイグレーション＆フォールバック安全性ガバナンステスト', () {
    test('MatchModel: 空マップ・欠落JSONからでも安全にデフォルト値へフォールバックすること', () {
      final json = <String, dynamic>{
        'id': 'fallback_test_01',
        'matchType': '先鋒',
        'redName': '選手A',
        'whiteName': '選手B',
      };

      final model = MatchModel.fromJson(json);

      expect(model.id, 'fallback_test_01');
      expect(model.matchType, '先鋒');
      expect(model.redScore, 0);
      expect(model.whiteScore, 0);
      expect(model.status, 'waiting');
      expect(model.organizationId, 'default_org');
      expect(model.events, isEmpty);
      expect(model.snapshots, isEmpty);
      expect(model.syncState, SyncState.synced);
      expect(model.countForStandings, isTrue);
      expect(model.matchScene, 'honsen');
    });

    test('MatchModel: 未知のキーや旧スキーマデータが含まれていてもクラッシュしないこと', () {
      final legacyJson = <String, dynamic>{
        'id': 'legacy_match_99',
        'matchType': '大将',
        'redName': '赤選手',
        'whiteName': '白選手',
        'legacy_unknown_field_2024': 'obsolete_data',
        'isDirty': true,
        'remainingSeconds': 180,
      };

      expect(() => MatchModel.fromJson(legacyJson), returnsNormally);
      final model = MatchModel.fromJson(legacyJson);
      expect(model.id, 'legacy_match_99');
    });

    test('MatchRule: 新フィールド欠落時でも安全に初期値へフォールバックすること', () {
      final minimalRuleJson = <String, dynamic>{'matchTimeMinutes': 3.0};

      final rule = MatchRule.fromJson(minimalRuleJson);

      expect(rule.matchTimeMinutes, 3.0);
      expect(rule.isKataMatch, isFalse);
      expect(rule.isKachinuki, isFalse);
      expect(rule.hasHantei, isFalse);
    });

    test('MatchRule: 剣道形・勝ち抜き戦の新スキーマ値が安全に復元されること', () {
      final newRuleJson = <String, dynamic>{
        'isKataMatch': true,
        'hasHantei': true,
        'isKachinuki': true,
        'positions': ['打太刀', '仕太刀'],
      };

      final rule = MatchRule.fromJson(newRuleJson);

      expect(rule.isKataMatch, isTrue);
      expect(rule.hasHantei, isTrue);
      expect(rule.isKachinuki, isTrue);
      expect(rule.positions, ['打太刀', '仕太刀']);
    });
  });
}
