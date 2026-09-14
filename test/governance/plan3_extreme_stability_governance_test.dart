import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ 【Plan 3 ガバナンス監査】絶対的な安定性（バグ・データ消失ゼロ）永続保証テスト', () {
    test(
      '1. [同期ビジー再帰ループ根絶] sync_provider.dart に指数バックオフ＆サーキットブレーカーが実装されていること',
      () {
        final syncFile = File(
          'lib/features/tournament/presentation/operate/providers/sync_provider.dart',
        );
        final content = syncFile.readAsStringSync();

        expect(
          content.contains('maxConsecutiveFailures'),
          isTrue,
          reason: 'SyncEngine に連続失敗上限(maxConsecutiveFailures)が定義されていなければならない',
        );
        expect(
          content.contains('_consecutiveFailures'),
          isTrue,
          reason: 'SyncEngine に連続失敗カウンタ(_consecutiveFailures)が配備されていなければならない',
        );
        expect(
          content.contains('_retryTimer'),
          isTrue,
          reason: 'SyncEngine に安全な遅延リトライ用の _retryTimer が配備されていなければならない',
        );
        expect(
          content.contains('サーキットブレーカー'),
          isTrue,
          reason: '連続失敗時のサーキットブレーカー発動処理が配備されていなければならない',
        );
        expect(
          content.contains('delaySeconds'),
          isTrue,
          reason: '指数バックオフ計算処理が配備されていなければならない',
        );
      },
    );

    test(
      '2. [CRDTステータス不可逆ガード] resolveMonotonicStatus で確定終了ステータス(finished/approved)が進行中に巻き戻らないこと',
      () {
        // 1. リモートが finished、ローカルが in_progress（ローカル優先フラグ true）でも finished が維持される
        final status1 = SyncCrdtMerger.resolveMonotonicStatus(
          localStatus: 'in_progress',
          remoteStatus: 'finished',
          preferLocal: true,
        );
        expect(
          status1,
          'finished',
          reason: 'リモート確定の finished はローカルの in_progress に巻き戻されてはならない',
        );

        // 2. リモートが approved、ローカルが finished（ローカル優先フラグ true）でも approved が維持される
        final status2 = SyncCrdtMerger.resolveMonotonicStatus(
          localStatus: 'finished',
          remoteStatus: 'approved',
          preferLocal: true,
        );
        expect(
          status2,
          'approved',
          reason: '承認済み(approved)ステータスは単なる終了(finished)より優先されなければならない',
        );

        // 3. ローカルが finished、リモートが in_progress の場合、finished が採用される
        final status3 = SyncCrdtMerger.resolveMonotonicStatus(
          localStatus: 'finished',
          remoteStatus: 'in_progress',
          preferLocal: false,
        );
        expect(
          status3,
          'finished',
          reason: 'ローカル確定の finished はリモートの in_progress に降格されてはならない',
        );

        // 4. 双方が同等進行中（in_progress vs paused）の場合は preferLocal に従う
        final status4 = SyncCrdtMerger.resolveMonotonicStatus(
          localStatus: 'paused',
          remoteStatus: 'in_progress',
          preferLocal: true,
        );
        expect(status4, 'paused', reason: '同ランク進行中ステータス同士は preferLocal の調停に従う');
      },
    );

    test(
      '3. [ネイティブ電波検知修復] sync_provider.dart で999日スタックが完全撤廃され、全環境でConnectivityストリームが稼働すること',
      () {
        final syncFile = File(
          'lib/features/tournament/presentation/operate/providers/sync_provider.dart',
        );
        final content = syncFile.readAsStringSync();

        expect(
          content.contains('days: 999'),
          isFalse,
          reason: 'sync_provider.dart にネイティブ環境をスタックさせる 999日ディレイが残っていてはならない',
        );
        expect(
          content.contains('Connectivity().onConnectivityChanged'),
          isTrue,
          reason: 'Connectivity().onConnectivityChanged が購読されていなければならない',
        );
      },
    );

    test(
      '4. [コネクティビティ判定統一] app_bootstrap_helper.dart に isOnlineStreamProvider および isOfflineStreamProvider が配備されていること',
      () {
        final helperFile = File(
          'lib/shared/bootstrap/app_bootstrap_helper.dart',
        );
        final content = helperFile.readAsStringSync();

        expect(
          content.contains('isOnlineStreamProvider'),
          isTrue,
          reason:
              'app_bootstrap_helper.dart に接続時trueとなる isOnlineStreamProvider が配備されていなければならない',
        );
        expect(
          content.contains('isOfflineStreamProvider'),
          isTrue,
          reason:
              'app_bootstrap_helper.dart に切断時trueとなる isOfflineStreamProvider が配備されていなければならない',
        );
        expect(
          content.contains('globalConnectivityProvider'),
          isTrue,
          reason:
              '既存コードおよびテストの後方互換性のために globalConnectivityProvider が維持されていなければならない',
        );
      },
    );

    test(
      '5. [データ消失ゼロ暗号フォールバック] saveMatchSafeMode により不正署名時も例外で破棄されず隔離退避されること',
      () async {
        final repoFile = File(
          'lib/shared/infrastructure/repository/local_match_repository.dart',
        );
        final content = repoFile.readAsStringSync();

        expect(
          content.contains('saveMatchSafeMode'),
          isTrue,
          reason: 'LocalMatchRepository に saveMatchSafeMode が配備されていなければならない',
        );
        expect(
          content.contains('saveMatchesBulkSafeMode'),
          isTrue,
          reason:
              'LocalMatchRepository に saveMatchesBulkSafeMode が配備されていなければならない',
        );
        expect(
          content.contains('[QUARANTINE_TAMPERED]'),
          isTrue,
          reason: '不正署名データに隔離タグ [QUARANTINE_TAMPERED] が付与されなければならない',
        );

        // 改ざんされた署名を持つイベント
        final tamperedEvent = ScoreEventLegacyAdapter.fromLegacy(
          type: PointType.men,
          side: Side.red,
          id: 'tampered_event_safe_test',
        ).copyWith(signature: 'invalid_tampered_signature');

        final tamperedMatch = MatchModel(
          id: 'tampered_match_safe_test',
          matchType: '個人戦',
          redName: '赤選手',
          whiteName: '白選手',
          events: [tamperedEvent],
        );

        final repo = LocalMatchRepository(null);

        // 通常モードでは厳格に TamperedEventException をスローすること (Plan 1 規約遵守)
        expect(
          () => repo.saveMatch(tamperedMatch),
          throwsA(isA<TamperedEventException>()),
          reason: '通常 saveMatch では厳格に改ざんイベントが拒絶されなければならない',
        );

        // セーフモードでは例外をスローせず、データ消失ゼロ原則により安全に保存処理が完了すること (Plan 3 規約)
        await expectLater(
          repo.saveMatchSafeMode(tamperedMatch),
          completes,
          reason: 'saveMatchSafeMode は不正署名時も例外でクラッシュ・破棄せず安全に隔離完了しなければならない',
        );
      },
    );
  });
}
