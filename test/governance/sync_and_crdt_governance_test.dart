import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🌐 【第16条 ガバナンス監査】分散同期整合性・Clock Skew補正 ＆ CRDT調停規約', () {
    test(
      'Rule 1: [Clock Skew時刻補正] server_clock_offset_service.dart ＆ system_time_source.dart による端末時計ズレ補正規約',
      () {
        final serviceFile = File(
          'lib/shared/time/server_clock_offset_service.dart',
        );
        expect(serviceFile.existsSync(), isTrue);
        final serviceContent = serviceFile.readAsStringSync();
        expect(
          serviceContent.contains('class ServerClockOffsetService'),
          isTrue,
        );
        expect(serviceContent.contains('Duration get offset'), isTrue);

        final timeSourceFile = File('lib/shared/time/system_time_source.dart');
        expect(timeSourceFile.existsSync(), isTrue);
        final timeSourceContent = timeSourceFile.readAsStringSync();
        expect(timeSourceContent.contains('ServerClockOffsetService'), isTrue);
        expect(timeSourceContent.contains('.add(offset)'), isTrue);
      },
    );

    test(
      'Rule 2: [CRDT 3者マージ＆LWW調停] sync_crdt_merger.dart における 3者（リモート確定・ローカル確定・ローカル未送信）マージ ＆ LWWタイマー調停規約',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/providers/sync_crdt_merger.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(content.contains('remoteMatch.events'), isTrue);
        expect(content.contains('localMatch.events'), isTrue);
        expect(content.contains('localMatch.pendingEvents'), isTrue);
        expect(content.contains('preferLocal'), isTrue);
        expect(content.contains('chosenTimerStartedAt'), isTrue);
      },
    );

    test(
      'Rule 3: [CRDTステータス不可逆ガード] resolveMonotonicStatus で確定終了ステータス(finished/approved)が進行中に巻き戻らないこと',
      () {
        final status1 = SyncCrdtMerger.resolveMonotonicStatus(
          localStatus: 'in_progress',
          remoteStatus: 'finished',
          preferLocal: true,
        );
        expect(status1, 'finished');

        final status2 = SyncCrdtMerger.resolveMonotonicStatus(
          localStatus: 'finished',
          remoteStatus: 'approved',
          preferLocal: true,
        );
        expect(status2, 'approved');

        final status3 = SyncCrdtMerger.resolveMonotonicStatus(
          localStatus: 'finished',
          remoteStatus: 'in_progress',
          preferLocal: false,
        );
        expect(status3, 'finished');

        final status4 = SyncCrdtMerger.resolveMonotonicStatus(
          localStatus: 'paused',
          remoteStatus: 'in_progress',
          preferLocal: true,
        );
        expect(status4, 'paused');
      },
    );

    test(
      'Rule 4: [同期ビジー再帰ループ根絶] sync_provider.dart に指数バックオフ＆サーキットブレーカーが実装されていること',
      () {
        final syncFile = File(
          'lib/features/tournament/presentation/operate/providers/sync_provider.dart',
        );
        expect(syncFile.existsSync(), isTrue);
        final content = syncFile.readAsStringSync();

        expect(content.contains('maxConsecutiveFailures'), isTrue);
        expect(content.contains('_consecutiveFailures'), isTrue);
        expect(content.contains('_retryTimer'), isTrue);
        expect(content.contains('サーキットブレーカー'), isTrue);
        expect(content.contains('delaySeconds'), isTrue);
      },
    );

    test(
      'Rule 5: [ライフサイクル同期一元化] main.dart 重複同期排除 ＆ sync_provider.dart 一元化規約',
      () {
        final mainFile = File('lib/main.dart');
        final syncProviderFile = File(
          'lib/features/tournament/presentation/operate/providers/sync_provider.dart',
        );

        expect(mainFile.existsSync(), isTrue);
        expect(syncProviderFile.existsSync(), isTrue);

        expect(
          mainFile.readAsStringSync().contains('didChangeAppLifecycleState'),
          isFalse,
        );
        expect(
          syncProviderFile.readAsStringSync().contains('AppLifecycleListener'),
          isTrue,
        );
      },
    );

    test(
      'Rule 6: [Firestoreリスナー一元化＆O(1)直結] scoreboard.dart 階層パス監視優先 ＆ 重複リスナー排除規約',
      () {
        final scoreboardFile = File('lib/shared/widgets/scoreboard.dart');
        expect(scoreboardFile.existsSync(), isTrue);
        final scoreboardContent = scoreboardFile.readAsStringSync();

        expect(
          scoreboardContent.contains('.collection(\'organizations\')') &&
              scoreboardContent.contains('.collection(\'tournaments\')') &&
              scoreboardContent.contains('.collection(\'matches\')'),
          isTrue,
        );

        final matchListFile = File(
          'lib/features/tournament/presentation/operate/providers/match_list_provider.dart',
        );
        expect(matchListFile.existsSync(), isTrue);
        final matchContent = matchListFile.readAsStringSync();
        expect(
          matchContent.contains('matchesCollection.snapshots().listen'),
          isFalse,
        );
        expect(
          matchContent.contains('watchLocalMatches(tournamentId)'),
          isTrue,
        );
      },
    );

    test(
      'Rule 7: [Webステート保護＆FSM状態遷移＆コネクティビティ統一] 大会ID切替ステートリセット、FSM遷移、ネットワーク判定統一規約',
      () {
        final listFile = File(
          'lib/features/tournament/presentation/operate/providers/match_list_provider.dart',
        );
        expect(listFile.existsSync(), isTrue);
        final listContent = listFile.readAsStringSync();
        expect(
          listContent.contains('activeWebTournamentId != safeTournamentId'),
          isTrue,
        );
        expect(
          listContent.contains('m.tournamentId == currentTournamentId'),
          isTrue,
        );

        final modelFile = File('lib/features/match/domain/match_model.dart');
        expect(modelFile.existsSync(), isTrue);
        final modelContent = modelFile.readAsStringSync();
        expect(
          modelContent.contains('MatchLifecycleState get lifecycleState'),
          isTrue,
        );
        expect(
          modelContent.contains(
            'MatchModel transitionEvent(StateTransitionEvent event)',
          ),
          isTrue,
        );

        final helperFile = File(
          'lib/shared/bootstrap/app_bootstrap_helper.dart',
        );
        expect(helperFile.existsSync(), isTrue);
        final helperContent = helperFile.readAsStringSync();
        expect(helperContent.contains('days: 999'), isFalse);
        expect(
          helperContent.contains('Connectivity().onConnectivityChanged'),
          isTrue,
        );
        expect(helperContent.contains('isOnlineStreamProvider'), isTrue);
        expect(helperContent.contains('isOfflineStreamProvider'), isTrue);
        expect(helperContent.contains('globalConnectivityProvider'), isTrue);
      },
    );

    test(
      'Rule 8: [差分デルタ伝送] local_p2p_broadcaster.dart の broadcastMatchDelta 規約',
      () {
        final file = File(
          'lib/features/p2p/infrastructure/local_p2p_broadcaster.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content.contains('broadcastMatchDelta'), isTrue);
        expect(content.contains('MATCH_DELTA'), isTrue);
      },
    );

    test(
      'Rule 9: [CQRS DI一貫性規約] ProjectionStore で FirebaseFirestore.instance 直接参照が存在せず、firestoreProvider 経由であること',
      () {
        final storeFile = File(
          'lib/shared/application/projections/projection_store.dart',
        );
        expect(storeFile.existsSync(), isTrue);
        final content = storeFile.readAsStringSync();

        expect(
          content.contains('FirebaseFirestore.instance'),
          isFalse,
          reason:
              'ProjectionStore で FirebaseFirestore.instance を直接参照してはならない。ref.read(firestoreProvider) を使用すること。',
        );
        expect(
          content.contains('firestoreProvider'),
          isTrue,
          reason: 'ProjectionStore は firestoreProvider を使用していなければならない',
        );
      },
    );
  });
}
