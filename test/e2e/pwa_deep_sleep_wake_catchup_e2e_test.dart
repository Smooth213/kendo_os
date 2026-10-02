import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/projections/tournament_projection_mapper.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/time/server_clock_offset_service.dart';

void main() {
  group('[E2E] 観客PWA ディープスリープ復帰・30試合一括差分キャッチアップE2Eテスト', () {
    test('画面ロックで長時間放置後に30試合分の差分イベントを一括受信してもプロジェクションが破綻せず最新状態に同期すること', () async {
      final clockService = ServerClockOffsetService.instance;
      clockService.resetOffset();

      // 1. スリープ前の初期状態（1試合のみ）
      final initialMatches = [
        const MatchModel(
          id: 'sleep_m_0',
          tournamentId: 't_deep_sleep',
          matchType: '個人戦',
          status: 'in_progress',
          redName: '選手0_赤',
          whiteName: '選手0_白',
          redScore: 0,
          whiteScore: 0,
        ),
      ];

      final streamController = StreamController<List<MatchModel>>.broadcast();
      List<MatchModel> pwaState = [...initialMatches];

      final subscription = streamController.stream.listen((updatedList) {
        pwaState = List<MatchModel>.from(updatedList);
      });

      // 2. ディープスリープシミュレーション（時計が2時間進む）
      clockService.setOffset(const Duration(hours: 2));

      // 3. バックグラウンドで30試合が進行完了
      final caughtUpMatches = List.generate(30, (i) {
        return MatchModel(
          id: 'sleep_m_$i',
          tournamentId: 't_deep_sleep',
          matchType: '個人戦',
          status: 'finished',
          redName: '選手${i}_赤',
          whiteName: '選手${i}_白',
          redScore: (i % 2 == 0) ? 2 : 1,
          whiteScore: (i % 2 == 0) ? 0 : 2,
          order: i.toDouble(),
        );
      });

      // 4. 端末ウェイクアップ（一括受信）
      streamController.add(caughtUpMatches);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(pwaState.length, 30);
      expect(pwaState.every((m) => m.status == 'finished'), isTrue);

      // プロジェクションマッピング検証
      final tournament = TournamentModel(
        id: 't_deep_sleep',
        organizationId: 'org_1',
        name: 'ディープスリープ検証大会',
        venue: '日本武道館',
        date: DateTime(2026, 10, 2),
      );
      final projections = TournamentProjectionMapper.fromModels(
        tournament,
        pwaState,
      );

      expect(projections.allMatches.length, 30);
      expect(
        projections.allMatches.where((m) => m.status == 'finished').length,
        30,
      );

      await subscription.cancel();
      await streamController.close();
      clockService.resetOffset();
    });
  });
}
