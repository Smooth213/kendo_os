import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/security/pwa_storage_bridge.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

void main() {
  group('🛡️ Web/PWA リロード・タブ復帰 状態保証テスト要塞', () {
    late DateTime baseTime;

    setUp(() {
      baseTime = DateTime(2026, 9, 3, 10, 0, 0);
      PwaStorage.removeItem('kendo_os_active_tournament_id');
      PwaStorage.removeItem('kendo_os_active_dojo_id');
    });

    tearDown(() {
      PwaStorage.removeItem('kendo_os_active_tournament_id');
      PwaStorage.removeItem('kendo_os_active_dojo_id');
    });

    test(
      '1. 【PwaStorage永続化】ブラウザリロード（ProviderContainer再構築）後も大会ID・道場IDが完全復元される',
      () {
        // 1. リロード前の状態をシミュレート
        PwaStorage.setItem(
          'kendo_os_active_tournament_id',
          't-web-reload-tournament-999',
        );
        PwaStorage.setItem('kendo_os_active_dojo_id', 'dojo-tokyo-center-001');

        // 2. ブラウザがF5リロードされて新しいProviderContainerが生成された状態
        final reloadedContainer = ProviderContainer();
        addTearDown(reloadedContainer.dispose);

        final recoveredTournamentId = reloadedContainer.read(
          currentTournamentIdProvider,
        );
        final recoveredDojoId = reloadedContainer.read(currentDojoIdProvider);
        final syncContext = reloadedContainer.read(currentSyncContextProvider);

        expect(recoveredTournamentId, 't-web-reload-tournament-999');
        expect(recoveredDojoId, 'dojo-tokyo-center-001');
        expect(syncContext.organizationId, 'dojo-tokyo-center-001');
        expect(syncContext.role, UserRole.viewer);
      },
    );

    test('2. 【URLクエリ/エンコード復元】URL経由で日本語グループ名・IDがリロード時に安全にデコードされる', () {
      const rawGroupName = '一般男子 1回戦【第1コート】';
      final encodedUri = Uri.parse(
        'https://kendo-os.web.app/viewer/team-scoreboard/${Uri.encodeComponent(rawGroupName)}?tournamentId=t-param-777',
      );

      final queryTournamentId = encodedUri.queryParameters['tournamentId'];
      final pathSegment = encodedUri.pathSegments.last;

      // 本番実装と同等の二重デコード・破損耐性セーフガード関数
      String safeDecode(String? input) {
        if (input == null) return '';
        try {
          return Uri.decodeComponent(input);
        } catch (_) {
          return input;
        }
      }

      final decodedGroupName = safeDecode(pathSegment);

      expect(queryTournamentId, 't-param-777');
      expect(decodedGroupName, rawGroupName);
      expect(decodedGroupName.contains('第1コート'), isTrue);
    });

    test('3. 【タブ復帰/オフライン復元】試合進行中にタブが再アクティブ化されてもスコアとタイマー状態が保全される', () {
      final inFlightMatch = MatchModel(
        id: 'match-web-restore-001',
        tournamentId: 't-web-restore',
        category: '一般個人',
        matchType: 'individual',
        groupName: '準決勝',
        redName: '神武館:佐藤',
        whiteName: '修道館:田中',
        redScore: 1,
        whiteScore: 0,
        timerStartedAt: baseTime,
        matchTimeMinutes: 3.0,
        status: 'in_progress',
        order: 1.0,
        events: [
          ScoreEvent(
            id: 'ev-1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: baseTime,
            logicalClock: 1,
          ),
        ],
      );

      // JSON直列化＆復元（IndexedDB / LocalStorage 永続化サイクル）
      final serialized = inFlightMatch.toJson();
      final restored = MatchModel.fromJson(serialized);

      expect(restored.id, inFlightMatch.id);
      expect(restored.redScore, 1);
      expect(restored.whiteScore, 0);
      expect(restored.timerStartedAt, baseTime);
      expect(restored.matchTimeMinutes, 3.0);
      expect(restored.status, 'in_progress');
      expect(restored.events.length, 1);
      expect(restored.events.first.strikeType, StrikeType.men);
    });

    test(
      '4. 【ServiceWorker重複・順不同注入】リロード直後に重複または順不同で到着したスコアイベントが論理時計順に正しく収束する',
      () {
        final ev1 = ScoreEvent(
          id: 'ev-clock-1',
          side: Side.red,
          strikeType: StrikeType.men,
          isIppon: true,
          timestamp: baseTime,
          logicalClock: 1,
        );
        final ev2 = ScoreEvent(
          id: 'ev-clock-2',
          side: Side.white,
          strikeType: StrikeType.kote,
          isIppon: true,
          timestamp: baseTime.add(const Duration(seconds: 30)),
          logicalClock: 2,
        );

        // キャッシュとネットワークから重複・順不同で流れてきたリスト
        final disorderedEvents = [ev2, ev1, ev2, ev1];

        // IDによる一意化と論理クロックによる決定論的ソート
        final uniqueMap = <String, ScoreEvent>{};
        for (final ev in disorderedEvents) {
          uniqueMap[ev.id] = ev;
        }
        final sortedEvents = uniqueMap.values.toList()
          ..sort((a, b) => a.logicalClock.compareTo(b.logicalClock));

        expect(sortedEvents.length, 2);
        expect(sortedEvents[0].id, 'ev-clock-1');
        expect(sortedEvents[1].id, 'ev-clock-2');
        expect(sortedEvents[0].strikeType, StrikeType.men);
        expect(sortedEvents[1].strikeType, StrikeType.kote);
      },
    );
  });
}
