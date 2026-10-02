import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

void main() {
  group('[E2E] 急遽コート振替（A→Bコート）観客Viewer呼出バナー・試合一覧即時追従E2Eテスト', () {
    test(
      '第1試合場から第2試合場への急遽振替時に、観客側Viewerのプロジェクションとコート情報がリロードなしで即時追従すること',
      () async {
        final now = DateTime(2026, 10, 2, 11, 0);
        final ruleEngine = KendoRuleEngine();

        // 1. 第1コート（Aコート）で予定されていた試合
        final court1Match = MatchModel(
          id: 'migration_match_01',
          tournamentId: 't_migration',
          matchType: '個人戦',
          status: 'waiting',
          groupName: '第1試合場',
          redName: '選手A',
          whiteName: '選手B',
          order: 1.0,
          rule: const MatchRule(),
        );

        final viewerStreamController =
            StreamController<MatchProjection>.broadcast();
        addTearDown(viewerStreamController.close);

        MatchProjection? latestViewerState;
        final subscription = viewerStreamController.stream.listen((proj) {
          latestViewerState = proj;
        });
        addTearDown(subscription.cancel);

        // 初期状態配信
        final analysis1 = ruleEngine.analyzeHistory(
          court1Match.events,
          court1Match,
          const MatchRule(),
        );
        viewerStreamController.add(
          MatchProjectionMapper.toMatchProjection(court1Match, analysis1),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(latestViewerState, isNotNull);
        expect(latestViewerState!.groupName, '第1試合場');

        // 2. 進行遅延により急遽第2コート（Bコート）へ振替
        final migratedMatch = court1Match.copyWith(
          groupName: '第2試合場',
          note: '第1試合場遅延に伴う緊急振替',
          status: 'in_progress',
          events: [ScoreEvent(id: 'ev_start', side: Side.none, timestamp: now)],
        );

        // 振替後ストリーム配信
        final analysis2 = ruleEngine.analyzeHistory(
          migratedMatch.events,
          migratedMatch,
          const MatchRule(),
        );
        viewerStreamController.add(
          MatchProjectionMapper.toMatchProjection(migratedMatch, analysis2),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // 3. 観客側Viewerがリロードなしで第2試合場・進行中・緊急振替備考を即座に追従していることの検証
        expect(latestViewerState!.groupName, '第2試合場');
        expect(latestViewerState!.status, 'in_progress');
        expect(latestViewerState!.note, contains('緊急振替'));
      },
    );
  });
}
