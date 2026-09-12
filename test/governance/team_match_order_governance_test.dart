import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/team_scoreboard_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_team_scoreboard_screen.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/application/projections/tournament_projection_mapper.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/utils/kendo_position_sorter.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

/// 🥋 【ガバナンス監査 22/22】団体戦試合順序（先鋒〜大将・代表戦）剣道標準配列 永続保証テスト
void main() {
  group('🥋 【ガバナンス監査 22/22】団体戦試合順序（先鋒〜大将・代表戦）剣道標準配列 永続保証テスト', () {
    late MockTournamentRepository mockTournamentRepo;
    late SharedPreferences prefs;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    setUp(() {
      mockTournamentRepo = MockTournamentRepository();
      when(() => mockTournamentRepo.getTournamentStream(any())).thenAnswer(
        (_) => Stream.value(
          TournamentModel(
            id: 'tour_gov_1',
            organizationId: 'org_gov',
            name: 'ガバナンス検証大会',
            date: DateTime.now(),
            venue: '武道場',
            categories: const ['一般の部'],
          ),
        ),
      );
    });

    // =========================================================================
    // 1. [静的スキャン規約] 団体戦スコア関連クラスの KendoPositionSorter 適用検証
    // =========================================================================
    test('1. 【静的コード規約】団体戦スコアボード・記録コンポーネントにおける KendoPositionSorter 適用規約', () {
      final targetFiles = [
        'lib/features/viewer/screens/viewer_team_scoreboard_screen.dart',
        'lib/features/tournament/presentation/operate/team_scoreboard_screen.dart',
        'lib/features/viewer/components/viewer_official_record_table_sections.dart',
        'lib/shared/application/projections/tournament_projection_mapper.dart',
      ];

      for (final path in targetFiles) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'ファイルが存在しません: $path');
        final content = file.readAsStringSync();
        expect(
          content.contains('KendoPositionSorter'),
          isTrue,
          reason: '$path で KendoPositionSorter による整列が適用されていません',
        );
      }
    });

    // =========================================================================
    // 2. [動的規約: 観戦用ビュアー] ViewerTeamScoreboardScreen の整列保証
    // =========================================================================
    testWidgets('2. 【動的規約: 観戦ビュアー】入力順序乱れ時の先鋒〜大将・代表戦 自動整列保証規約', (tester) async {
      // 意図的に「中堅 ➔ 大将 ➔ 代表戦 ➔ 先鋒」とシャッフル
      final mChuken = MatchModel(
        id: 'm_chuken',
        tournamentId: 'tour_gov_1',
        order: 2.0,
        matchType: '中堅',
        redName: '道上: 皿田',
        whiteName: '相手: 選手2',
        groupName: 'gov_group_1',
        status: 'finished',
        redScore: 1,
        whiteScore: 0,
      );
      final mTaisho = MatchModel(
        id: 'm_taisho',
        tournamentId: 'tour_gov_1',
        order: 3.0,
        matchType: '大将',
        redName: '道上: 久安',
        whiteName: '相手: 選手3',
        groupName: 'gov_group_1',
        status: 'finished',
        redScore: 0,
        whiteScore: 1,
      );
      final mDaihyo = MatchModel(
        id: 'm_daihyo',
        tournamentId: 'tour_gov_1',
        order: 4.0,
        matchType: '代表戦',
        redName: '道上: 塚本',
        whiteName: '相手: 選手1',
        groupName: 'gov_group_1',
        status: 'finished',
        redScore: 1,
        whiteScore: 0,
      );
      final mSempo = MatchModel(
        id: 'm_sempo',
        tournamentId: 'tour_gov_1',
        order: 1.0,
        matchType: '先鋒',
        redName: '道上: 塚本',
        whiteName: '相手: 選手1',
        groupName: 'gov_group_1',
        status: 'finished',
        redScore: 2,
        whiteScore: 0,
      );

      final scrambledMatches = [mChuken, mTaisho, mDaihyo, mSempo];

      final router = GoRouter(
        initialLocation: '/viewer-team/gov_group_1?tournamentId=tour_gov_1',
        routes: [
          GoRoute(
            path: '/viewer-team/:groupName',
            builder: (context, state) => ViewerTeamScoreboardScreen(
              groupName: state.pathParameters['groupName']!,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            matchListProvider.overrideWith((ref) => scrambledMatches),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // ポジションテキストの描画縦位置 (Y座標) を検証
      final sempoY = tester.getTopLeft(find.text('先鋒')).dy;
      final chukenY = tester.getTopLeft(find.text('中堅')).dy;
      final taishoY = tester.getTopLeft(find.text('大将')).dy;
      final daihyoY = tester.getTopLeft(find.text('代表戦')).dy;

      expect(sempoY < chukenY, isTrue, reason: '先鋒は中堅より上に表示されること');
      expect(chukenY < taishoY, isTrue, reason: '中堅は大将より上に表示されること');
      expect(taishoY < daihyoY, isTrue, reason: '大将は代表戦より上に表示されること');
    });

    // =========================================================================
    // 3. [動的規約: 通常ビュアー] TeamScoreboardScreen の整列保証
    // =========================================================================
    testWidgets('3. 【動的規約: 通常ビュアー】大会ホーム側スコアボードにおける剣道ポジション順序保証規約', (
      tester,
    ) async {
      // order が全て 0 の極端なデータでもポジション順に整列するか検証
      final mTaisho = MatchModel(
        id: 'm_taisho_zero',
        tournamentId: 'tour_gov_1',
        order: 0.0,
        matchType: '大将',
        redName: '道上: 久安',
        whiteName: '相手: 選手3',
        groupName: 'gov_group_2',
        status: 'finished',
      );
      final mSempo = MatchModel(
        id: 'm_sempo_zero',
        tournamentId: 'tour_gov_1',
        order: 0.0,
        matchType: '先鋒',
        redName: '道上: 塚本',
        whiteName: '相手: 選手1',
        groupName: 'gov_group_2',
        status: 'finished',
      );
      final mChuken = MatchModel(
        id: 'm_chuken_zero',
        tournamentId: 'tour_gov_1',
        order: 0.0,
        matchType: '中堅',
        redName: '道上: 皿田',
        whiteName: '相手: 選手2',
        groupName: 'gov_group_2',
        status: 'finished',
      );

      final matches = [mTaisho, mSempo, mChuken];

      final router = GoRouter(
        initialLocation: '/team-scoreboard/gov_group_2?tournamentId=tour_gov_1',
        routes: [
          GoRoute(
            path: '/team-scoreboard/:groupName',
            builder: (context, state) => TeamScoreboardScreen(
              groupName: state.pathParameters['groupName']!,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            matchListProvider.overrideWith((ref) => matches),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      final sempoY = tester.getTopLeft(find.text('先鋒')).dy;
      final chukenY = tester.getTopLeft(find.text('中堅')).dy;
      final taishoY = tester.getTopLeft(find.text('大将')).dy;

      expect(sempoY < chukenY, isTrue, reason: '通常ビュアーでも先鋒が中堅より上であること');
      expect(chukenY < taishoY, isTrue, reason: '通常ビュアーでも中堅が大将より上であること');
    });

    // =========================================================================
    // 4. [動的規約: プロジェクション層] TeamMatchProjection の永続ソート保証
    // =========================================================================
    test('4. 【動的規約: プロジェクション層】TeamMatchProjection.matches 剣道標準配列 永続保持規約', () {
      final fakeTournament = TournamentModel(
        id: 'tour_gov_1',
        organizationId: 'org_gov',
        name: '大会',
        date: DateTime.now(),
        venue: '道場',
        categories: ['一般'],
      );

      final scrambledListProjections = [
        MatchListProjection(
          id: 'p_daihyo',
          tournamentId: 'tour_gov_1',
          matchOrder: 0,
          matchType: '代表戦',
          status: 'finished',
          redName: 'A: 塚本',
          whiteName: 'B: 田中',
          redScore: 1,
          whiteScore: 0,
          groupName: 'grp_proj',
          isKachinuki: false,
          note: '',
        ),
        MatchListProjection(
          id: 'p_chuken',
          tournamentId: 'tour_gov_1',
          matchOrder: 0,
          matchType: '中堅',
          status: 'finished',
          redName: 'A: 皿田',
          whiteName: 'B: 佐藤',
          redScore: 1,
          whiteScore: 0,
          groupName: 'grp_proj',
          isKachinuki: false,
          note: '',
        ),
        MatchListProjection(
          id: 'p_sempo',
          tournamentId: 'tour_gov_1',
          matchOrder: 0,
          matchType: '先鋒',
          status: 'finished',
          redName: 'A: 塚本',
          whiteName: 'B: 鈴木',
          redScore: 2,
          whiteScore: 0,
          groupName: 'grp_proj',
          isKachinuki: false,
          note: '',
        ),
        MatchListProjection(
          id: 'p_taisho',
          tournamentId: 'tour_gov_1',
          matchOrder: 0,
          matchType: '大将',
          status: 'finished',
          redName: 'A: 久安',
          whiteName: 'B: 高橋',
          redScore: 0,
          whiteScore: 1,
          groupName: 'grp_proj',
          isKachinuki: false,
          note: '',
        ),
      ];

      final proj = TournamentProjectionMapper.fromProjections(
        fakeTournament,
        scrambledListProjections,
      );

      final teamMatch = proj.teamMatches['grp_proj'];
      expect(teamMatch, isNotNull);
      final types = teamMatch!.matches.map((m) => m.matchType).toList();
      expect(types, ['先鋒', '中堅', '大将', '代表戦']);
    });

    // =========================================================================
    // 5. [動的規約: ポジション体系網羅] 3人/5人/7人/多人数/代表戦 網羅規約
    // =========================================================================
    test('5. 【動的規約: ポジション体系網羅】3人制・5人制・7人制・代表戦・順位戦・追加試合 全配列整合性規約', () {
      // 7人制 + 代表戦 + 順位決定戦 + 追加試合 の逆順リスト
      final reversedPositions = [
        '追加試合',
        '順位決定戦',
        '代表戦',
        '大将',
        '副将',
        '三将',
        '中堅',
        '五将',
        '次鋒',
        '先鋒',
      ];

      final matches = reversedPositions.map((pos) {
        return MatchModel(
          id: 'm_$pos',
          tournamentId: 'tour_gov_1',
          order: 0.0,
          matchType: pos,
          redName: '赤チーム: 選手',
          whiteName: '白チーム: 選手',
        );
      }).toList();

      final sorted = KendoPositionSorter.sortMatches(matches);
      final resultPositions = sorted.map((m) => m.matchType).toList();

      expect(resultPositions, [
        '先鋒',
        '次鋒',
        '五将',
        '中堅',
        '三将',
        '副将',
        '大将',
        '代表戦',
        '順位決定戦',
        '追加試合',
      ]);
    });

    // =========================================================================
    // 6. [動的規約: 異常系耐性] order反転・未設定・同値および文字揺れ耐性規約
    // =========================================================================
    test('6. 【動的規約: 異常系耐性】order反転・未設定・同値および文字揺れ耐性規約', () {
      // order が 100 と 1 で完全に逆転しているケース
      final mTaishoBadOrder = MatchModel(
        id: 'm1',
        order: 1.0, // order が小さい
        matchType: '大将',
        redName: '赤: 大将',
        whiteName: '白: 大将',
      );
      final mSempoBadOrder = MatchModel(
        id: 'm2',
        order: 100.0, // order が大きい
        matchType: '先鋒',
        redName: '赤: 先鋒',
        whiteName: '白: 先鋒',
      );

      final sortedBadOrder = KendoPositionSorter.sortMatches([
        mTaishoBadOrder,
        mSempoBadOrder,
      ]);
      expect(sortedBadOrder.first.matchType, '先鋒');
      expect(sortedBadOrder.last.matchType, '大将');

      // matchType が空で note や選手名に【先鋒】や【大将】が含まれるケース
      final mNoteTaisho = MatchModel(
        id: 'm3',
        matchType: '',
        note: '第3試合 【大将戦】',
        redName: '赤選手',
        whiteName: '白選手',
      );
      final mNoteSempo = MatchModel(
        id: 'm4',
        matchType: '',
        note: '第1試合 【先鋒戦】',
        redName: '赤選手',
        whiteName: '白選手',
      );

      final sortedByNote = KendoPositionSorter.sortMatches([
        mNoteTaisho,
        mNoteSempo,
      ]);
      expect(sortedByNote.first.id, 'm4'); // 先鋒が先
      expect(sortedByNote.last.id, 'm3'); // 大将が後
    });
  });
}
