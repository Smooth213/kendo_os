import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ※ プロジェクトの実際のパスに合わせてインポートを調整してください
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/features/tournament/domain/services/bunaiksen_helper.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_record_export_helper.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';

// ============================================================================
// 【単体テスト（Unit Test）実行部】
// 以前の仮設モック（BunaiksenLogicHelper）を削除し、
// 分離が完了した本番用の BunaiksenHelper を直接テストします！
// ============================================================================
void main() {
  group('[Unit] カテゴリ1: 部内戦ルールのテスト', () {
    test('3分・延長なしにおいて 部内戦の基本ルールが正しく定義されていること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final rule = container.read(bunaiksenRuleProvider);

      expect(rule.matchTimeMinutes, 3, reason: '試合時間は3分であるべき');
      expect(rule.enchoTimeMinutes, 0, reason: '基本ルールでは延長戦は無し(0分)であるべき');
      expect(rule.isEnchoUnlimited, false, reason: '無限延長は無効であるべき');
    });

    test('1本勝負の設定を適用した場合、1本で勝敗が決まるルールになること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(bunaiksenRuleProvider.notifier)
          .update((state) => state.copyWith(isIpponShobu: true, ipponLimit: 1));

      final rule = container.read(bunaiksenRuleProvider);

      expect(rule.isIpponShobu, true);
      expect(rule.ipponLimit, 1);

      final engine = KendoRuleEngine();
      final mockMatch = MatchModel(
        id: 'test',
        tournamentId: 't1',
        matchOrder: 1,
        order: 1,
        redName: 'Red',
        whiteName: 'White',
        status: 'in_progress',
        matchType: '個人戦',
      );
      final mockEvents = [
        ScoreEvent(
          id: 'e1',
          side: Side.red,
          strikeType: StrikeType.men,
          isIppon: true,
          timestamp: DateTime.now(),
        ),
      ];

      final analysis = engine.analyzeHistory(mockEvents, mockMatch, rule);
      final result = engine.decideResult(analysis.context, rule);

      expect(analysis.context.redIppon, 1);
      expect(
        result,
        MatchResultStatus.redWin,
        reason: '1本勝負なので、1本先取した時点で勝利となるべき',
      );
    });
  });

  group('カテゴリ2: 技（スコアマーク）変換ロジックのテスト', () {
    test('赤が先取（メン）、白が取り返し（コテ）、赤が勝負あり（ドウ）の場合の正確な変換こと', () {
      final mockEvents = [
        {'side': 'red', 'type': 'men'},
        {'side': 'white', 'type': 'kote'},
        {'side': 'red', 'type': 'do'},
      ];

      // ★ 本番の BunaiksenHelper を使用
      final redMarks = BunaiksenHelper.extractMarks(mockEvents, true);
      final whiteMarks = BunaiksenHelper.extractMarks(mockEvents, false);

      expect(redMarks.length, 2);
      expect(redMarks[0], '㋱', reason: '試合全体の先取技なので丸囲みの「㋱」になるべき');
      expect(redMarks[1], 'ド', reason: '3本目の技なので通常の「ド」になるべき');

      expect(whiteMarks.length, 1);
      expect(whiteMarks[0], 'コ', reason: '2本目の技なので通常の「コ」になるべき');
    });

    test('取り消し（Undo/isCanceled）された技が無視され、次の技が正しく先取（丸囲み）扱いになること', () {
      final mockEvents = [
        {'side': 'red', 'type': 'men', 'isCanceled': true},
        {'side': 'white', 'type': 'tsuki'},
      ];

      final redMarks = BunaiksenHelper.extractMarks(mockEvents, true);
      final whiteMarks = BunaiksenHelper.extractMarks(mockEvents, false);

      expect(redMarks.isEmpty, true, reason: '取り消された技はリストに入らないべき');
      expect(whiteMarks.length, 1);
      expect(whiteMarks[0], '㋡', reason: '取り消し後の有効な最初の技なので丸囲みになるべき');
    });
  });

  group('カテゴリ3: 表示チーム名・選手名抽出ロジックのテスト', () {
    test('個人戦の場合、フォーマットから選手名のみが抽出されること', () {
      // parseName を使用した検証
      final parsed = BunaiksenHelper.parseName('道場A: 剣道太郎');
      expect(parsed['last'], '剣道太郎');
    });

    test('欠員の場合、空文字が返されること', () {
      final parsed = BunaiksenHelper.parseName('欠員');
      expect(parsed['last'], '');
    });
  });

  group('カテゴリ4: リーグ戦勝点（ポイント）計算ロジックのテスト', () {
    test('勝利した場合は勝ち点「3」、引き分けは「1」、敗北は「0」が付与されること', () {
      final mockMatches = [
        MatchModel(
          id: '1',
          tournamentId: 'test',
          order: 1,
          matchType: 'リーグ',
          redName: 'Aチーム: 太郎',
          whiteName: 'Bチーム: 次郎',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          events: [],
        ),
        MatchModel(
          id: '2',
          tournamentId: 'test',
          order: 2,
          matchType: 'リーグ',
          redName: 'Aチーム: 太郎',
          whiteName: 'Cチーム: 三郎',
          redScore: 1,
          whiteScore: 1,
          status: 'finished',
          events: [],
        ),
        MatchModel(
          id: '3',
          tournamentId: 'test',
          order: 3,
          matchType: 'リーグ',
          redName: 'Aチーム: 太郎',
          whiteName: 'Dチーム: 四郎',
          redScore: 0,
          whiteScore: 1,
          status: 'finished',
          events: [],
        ),
      ];

      final teamList = ['Aチーム', 'Bチーム', 'Cチーム', 'Dチーム'];

      final pointsA = BunaiksenHelper.calculateCustomLeaguePoints(
        'Aチーム',
        teamList,
        mockMatches,
      );
      // 2-0 (勝=3) + 1-1 (分=1) + 0-1 (負=0) = 4ポイント
      expect(pointsA, 4);
    });

    test('リーグ戦判定において カテゴリやnoteやmatchTypeからリーグ戦を正しく識別できること', () {
      final calculatorLeagueMatch = MatchModel(
        id: 'calc_league_1',
        tournamentId: 't1',
        category: 'Aリーグ',
        matchType: 'リーグ戦',
        groupName: 'league_Aリーグ',
        note: '[Aリーグ] 第1試合 (第1コート 第1試合)',
        redName: '選手A',
        whiteName: '選手B',
      );
      final tournamentMatch = MatchModel(
        id: 'calc_tour_1',
        tournamentId: 't1',
        category: '決勝トーナメント',
        matchType: 'トーナメント',
        groupName: 'tournament',
        note: '[決勝トーナメント] 1回戦第1試合',
        redName: '選手A',
        whiteName: '選手B',
      );

      expect(BunaiksenHelper.isLeagueMatch(calculatorLeagueMatch), isTrue);
      expect(BunaiksenHelper.isLeagueMatch(tournamentMatch), isFalse);
      expect(BunaiksenHelper.isLeagueMatches([calculatorLeagueMatch]), isTrue);
      expect(BunaiksenHelper.isLeagueMatches([tournamentMatch]), isFalse);
    });
  });

  group('カテゴリ4: 部内戦公式記録の複数形式データ集約ロジックのテスト', () {
    test('複数形式の試合データにおいて 全カテゴリが欠落なく集約され個人戦グループが正しく統合されること', () {
      // 1. リーグ戦形式の試合データ
      final leagueMatches = [
        const MatchModel(
          id: 'm_league_2',
          tournamentId: 't1',
          category: 'Aリーグ',
          matchType: 'リーグ戦',
          order: 2.0,
          redName: '選手A',
          whiteName: '選手C',
          groupName: 'league_A',
          note: '[Aリーグ] 第2試合',
        ),
        const MatchModel(
          id: 'm_league_1',
          tournamentId: 't1',
          category: 'Aリーグ',
          matchType: 'リーグ戦',
          order: 1.0,
          redName: '選手A',
          whiteName: '選手B',
          groupName: 'league_A',
          note: '[Aリーグ] 第1試合',
        ),
      ];

      // 2. 個人戦形式の試合データ（UUIDグループ名で個別登録されたもの）
      final indivMatches1 = [
        const MatchModel(
          id: 'm_indiv_1',
          tournamentId: 't1',
          category: '個人戦トーナメント',
          matchType: '個人戦',
          order: 1.0,
          redName: '選手C',
          whiteName: '選手D',
          groupName: '12345678-1234-1234-1234-123456789abc',
        ),
      ];
      final indivMatches2 = [
        const MatchModel(
          id: 'm_indiv_2',
          tournamentId: 't1',
          category: '個人戦トーナメント',
          matchType: '個人戦',
          order: 2.0,
          redName: '選手E',
          whiteName: '選手F',
          groupName: '87654321-4321-4321-4321-cba987654321',
        ),
      ];

      final categoryGroups = <String, Map<String, List<MatchModel>>>{
        'Aリーグ': {'league_A': leagueMatches},
        '個人戦トーナメント': {
          '12345678-1234-1234-1234-123456789abc': indivMatches1,
          '87654321-4321-4321-4321-cba987654321': indivMatches2,
        },
      };

      // 実行
      final allData = BunaiksenRecordExportHelper.buildAllCategoryData(
        categoryGroups,
      );

      // 検証
      expect(allData.length, 2, reason: '全2カテゴリが欠落なく生成されること');

      // 1) Aリーグの検証（リーグ戦は統合されず元のグループ名でソートされる）
      final leagueCategory = allData.firstWhere(
        (c) => c.categoryName == 'Aリーグ',
      );
      expect(leagueCategory.groupDataList.length, 1);
      expect(leagueCategory.groupDataList[0]['groupName'], 'league_A');
      final sortedLeagueMatches =
          leagueCategory.groupDataList[0]['matches'] as List<MatchModel>;
      expect(sortedLeagueMatches.length, 2);
      expect(
        sortedLeagueMatches[0].id,
        'm_league_1',
        reason: 'order昇順でソートされること',
      );
      expect(sortedLeagueMatches[1].id, 'm_league_2');

      // 2) 個人戦トーナメントの検証（個別UUIDグループが __merged_individual__ に統合される）
      final indivCategory = allData.firstWhere(
        (c) => c.categoryName == '個人戦トーナメント',
      );
      expect(indivCategory.groupDataList.length, 1);
      expect(
        indivCategory.groupDataList[0]['groupName'],
        '__merged_individual__',
      );
      final mergedIndivMatches =
          indivCategory.groupDataList[0]['matches'] as List<MatchModel>;
      expect(mergedIndivMatches.length, 2);
      expect(mergedIndivMatches[0].id, 'm_indiv_1');
      expect(mergedIndivMatches[1].id, 'm_indiv_2');
    });
  });
}
