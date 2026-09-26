import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/match_domain_service.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_share_data.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_text_parser_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_match_generator.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  group('🥋 勝ち抜き戦（3人制 / 5人制）包括的ドメイン・進行ユニットテスト', () {
    final roster = [
      PlayerModel(
        id: 'p1',
        lastName: '佐藤',
        firstName: '太郎',
        lastNameKana: 'さとう',
        firstNameKana: 'たろう',
        grade: 4,
      ),
      PlayerModel(
        id: 'p2',
        lastName: '鈴木',
        firstName: '次郎',
        lastNameKana: 'すずき',
        firstNameKana: 'じろう',
        grade: 5,
      ),
      PlayerModel(
        id: 'p3',
        lastName: '高橋',
        firstName: '三郎',
        lastNameKana: 'たかはし',
        firstNameKana: 'さぶろう',
        grade: 6,
      ),
    ];

    test('1. 3人制勝ち抜き戦の自動判定およびスロット（先鋒・中堅・大将）割り当て検証', () {
      final team3 = const ParsedTeamOrder(
        teamName: '道上剣友会（勝ち抜き）',
        category: '小学生高学年の部',
        members: [
          ParsedTeamMember(position: '先鋒', name: '佐藤太郎'),
          ParsedTeamMember(position: '中堅', name: '鈴木'),
          ParsedTeamMember(position: '大将', name: '高橋三郎'),
        ],
      );

      // 3名構成の勝ち抜き戦チームは「勝ち抜き戦（3人制）」と自動判定される
      final matchType = TournamentTeamAutoRegisterService.determineMatchType(
        team3,
      );
      expect(matchType, equals('勝ち抜き戦（3人制）'));

      // 基準スロット定義の検証
      final slots = TournamentTeamAutoRegisterService.getBaseSlots(matchType);
      expect(slots, equals(['先鋒', '中堅', '大将']));

      // 選手名の名簿照合とスロット配置検証
      final names = TournamentTeamAutoRegisterService.buildPlayerNames(
        team: team3,
        matchType: matchType,
        roster: roster,
      );
      expect(names, equals(['佐藤 太郎', '鈴木 次郎', '高橋 三郎']));
    });

    test('2. 5人制勝ち抜き戦の自動判定およびスロット割り当て検証', () {
      final team5 = const ParsedTeamOrder(
        teamName: '道上剣友会（勝ち抜き）',
        category: '小学生高学年の部',
        members: [
          ParsedTeamMember(position: '先鋒', name: '選手1'),
          ParsedTeamMember(position: '次鋒', name: '選手2'),
          ParsedTeamMember(position: '中堅', name: '選手3'),
          ParsedTeamMember(position: '副将', name: '選手4'),
          ParsedTeamMember(position: '大将', name: '選手5'),
        ],
      );

      // 5名構成の勝ち抜き戦チームは「勝ち抜き戦（5人制）」と判定される
      final matchType = TournamentTeamAutoRegisterService.determineMatchType(
        team5,
      );
      expect(matchType, equals('勝ち抜き戦（5人制）'));

      // 基準スロット定義の検証
      final slots = TournamentTeamAutoRegisterService.getBaseSlots(matchType);
      expect(slots, equals(['先鋒', '次鋒', '中堅', '副将', '大将']));
    });

    test('3. テキストパーサーによるセクションおよびチーム形式検出（3人制・5人制）', () {
      // セクション見出しの検出
      expect(
        TournamentTextParserHelper.detectSectionMatchType('【3人制勝ち抜き戦の部】'),
        equals('勝ち抜き戦（3人制）'),
      );
      expect(
        TournamentTextParserHelper.detectSectionMatchType('【5人制勝ち抜き戦】'),
        equals('勝ち抜き戦（5人制）'),
      );
      expect(
        TournamentTextParserHelper.detectSectionMatchType('【勝ち抜き戦】'),
        equals('勝ち抜き戦'),
      );

      // 初期形式検出
      expect(
        TournamentTextParserHelper.detectInitialMatchType(
          teamName: '3人制勝ち抜きチーム',
          rawText: '',
          memberCount: 3,
        ),
        equals('勝ち抜き戦（3人制）'),
      );
      expect(
        TournamentTextParserHelper.detectInitialMatchType(
          teamName: '勝ち抜きAチーム',
          rawText: '',
          memberCount: 5,
        ),
        equals('勝ち抜き戦（5人制）'),
      );
    });

    test('4. OrderSetupMatchGeneratorによる3人制勝ち抜き戦の初期試合生成と待機選手検証', () {
      const rule = MatchRule(
        isKachinuki: true,
        matchTimeMinutes: 3.0,
        positions: ['先鋒', '中堅', '大将'],
        category: '小学生高学年の部',
        teamName: '赤隊',
      );

      final matches = OrderSetupMatchGenerator.generateMatches(
        rule: rule,
        opponentTeamInput: '白隊',
        selectedPlayers: {0: '赤先鋒', 1: '赤中堅', 2: '赤大将'},
        opponentPlayers: {0: '白先鋒', 1: '白中堅', 2: '白大将'},
        leagueTeamOrders: {},
        leagueParticipants: [],
        tournamentId: 'tour_1',
        isOwnTeamRed: true,
        isStartNow: true,
        positions: ['先鋒', '中堅', '大将'],
        matchType: '勝ち抜き戦（3人制）',
        baseOrder: 1.0,
      );

      // 勝ち抜き戦では初期に1試合のみ生成される
      expect(matches.length, equals(1));
      final bout1 = matches.first;

      expect(bout1.isKachinuki, isTrue);
      expect(bout1.redName, equals('赤隊 : 赤先鋒'));
      expect(bout1.whiteName, equals('白隊 : 白先鋒'));
      // 待機選手リスト（中堅・大将の2名）
      expect(bout1.redRemaining, equals(['赤隊 : 赤中堅', '赤隊 : 赤大将']));
      expect(bout1.whiteRemaining, equals(['白隊 : 白中堅', '白隊 : 白大将']));
    });

    test('5. 3人制勝ち抜き戦の試合進行・勝者残留・敗者交代・大将戦決着の繰り上げ処理検証', () {
      final domainService = MatchDomainService();
      const rule = MatchRule(
        isKachinuki: true,
        matchTimeMinutes: 3.0,
        kachinukiUnlimitedType: '大将対大将',
      );

      // ── 第1戦: 先鋒同士（赤先鋒 2 - 0 白先鋒 で赤勝利） ──
      final bout1 = MatchModel(
        id: 'bout_1',
        tournamentId: 'tour_1',
        matchType: '勝ち抜き戦',
        isKachinuki: true,
        redName: '赤先鋒',
        whiteName: '白先鋒',
        redScore: 2,
        whiteScore: 0,
        redRemaining: ['赤中堅', '赤大将'],
        whiteRemaining: ['白中堅', '白大将'],
        order: 1.0,
      );

      final bout2 = domainService.generateNextKachinukiMatch(bout1, rule);
      expect(bout2, isNotNull);
      // 赤先鋒が残留
      expect(bout2!.redName, equals('赤先鋒'));
      // 白先鋒が敗退し、白中堅が繰り上げ
      expect(bout2.whiteName, equals('白中堅'));
      // 残り待機選手
      expect(bout2.redRemaining, equals(['赤中堅', '赤大将']));
      expect(bout2.whiteRemaining, equals(['白大将']));
      expect(bout2.order, closeTo(1.1, 0.001));

      // ── 第2戦: 赤先鋒 vs 白中堅（0 - 0 引き分け、両者退場） ──
      final bout2Finished = bout2.copyWith(redScore: 0, whiteScore: 0);
      final bout3 = domainService.generateNextKachinukiMatch(
        bout2Finished,
        rule,
      );
      expect(bout3, isNotNull);
      // 両者退場のため、赤中堅 vs 白大将
      expect(bout3!.redName, equals('赤中堅'));
      expect(bout3.whiteName, equals('白大将'));
      expect(bout3.redRemaining, equals(['赤大将']));
      expect(bout3.whiteRemaining, isEmpty); // 白はもう控えなし（大将が出場）

      // ── 第3戦: 赤中堅 vs 白大将（白大将 1 - 0 赤中堅 で白勝利） ──
      final bout3Finished = bout3.copyWith(redScore: 0, whiteScore: 1);
      final bout4 = domainService.generateNextKachinukiMatch(
        bout3Finished,
        rule,
      );
      expect(bout4, isNotNull);
      // 白大将残留 vs 赤最後の砦（赤大将）
      expect(bout4!.redName, equals('赤大将'));
      expect(bout4.whiteName, equals('白大将'));
      expect(bout4.redRemaining, isEmpty);
      expect(bout4.whiteRemaining, isEmpty);

      // ── 第4戦（大将同士）: 赤大将 vs 白大将（赤大将 1 - 0 白大将 で赤完全勝利） ──
      final bout4Finished = bout4.copyWith(redScore: 1, whiteScore: 0);
      final bout5 = domainService.generateNextKachinukiMatch(
        bout4Finished,
        rule,
      );
      // 白大将敗退かつ白の控えも0名のため試合終了（null）
      expect(bout5, isNull);
    });
  });
}
