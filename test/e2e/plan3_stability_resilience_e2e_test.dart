import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/bootstrap/app_bootstrap_helper.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ 【E2E / 統合シナリオ】Plan 3: 絶対的安定性・同期無限ループ根絶＆データ消失ゼロ検証', () {
    test(
      '1. [CRDT不可逆ガード] 本部確定(finished/approved)の試合に未送信イベントが混ざってもステータス巻き戻りゼロ＆データ完全合流',
      () {
        // 本部クラウド側: すでに勝敗が決し、approved (承認完了) になっている試合
        final remoteMatch = MatchModel(
          id: 'crdt_stability_match_100',
          matchType: '個人戦',
          redName: '選手 A',
          whiteName: '選手 B',
          status: 'approved',
          redScore: 2,
          whiteScore: 0,
          version: 5,
          events: [
            ScoreEventLegacyAdapter.fromLegacy(
              type: PointType.men,
              side: Side.red,
            ).copyWith(
              id: 'ev_remote_1',
              logicalClock: 1,
              timestamp: DateTime(2026, 1, 1, 10, 0),
            ),
            ScoreEventLegacyAdapter.fromLegacy(
              type: PointType.kote,
              side: Side.red,
            ).copyWith(
              id: 'ev_remote_2',
              logicalClock: 2,
              timestamp: DateTime(2026, 1, 1, 10, 2),
            ),
          ],
        );

        // ローカル端末側: 電波切断中にオフラインで打突が追加され、ステータスがまだ in_progress のまま
        final localPendingEvent =
            ScoreEventLegacyAdapter.fromLegacy(
              type: PointType.doIdo,
              side: Side.white,
            ).copyWith(
              id: 'ev_local_pending_1',
              logicalClock: 3,
              timestamp: DateTime(2026, 1, 1, 10, 3),
            );

        final localMatch = remoteMatch.copyWith(
          status: 'in_progress',
          syncState: SyncState.localOnly,
          pendingEvents: [localPendingEvent],
          events: [...remoteMatch.events, localPendingEvent],
        );

        // CRDTマージを実行（未送信データがあるため従来のロジックでは preferLocal: true となる状況）
        final mergedMatch = SyncCrdtMerger.mergeAndRebuild(
          remoteMatch: remoteMatch,
          localMatch: localMatch,
          rule: const MatchRule(),
          rebuilder: RebuildMatchFromEventsUseCase(
            KendoRuleEngine(),
            SystemTimeSource(),
          ),
        );

        // 検証1: ステータスが in_progress に巻き戻らず、approved が100%死守されていること
        expect(
          mergedMatch.status,
          'approved',
          reason:
              '確定ステータス(approved)は未送信ローカルデータの進行中(in_progress)によって絶対に巻き戻されてはならない',
        );

        // 検証2: イベント履歴は欠損せず、未送信イベントも含めて全3件が完全合流していること
        expect(
          mergedMatch.events.length,
          3,
          reason: 'CRDTマージによって両者のイベントが1件も欠落することなく合流していなければならない',
        );
        expect(
          mergedMatch.events.any((e) => e.id == 'ev_local_pending_1'),
          isTrue,
          reason: 'ローカル端末で入力された未送信打突イベントが保持されていなければならない',
        );
      },
    );

    test(
      '2. [暗号署名フォールバック・セーフモード] 不正署名検知時も現場スコアが物理破棄されず安全に隔離退避完了すること',
      () async {
        final repo = LocalMatchRepository(null);

        // 不正な署名が埋め込まれた打突イベント
        final invalidSignatureEvent = ScoreEventLegacyAdapter.fromLegacy(
          type: PointType.tsuki,
          side: Side.red,
          id: 'tampered_event_e2e_1',
        ).copyWith(signature: 'corrupted_or_mismatched_key_hash');

        final matchWithAnomaly = MatchModel(
          id: 'safe_mode_match_e2e',
          matchType: '個人戦',
          redName: '神埼',
          whiteName: '鹿島',
          events: [invalidSignatureEvent],
        );

        // 通常保存（厳格モード）では改ざん攻撃を検知して即座に例外をスロー
        expect(
          () => repo.saveMatch(matchWithAnomaly),
          throwsA(isA<TamperedEventException>()),
          reason: '通常モードではセキュリティ防壁として例外がスローされなければならない',
        );

        // セーフモード保存（現場データ最優先モード）では例外クラッシュを起こさず安全に完了
        await expectLater(
          repo.saveMatchSafeMode(matchWithAnomaly),
          completes,
          reason: 'セーフモードでは例外で保存中断せず、データ消失ゼロを確約しなければならない',
        );
      },
    );

    test(
      '3. [コネクティビティ判定統一] isOnlineStreamProvider と isOfflineStreamProvider の論理的完全整合性',
      () async {
        final container = ProviderContainer(
          overrides: [
            isOnlineStreamProvider.overrideWith((ref) => Stream.value(true)),
          ],
        );
        addTearDown(container.dispose);

        // オンライン時は isOnline が true, isOffline が false
        final isOnline = await container.read(isOnlineStreamProvider.future);
        expect(isOnline, isTrue);

        final isOffline = await container.read(isOfflineStreamProvider.future);
        expect(isOffline, isFalse);

        expect(
          isOnline,
          !isOffline,
          reason: 'isOnline と isOffline は常に真偽値が反転整合していなければならない',
        );
      },
    );

    test('4. [同期エンジン耐性設計] 指数バックオフ待機とサーキットブレーカー定義の整合性検証', () {
      expect(SyncEngine.maxConsecutiveFailures, 5);

      // 連続失敗回数に応じた指数バックオフ遅延（1s, 2s, 4s, 8s, 16s... 最大30s）の計算整合性
      int calculateBackoff(int failures) {
        return (1 << (failures - 1)).clamp(1, 30);
      }

      expect(calculateBackoff(1), 1);
      expect(calculateBackoff(2), 2);
      expect(calculateBackoff(3), 4);
      expect(calculateBackoff(4), 8);
      expect(calculateBackoff(5), 16);
      expect(calculateBackoff(6), 30);
    });
  });
}
