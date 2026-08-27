import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
// 🛡️ 補正：未使用の tournament_projection.dart インポートを完全物理排除し、警告を撲滅
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/application/projections/tournament_projection_mapper.dart';

void main() {
  group('🛡️ STEP 2-1: TournamentProjectionMapper 完全ユニットテスト要塞', () {
    late TournamentModel fakeTournament;

    setUp(() {
      fakeTournament = TournamentModel(
        id: 'tournament_test_001',
        organizationId: 'org_test_001',
        name: '〇〇剣道大会',
        date: DateTime(2026, 5, 29),
        venue: '△△体育館',
        categories: ['小学生の部'],
        status: 'active',
        notes: '開場8時30分',
        securityLevel: 2,
      );
    });

    test('1. 【団体戦】団体戦が正しく集計・構築されること', () {
      final matches = [
        MatchListProjection(
          id: 'match_001',
          tournamentId: 'tournament_test_001',
          matchOrder: 1,
          matchType: '先鋒',
          status: 'approved',
          redName: '××剣道教室 : 選手A',
          whiteName: '〇〇剣友会 : 選手B',
          redScore: 2,
          whiteScore: 0,
          groupName: '小学生の部',
          isKachinuki: false,
          note: '団体戦1回戦',
        ),
        MatchListProjection(
          id: 'match_002',
          tournamentId: 'tournament_test_001',
          matchOrder: 2,
          matchType: '次鋒',
          status: 'approved',
          redName: '××剣道教室 : 選手C',
          whiteName: '〇〇剣友会 : 選手D',
          redScore: 1,
          whiteScore: 1,
          groupName: '小学生の部',
          isKachinuki: false,
          note: '団体戦1回戦',
        ),
      ];

      final projection = TournamentProjectionMapper.fromProjections(
        fakeTournament,
        matches,
      );

      expect(projection.tournament.id, equals('tournament_test_001'));
      expect(projection.teamMatches.containsKey('小学生の部'), isTrue);

      final teamProj = projection.teamMatches['小学生の部']!;
      expect(teamProj.redTeamName, equals('××剣道教室'));
      expect(teamProj.whiteTeamName, equals('〇〇剣友会'));
      expect(teamProj.result.redWins, equals(1));
      expect(teamProj.result.whiteWins, equals(0));
      expect(teamProj.result.redPoints, equals(3));
      expect(teamProj.result.whitePoints, equals(1));
    });

    test('2. 【リーグ戦】リーグ戦タグが正しく判定・グルーピングされること', () {
      final matches = [
        MatchListProjection(
          id: 'match_league_001',
          tournamentId: 'tournament_test_001',
          matchOrder: 1,
          matchType: '個人戦',
          status: 'approved',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 1,
          whiteScore: 0,
          groupName: '3人リーグ戦の部',
          isKachinuki: false,
          note: '[リーグ戦]',
        ),
      ];

      final projection = TournamentProjectionMapper.fromProjections(
        fakeTournament,
        matches,
      );
      final teamProj = projection.teamMatches['3人リーグ戦の部']!;

      expect(teamProj.isLeague, isTrue);
      expect(teamProj.note, contains('[リーグ戦]'));
    });

    test('3. 【個人戦判定】個人戦の設定がマッパーを正常透過すること', () {
      final matches = [
        MatchListProjection(
          id: 'match_indiv_001',
          tournamentId: 'tournament_test_001',
          matchOrder: 1,
          matchType: 'individual',
          status: 'waiting',
          redName: '中村たけし',
          whiteName: '佐々木はな子',
          redScore: 0,
          whiteScore: 0,
          groupName: '個人戦トーナメント',
          isKachinuki: false,
          note: '1回戦',
        ),
      ];

      final projection = TournamentProjectionMapper.fromProjections(
        fakeTournament,
        matches,
      );
      final teamProj = projection.teamMatches['個人戦トーナメント']!;

      expect(teamProj.matchType, equals('individual'));
      expect(teamProj.isKachinuki, isFalse);
    });

    test('4. 【勝ち抜き】isKachinukiフラグが正しくプロジェクションへ連動すること', () {
      final matches = [
        MatchListProjection(
          id: 'match_kachi_001',
          tournamentId: 'tournament_test_001',
          matchOrder: 1,
          matchType: '団体戦',
          status: 'in_progress',
          redName: 'A道場',
          whiteName: 'B道場',
          redScore: 0,
          whiteScore: 0,
          groupName: '勝ち抜き戦の部',
          isKachinuki: true,
          note: '勝ち抜き規定適用',
        ),
      ];

      final projection = TournamentProjectionMapper.fromProjections(
        fakeTournament,
        matches,
      );
      final teamProj = projection.teamMatches['勝ち抜き戦の部']!;

      expect(teamProj.isKachinuki, isTrue);
    });

    test('5. 【SUMMARY】Noteおよびステータス状態が正常に集約されること', () {
      final matches = [
        MatchListProjection(
          id: 'match_sum_001',
          tournamentId: 'tournament_test_001',
          matchOrder: 1,
          matchType: '大将戦',
          status: 'finished',
          redName: '紅組',
          whiteName: '白組',
          redScore: 1,
          whiteScore: 2,
          groupName: '総合決戦',
          isKachinuki: false,
          note: '[SUMMARY] overlay判定対象',
        ),
      ];

      final projection = TournamentProjectionMapper.fromProjections(
        fakeTournament,
        matches,
      );
      final teamProj = projection.teamMatches['総合決戦']!;

      expect(teamProj.note, equals('[SUMMARY] overlay判定対象'));
      expect(teamProj.result.allFinished, isTrue);
    });

    test('6. 【UUID/文字列整合性】groupNameキーが崩れず正確にマッピング保持されること', () {
      const uuidGroupName = '小学生低学年の部_QA-776-XYZ';
      final matches = [
        MatchListProjection(
          id: 'match_uuid_001',
          tournamentId: 'tournament_test_001',
          matchOrder: 1,
          matchType: '先鋒',
          status: 'waiting',
          redName: 'Aチーム',
          whiteName: 'Bチーム',
          redScore: 0,
          whiteScore: 0,
          groupName: uuidGroupName,
          isKachinuki: false,
          note: '',
        ),
      ];

      final projection = TournamentProjectionMapper.fromProjections(
        fakeTournament,
        matches,
      );

      expect(projection.teamMatches.containsKey(uuidGroupName), isTrue);
      expect(projection.categoryToGroupKeys['小学生の部'], contains(uuidGroupName));
    });
  });
}
