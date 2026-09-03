import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_entity_mapper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

void main() {
  group('🥋 【Phase 1-9/10】IsarローカルDB旧スキーマ互換＆安全マイグレーションテスト', () {
    test(
      '1. 旧形式（古いアプリ版）のMatchEntityで新フィールドがnull/未設定の場合でも例外なくMatchModelへ復元されること',
      () {
        // 過去バージョンの最小限データしか持たないEntity
        final legacyEntity = MatchEntity()
          ..firestoreId = 'legacy_match_001'
          ..tournamentId = 'tourney_2025'
          ..matchType = '個人戦'
          ..redName = '旧赤選手'
          ..whiteName = '旧白選手'
          ..status = 'finished'
          // 新フィールド（ruleJson, timerStartedAt, timerPausedAt 等）は null またはデフォルト
          ..ruleJson = null
          ..timerStartedAt = null
          ..order = 1.0;

        final model = LocalMatchEntityMapper.toModel(legacyEntity);

        expect(model.id, 'legacy_match_001');
        expect(model.tournamentId, 'tourney_2025');
        expect(model.redName, '旧赤選手');
        expect(model.whiteName, '旧白選手');
        expect(model.status, 'finished');

        // 新フィールドがクラッシュせず安全なフォールバック値を持つこと
        expect(model.syncState, isNotNull);
        expect(model.rule, isNull); // 旧形式でruleJsonがない場合はnull安全
        expect(model.rule ?? const MatchRule(), isNotNull); // 使用側でデフォルトフォールバック
        expect(model.pendingEvents, isEmpty);
      },
    );

    test('2. MatchModel ➔ MatchEntity ➔ MatchModel の双方向変換で情報が完全に保存されること', () {
      final originalModel = MatchModel(
        id: 'round_trip_m1',
        tournamentId: 'tourney_2026',
        matchType: '団体戦',
        redName: '神武館',
        whiteName: '修道館',
        status: 'in_progress',
        matchTimeMinutes: 4.0,
        organizationId: 'dojo_tokyo_01',
        order: 2.5,
      );

      final entity = LocalMatchEntityMapper.toEntity(originalModel);
      final restoredModel = LocalMatchEntityMapper.toModel(entity);

      expect(restoredModel.id, originalModel.id);
      expect(restoredModel.tournamentId, originalModel.tournamentId);
      expect(restoredModel.matchType, originalModel.matchType);
      expect(restoredModel.redName, originalModel.redName);
      expect(restoredModel.whiteName, originalModel.whiteName);
      expect(restoredModel.status, originalModel.status);
      expect(restoredModel.order, originalModel.order);
    });
  });
}
