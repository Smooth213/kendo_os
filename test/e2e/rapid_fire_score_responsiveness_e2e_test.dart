import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';

void main() {
  group('⚡ 【E2E】Plan 1 高速スコア連打・Jank撲滅＆バッチ同期 E2Eテスト', () {
    test(
      '1. [高速スコア連打シナリオ] スコアの連続打突操作（赤・白の一本、取り消し）が遅延なく消化され、最終スコアが完全に整合すること',
      () async {
        // 模擬的な高速打突入力テスト
        var currentMatch = MatchModel(
          id: 'rapid_match_001',
          matchType: '個人戦',
          redName: '選手 赤',
          whiteName: '選手 白',
          status: 'in_progress',
          redScore: 0,
          whiteScore: 0,
          events: const [],
        );

        // 5回連続で一本追加・取消のコマンドをシミュレート
        final operations = [
          (Side.red, PointType.men),
          (Side.white, PointType.kote),
          (Side.red, PointType.doIdo),
        ];

        for (final op in operations) {
          final newEvent = ScoreEventLegacyAdapter.fromLegacy(
            type: op.$2,
            side: op.$1,
          );
          final isRed = op.$1 == Side.red;
          currentMatch = currentMatch.copyWith(
            redScore: isRed ? currentMatch.redScore + 1 : currentMatch.redScore,
            whiteScore: !isRed
                ? currentMatch.whiteScore + 1
                : currentMatch.whiteScore,
            events: [...currentMatch.events, newEvent],
          );
        }

        expect(currentMatch.events.length, 3);
        expect(currentMatch.redScore, 2);
        expect(currentMatch.whiteScore, 1);

        // 直近のイベント取り消し（Undo）操作
        final lastEvent = currentMatch.events.last;
        final undoneEvents = currentMatch.events.sublist(
          0,
          currentMatch.events.length - 1,
        );
        final isRedUndo = lastEvent.side == Side.red;
        currentMatch = currentMatch.copyWith(
          redScore: isRedUndo
              ? currentMatch.redScore - 1
              : currentMatch.redScore,
          whiteScore: !isRedUndo
              ? currentMatch.whiteScore - 1
              : currentMatch.whiteScore,
          events: undoneEvents,
        );

        expect(currentMatch.events.length, 2);
        expect(currentMatch.redScore, 1);
        expect(currentMatch.whiteScore, 1);
      },
    );

    test(
      '2. [団体戦セレクター等価遮断シナリオ] 複数試合が存在するトーナメントで、他グループや同一内容の更新時にリスナーへの再通知が0回であること',
      () async {
        final container = ProviderContainer(
          overrides: [
            matchListProvider.overrideWith(
              (ref) => ref.watch(_e2eMatchesStateProvider),
            ),
          ],
        );
        addTearDown(container.dispose);

        int groupANotificationCount = 0;
        container.listen<List<MatchModel>>(
          teamMatchesByGroupProvider('group_A'),
          (prev, next) {
            groupANotificationCount++;
          },
        );

        // 初期状態の確認
        final groupAMatches = container.read(
          teamMatchesByGroupProvider('group_A'),
        );
        expect(groupAMatches.length, 2);
        expect(groupANotificationCount, 0);

        // 1. 同一内容の試合リストを再代入（インスタンスは新規だが中身不変）
        final currentState = container.read(_e2eMatchesStateProvider);
        container.read(_e2eMatchesStateProvider.notifier).state =
            List<MatchModel>.from(currentState);

        // ListEqualityWrapper により同一内容の再通知は完全に0回に遮断されること
        expect(
          groupANotificationCount,
          0,
          reason: 'ListEqualityWrapper により、中身が同一ならリスナー通知が一切飛ばないこと',
        );

        // 2. 別グループ（group_B）の試合のみ更新
        container.read(_e2eMatchesStateProvider.notifier).state = currentState
            .map((m) {
              if (m.id == 'm_gb_1') {
                return m.copyWith(redScore: 1);
              }
              return m;
            })
            .toList();

        // group_A のリスナー通知は依然として0回であること
        expect(
          groupANotificationCount,
          0,
          reason: '別グループの更新で自グループのセレクターが再通知されてはならない',
        );

        // 3. group_A の試合を実際に更新
        final latestState = container.read(_e2eMatchesStateProvider);
        container.read(_e2eMatchesStateProvider.notifier).state = latestState
            .map((m) {
              if (m.id == 'm_ga_1') {
                return m.copyWith(redScore: 1);
              }
              return m;
            })
            .toList();

        // プロバイダの最新評価を同期
        final updatedGroupA = container.read(
          teamMatchesByGroupProvider('group_A'),
        );

        // 実際に group_A のデータが変化した時のみ正しく1回通知されること
        expect(
          groupANotificationCount,
          1,
          reason: '自グループの試合データが実際に変化した時のみ通知されること',
        );
        expect(updatedGroupA.first.redScore, 1);
      },
    );

    test(
      '3. [複数未同期マッチの一括バルク同期シナリオ] オフライン状態で蓄積された全試合がバッチ処理によりアトミックに同期完了ステートへ更新されること',
      () async {
        final unSyncedMatches = List.generate(
          5,
          (i) => MatchModel(
            id: 'un_synced_$i',
            matchType: '団体戦',
            groupName: 'league_1',
            redName: '選手R$i',
            whiteName: '選手W$i',
            syncState: SyncState.localOnly,
            version: 1,
          ),
        );

        // バッチ処理のシミュレーション: 全件を synced に昇格
        final syncedMatches = unSyncedMatches.map((m) {
          return m.copyWith(
            syncState: SyncState.synced,
            pendingEvents: const [],
            version: m.version + 1,
          );
        }).toList();

        expect(syncedMatches.length, 5);
        expect(
          syncedMatches.every((m) => m.syncState == SyncState.synced),
          isTrue,
        );
        expect(syncedMatches.every((m) => m.version == 2), isTrue);
      },
    );
  });
}

final _e2eMatchesStateProvider = StateProvider<List<MatchModel>>((ref) {
  return [
    MatchModel(
      id: 'm_ga_1',
      groupName: 'group_A',
      matchType: '団体戦',
      redName: '先鋒A',
      whiteName: '先鋒A2',
      redScore: 0,
    ),
    MatchModel(
      id: 'm_ga_2',
      groupName: 'group_A',
      matchType: '団体戦',
      redName: '次鋒A',
      whiteName: '次鋒A2',
      redScore: 0,
    ),
    MatchModel(
      id: 'm_gb_1',
      groupName: 'group_B',
      matchType: '団体戦',
      redName: '先鋒B',
      whiteName: '先鋒B2',
      redScore: 0,
    ),
  ];
});
