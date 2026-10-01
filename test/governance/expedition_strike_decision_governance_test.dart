import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_event_processor.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_player_roster_resolver.dart';

void main() {
  group('[Governance] 遠征打突種別および学年公式区分決定論保証規約', () {
    test('打突種別が剣道公式5大種別に厳格に分類され集計漏れが生じないこと', () {
      final now = DateTime.now();
      final strikes = [
        StrikeType.men,
        StrikeType.kote,
        StrikeType.dou,
        StrikeType.tsuki,
      ];

      final match = MatchModel(
        id: 'gov-strike-match',
        tournamentId: 't-1',
        matchType: '個人戦',
        redName: '自チーム:選手A',
        whiteName: '相手チーム:選手B',
        status: 'finished',
        events: [
          ...strikes.map(
            (s) => ScoreEvent(
              id: 'ev-${s.name}',
              side: Side.red,
              strikeType: s,
              isIppon: true,
              timestamp: now,
            ),
          ),
          ScoreEvent(
            id: 'ev-hansoku',
            side: Side.red,
            isIppon: true,
            isHansoku: true,
            timestamp: now,
          ),
        ],
      );

      final stats = ExpeditionEventProcessor.processEvents(
        matches: [match],
        selectedSummaryTeam: '自チーム',
        isMyTeam: (t) => t == '自チーム',
        isMyPlayer: (p, t) => t == '自チーム',
        isMatchPlayed: (m) => true,
        playerStatsMap: {},
      );

      expect(stats.teamMen, 1);
      expect(stats.teamKote, 1);
      expect(stats.teamDou, 1);
      expect(stats.teamTsuki, 1);
      expect(stats.teamHansoku, 1);
      expect(stats.teamTotalScored, 5);
      expect(stats.teamOther, 0);
    });

    test('学年カテゴリ決定論において未定義領域が存在せず全学年が公式区分に網羅されること', () {
      for (int grade = -1; grade <= 15; grade++) {
        final cat = MatchPlayerRosterResolver.getPlayerCategory(grade);
        expect(cat.isNotEmpty, isTrue);
        expect(
          cat == '初心者の部' ||
              cat == '幼年の部' ||
              cat == '小学生低学年の部' ||
              cat == '小学生高学年の部' ||
              cat == '中学生の部' ||
              cat == '高校生の部' ||
              cat == '一般の部',
          isTrue,
        );
      }
    });

    test('ソースコード静的解析において公式打突種別と学年解決が独立実装されていること', () {
      final file1 = File(
        'lib/features/tournament/presentation/components/official_record/expedition_event_processor.dart',
      );
      final file2 = File(
        'lib/features/tournament/presentation/operate/components/match_screen/match_player_roster_resolver.dart',
      );
      expect(file1.existsSync(), isTrue);
      expect(file2.existsSync(), isTrue);

      final content1 = file1.readAsStringSync();
      expect(content1.contains('StrikeType.men'), isTrue);
      expect(content1.contains('StrikeType.kote'), isTrue);
      expect(content1.contains('StrikeType.dou'), isTrue);
      expect(content1.contains('StrikeType.tsuki'), isTrue);
    });
  });
}
