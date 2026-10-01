import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_signature_verifier.dart';

void main() {
  group('[Governance] スコアイベント電子署名および改ざん隔離ガバナンステスト', () {
    test('スコアイベント電子署名検証において 正当な署名付きイベントが完全検証を通過すること', () {
      final now = DateTime.now();
      final validEvent = ScoreEventLegacyAdapter.fromLegacy(
        type: PointType.men,
        side: Side.red,
        id: 'gov-evt-001',
        timestamp: now,
        userId: 'referee-1',
      );

      final isSignatureValid = ScoreEventLegacyAdapter.verifySignature(
        validEvent,
        'kendo_os_secret_key_v1',
      );
      expect(isSignatureValid, isTrue);

      final match = MatchModel(
        id: 'gov-match-001',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
        events: [validEvent],
      );

      final verifier = MatchSignatureVerifier(<String>{});
      final hasTampered = verifier.verify(match, allowQuarantine: false);
      expect(hasTampered, isFalse);
    });

    test('悪意ある改ざん検知において 改ざんされたスコアイベント投入時に例外が送出されること', () {
      final now = DateTime.now();
      final validEvent = ScoreEventLegacyAdapter.fromLegacy(
        type: PointType.men,
        side: Side.red,
        id: 'gov-evt-002',
        timestamp: now,
        userId: 'referee-1',
      );

      // 署名と矛盾する改ざんイベント（技や署名を偽装）
      final tamperedEvent = validEvent.copyWith(strikeType: StrikeType.kote);

      final match = MatchModel(
        id: 'gov-match-002',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
        events: [tamperedEvent],
      );

      final verifier = MatchSignatureVerifier(<String>{});
      expect(
        () => verifier.verify(match, allowQuarantine: false),
        throwsA(isA<TamperedEventException>()),
      );
    });

    test('クランティン隔離モードにおいて 隔離フラグ有効時に例外を送出せず改ざん検知フラグを返却すること', () {
      final now = DateTime.now();
      final tamperedEvent = ScoreEvent(
        id: 'gov-evt-003',
        side: Side.white,
        strikeType: StrikeType.men,
        timestamp: now,
        signature: 'invalid_forged_signature_token',
      );

      final match = MatchModel(
        id: 'gov-match-003',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
        events: [tamperedEvent],
      );

      final verifier = MatchSignatureVerifier(<String>{});
      final hasTampered = verifier.verify(match, allowQuarantine: true);
      expect(hasTampered, isTrue);
    });

    test('署名検証キャッシュにおいて 5000件超過時にLRUクリアが安全に実行されること', () {
      final cacheSet = <String>{};
      for (int i = 0; i < 5001; i++) {
        cacheSet.add('cached_key_$i');
      }
      expect(cacheSet.length, 5001);

      final verifier = MatchSignatureVerifier(cacheSet);

      final validEvent = ScoreEventLegacyAdapter.fromLegacy(
        type: PointType.men,
        side: Side.red,
        id: 'gov-evt-cache-test',
        timestamp: DateTime.now(),
        userId: 'referee-1',
      );

      final match = MatchModel(
        id: 'gov-match-004',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
        events: [validEvent],
      );

      verifier.verify(match, allowQuarantine: false);

      // 5000件を超過したため一旦クリアされ、現在のイベント1件のみが追加されていること
      expect(cacheSet.length, 1);
      expect(
        cacheSet.contains('${validEvent.id}_${validEvent.signature}'),
        isTrue,
      );
    });
  });
}
