import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_signature_verifier.dart';

void main() {
  group('[Unit] 試合署名検証器 単体テスト', () {
    test('正常署名検証において 正当な署名を持つイベントが正常に検証通過すること', () {
      final now = DateTime.now();
      final event1 = ScoreEventLegacyAdapter.fromLegacy(
        type: PointType.men,
        side: Side.red,
        id: 'evt-sig-1',
        timestamp: now,
        userId: 'ref-101',
      );
      final event2 = ScoreEventLegacyAdapter.fromLegacy(
        type: PointType.kote,
        side: Side.white,
        id: 'evt-sig-2',
        timestamp: now.add(const Duration(seconds: 10)),
        userId: 'ref-101',
      );

      final match = MatchModel(
        id: 'match-sig-1',
        matchType: '個人戦',
        redName: '選手赤',
        whiteName: '選手白',
        events: [event1, event2],
      );

      final cache = <String>{};
      final verifier = MatchSignatureVerifier(cache);

      final hasTampered = verifier.verify(match, allowQuarantine: false);
      expect(hasTampered, isFalse);
      expect(cache.length, 2);
    });

    test('改ざんスコア検出において 署名不一致イベント投入時にTamperedEventExceptionが送出されること', () {
      final now = DateTime.now();
      final legitimateEvent = ScoreEventLegacyAdapter.fromLegacy(
        type: PointType.men,
        side: Side.red,
        id: 'evt-sig-3',
        timestamp: now,
        userId: 'ref-101',
      );

      final tamperedEvent = legitimateEvent.copyWith(
        strikeType: StrikeType.dou,
      );

      final match = MatchModel(
        id: 'match-sig-2',
        matchType: '個人戦',
        redName: '選手赤',
        whiteName: '選手白',
        events: [tamperedEvent],
      );

      final verifier = MatchSignatureVerifier(<String>{});
      expect(
        () => verifier.verify(match, allowQuarantine: false),
        throwsA(isA<TamperedEventException>()),
      );
    });

    test('クランティン隔離モードにおいて 隔離モード有効時は例外を送出せず改ざんフラグが返却されること', () {
      final now = DateTime.now();
      final tamperedEvent = ScoreEvent(
        id: 'evt-sig-4',
        side: Side.red,
        strikeType: StrikeType.tsuki,
        timestamp: now,
        signature: 'corrupted_or_forged_hash',
      );

      final match = MatchModel(
        id: 'match-sig-3',
        matchType: '個人戦',
        redName: '選手赤',
        whiteName: '選手白',
        events: [tamperedEvent],
      );

      final verifier = MatchSignatureVerifier(<String>{});
      final hasTampered = verifier.verify(match, allowQuarantine: true);
      expect(hasTampered, isTrue);
    });

    test('キャッシュメモリ保護において 5000件超過時にキャッシュが自動クリアされ最新値のみ保持されること', () {
      final cache = <String>{};
      for (int i = 0; i < 5005; i++) {
        cache.add('prev-key-$i');
      }

      final verifier = MatchSignatureVerifier(cache);

      final now = DateTime.now();
      final validEvent = ScoreEventLegacyAdapter.fromLegacy(
        type: PointType.men,
        side: Side.red,
        id: 'evt-sig-lru',
        timestamp: now,
        userId: 'ref-101',
      );

      final match = MatchModel(
        id: 'match-sig-4',
        matchType: '個人戦',
        redName: '選手赤',
        whiteName: '選手白',
        events: [validEvent],
      );

      verifier.verify(match, allowQuarantine: false);
      expect(cache.length, 1);
      expect(cache.first, '${validEvent.id}_${validEvent.signature}');
    });
  });
}
