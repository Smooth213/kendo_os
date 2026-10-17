import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  group('[Unit] 操作席形旗判定入力から観客席Webビューアへのリアルタイム同期検証テスト', () {
    test('操作席での形判定およびペア情報がCRDTマージを通じて観客ブラウザへ即時正確に投影されること', () async {
      final engine = KendoRuleEngine();
      final timeSource = SystemTimeSource();
      final now = DateTime(2026, 10, 15, 15, 0, 0);

      const kataRule = MatchRule(
        hasHantei: true,
        matchTimeMinutes: 5,
        ipponLimit: 0,
      );

      // 初期状態の剣道形試合モデル
      final initialMatch = MatchModel(
        id: 'kata_sync_e2e_01',
        tournamentId: 't_kata_sync',
        groupName: '第2コート',
        matchType: '個人戦',
        category: '日本剣道形 中学生の部',
        redName: '打太刀: 皿田 脩人・仕太刀: 塚本 大道',
        whiteName: '打太刀: 佐藤 健・仕太刀: 高橋 武',
        redScore: 0,
        whiteScore: 0,
        status: 'in_progress',
        rule: kataRule,
      );

      // 観客席Webビューアが購読するブロードキャストStream
      final viewerStreamController =
          StreamController<MatchProjection>.broadcast();
      addTearDown(viewerStreamController.close);

      final receivedProjections = <MatchProjection>[];
      final subscription = viewerStreamController.stream.listen((projection) {
        receivedProjections.add(projection);
      });
      addTearDown(subscription.cancel);

      // ─────────────────────────────────────────────
      // 1. 初期状態の配信
      // ─────────────────────────────────────────────
      final initialAnalysis = engine.analyzeHistory(
        initialMatch.events,
        initialMatch,
        kataRule,
      );
      viewerStreamController.add(
        MatchProjectionMapper.toMatchProjection(initialMatch, initialAnalysis),
      );
      await pumpEventQueue();

      expect(receivedProjections.length, equals(1));
      expect(receivedProjections.first.redName, contains('皿田 脩人'));
      expect(receivedProjections.first.whiteName, contains('佐藤 健'));
      expect(receivedProjections.first.status, equals('in_progress'));

      // ─────────────────────────────────────────────
      // 2. 主審・副審による旗判定入力（赤・赤・白 ➔ 赤2-1判定）
      // ─────────────────────────────────────────────
      // 審判1: 赤旗
      final hanteiRed1 = ScoreEvent(
        id: 'ev_kata_sync_1',
        side: Side.red,
        isHantei: true,
        timestamp: now.add(const Duration(seconds: 1)),
        sequence: 1,
        logicalClock: 1,
      );

      // 審判2: 赤旗
      final hanteiRed2 = ScoreEvent(
        id: 'ev_kata_sync_2',
        side: Side.red,
        isHantei: true,
        timestamp: now.add(const Duration(seconds: 2)),
        sequence: 2,
        logicalClock: 2,
      );

      // 審判3: 白旗
      final hanteiWhite = ScoreEvent(
        id: 'ev_kata_sync_3',
        side: Side.white,
        isHantei: true,
        timestamp: now.add(const Duration(seconds: 3)),
        sequence: 3,
        logicalClock: 3,
      );

      // CRDTマージと再構築を実行
      final rebuilder = RebuildMatchFromEventsUseCase(engine, timeSource);
      final updatedLocalMatch = initialMatch.copyWith(
        events: [hanteiRed1, hanteiRed2, hanteiWhite],
        status: 'finished',
        note: '判定勝負 赤2-1',
      );

      final mergedMatch = SyncCrdtMerger.mergeAndRebuild(
        remoteMatch: initialMatch,
        localMatch: updatedLocalMatch,
        rule: kataRule,
        rebuilder: rebuilder,
      );

      expect(mergedMatch.events.length, equals(3));

      // エンジンによる形判定の解析
      final finalAnalysis = engine.analyzeHistory(
        mergedMatch.events,
        mergedMatch,
        kataRule,
      );

      expect(finalAnalysis.context.hasHantei, isTrue);

      // ─────────────────────────────────────────────
      // 3. 観客席Webビューアへのリアルタイム更新プッシュ
      // ─────────────────────────────────────────────
      viewerStreamController.add(
        MatchProjectionMapper.toMatchProjection(mergedMatch, finalAnalysis),
      );
      await pumpEventQueue();

      // 観客席で2件目のプロジェクション（完了・反映）が受信されたこと
      expect(receivedProjections.length, equals(2));
      final latestProjection = receivedProjections.last;

      expect(latestProjection.status, equals('finished'));
      expect(latestProjection.note, contains('判定勝負 赤2-1'));
      expect(latestProjection.redName, contains('皿田 脩人・仕太刀: 塚本 大道'));
      expect(latestProjection.whiteName, contains('佐藤 健・仕太刀: 高橋 武'));
    });
  });
}
