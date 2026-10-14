import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_team_table.dart';
import 'package:kendo_os/shared/application/projections/tournament_projection_mapper.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late pw.Font ttf;
  late pw.Font ttfBold;

  setUpAll(() async {
    final fontData = await rootBundle.load(
      'assets/fonts/NotoSansJP-Regular.ttf',
    );
    ttf = pw.Font.ttf(fontData.buffer.asByteData());
    final fontBoldData = await rootBundle.load(
      'assets/fonts/NotoSansJP-Bold.ttf',
    );
    ttfBold = pw.Font.ttf(fontBoldData.buffer.asByteData());
  });

  group('[E2E] 剣道形 団体戦運用ライフサイクル結合テスト', () {
    const kataRule = MatchRule(
      isKataMatch: true,
      matchTimeMinutes: 0.0,
      hasHantei: true,
      enchoCount: 0,
    );

    test(
      '形競技の団体戦において旗判定と不戦勝が混在する場合でも本数差ではなく勝数のみで勝敗が決定されPDF出力まで整合すること',
      () async {
        // 1. 3人制の形競技団体戦マッチを作成
        // 先鋒: 赤 3 - 0 白 (赤判定勝ち)
        final senpo = MatchModel(
          id: 'team_kata_senpo',
          tournamentId: 't_team_kata',
          order: 1.0,
          matchType: '先鋒戦',
          status: 'finished',
          redName: '道上剣友会:皿田 脩人・塚本 大道',
          whiteName: '友道館:佐藤 健一・鈴木 次郎',
          groupName: '道上剣友会 vs 友道館',
          category: '形の部',
          rule: kataRule,
          redScore: 3,
          whiteScore: 0,
          events: [
            ScoreEventLegacyAdapter.fromLegacy(
              id: 'ev_s1',
              type: PointType.hantei,
              side: Side.red,
              timestamp: SystemTimeSource().now(),
            ),
          ],
        );

        // 次鋒: 赤 1 - 2 白 (白判定勝ち)
        final jiho = MatchModel(
          id: 'team_kata_jiho',
          tournamentId: 't_team_kata',
          order: 2.0,
          matchType: '次鋒戦',
          status: 'finished',
          redName: '道上剣友会:田中 一郎・井上 隆',
          whiteName: '友道館:高橋 大輔・渡辺 徹',
          groupName: '道上剣友会 vs 友道館',
          category: '形の部',
          rule: kataRule,
          redScore: 1,
          whiteScore: 2,
          events: [
            ScoreEventLegacyAdapter.fromLegacy(
              id: 'ev_j1',
              type: PointType.hantei,
              side: Side.white,
              timestamp: SystemTimeSource().now(),
            ),
          ],
        );

        // 大将: 赤 ○ - × 白 (赤不戦勝)
        final taisho = MatchModel(
          id: 'team_kata_taisho',
          tournamentId: 't_team_kata',
          order: 3.0,
          matchType: '大将戦',
          status: 'finished',
          redName: '道上剣友会:山本 健・小林 誠',
          whiteName: '友道館:欠員',
          groupName: '道上剣友会 vs 友道館',
          category: '形の部',
          rule: kataRule,
          redScore: 1,
          whiteScore: 0,
          events: [
            ScoreEventLegacyAdapter.fromLegacy(
              id: 'ev_t1',
              type: PointType.fusen,
              side: Side.red,
              timestamp: SystemTimeSource().now(),
            ),
          ],
        );

        final matches = [senpo, jiho, taisho];

        // 2. TeamMatchCalculator での集計検証
        // 勝数: 赤2勝 (先鋒、大将), 白1勝 (次鋒)
        // 判定旗合計: 赤5本 (3 + 1 + 1), 白2本 (0 + 2 + 0)
        final calcResult = TeamMatchCalculator.calculate(matches);
        expect(calcResult.allFinished, isTrue);
        expect(calcResult.redWins, 2);
        expect(calcResult.whiteWins, 1);
        expect(calcResult.isTie, isFalse);
        expect(calcResult.teamWinner, 'red');

        // 3. TournamentProjectionMapper による大会集約マッピング検証
        final tournament = TournamentModel(
          id: 't_team_kata',
          organizationId: 'org_1',
          name: '剣道形大会',
          categories: ['形の部'],
          date: DateTime(2026, 10, 14),
          venue: '武道館',
        );

        final projection = TournamentProjectionMapper.fromModels(
          tournament,
          matches,
        );
        final teamMatchProj = projection.teamMatches['道上剣友会 vs 友道館'];
        expect(teamMatchProj, isNotNull);
        expect(teamMatchProj!.result.redWins, 2);
        expect(teamMatchProj.result.whiteWins, 1);
        expect(teamMatchProj.result.teamWinner, 'red');

        // 4. PDF出力（PdfTeamTable）パイプライン検証
        final pdf = pw.Document();
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
            build: (context) => [
              PdfTeamTable.build('道上剣友会 vs 友道館', matches, ttf, ttfBold),
            ],
          ),
        );

        final Uint8List pdfBytes = await pdf.save();
        expect(pdfBytes, isNotEmpty);
        expect(String.fromCharCodes(pdfBytes.sublist(0, 4)), '%PDF');
      },
    );

    test('形競技の団体戦において勝数同数で旗数差がある場合でも本数勝ちは発生せず引き分け（代表戦へ）となること', () async {
      // 先鋒: 赤 3 - 0 白 (赤勝ち, 3本)
      final m1 = MatchModel(
        id: 'k_draw_1',
        tournamentId: 't_team_kata',
        order: 1.0,
        matchType: '先鋒戦',
        status: 'finished',
        redName: 'Aチーム:選手1',
        whiteName: 'Bチーム:選手1',
        groupName: 'Aチーム vs Bチーム',
        rule: kataRule,
        redScore: 3,
        whiteScore: 0,
        events: [
          ScoreEventLegacyAdapter.fromLegacy(
            id: 'ev_d1',
            type: PointType.hantei,
            side: Side.red,
            timestamp: SystemTimeSource().now(),
          ),
        ],
      );
      // 次鋒: 赤 1 - 2 白 (白勝ち, 白2本, 赤1本)
      final m2 = MatchModel(
        id: 'k_draw_2',
        tournamentId: 't_team_kata',
        order: 2.0,
        matchType: '次鋒戦',
        status: 'finished',
        redName: 'Aチーム:選手2',
        whiteName: 'Bチーム:選手2',
        groupName: 'Aチーム vs Bチーム',
        rule: kataRule,
        redScore: 1,
        whiteScore: 2,
        events: [
          ScoreEventLegacyAdapter.fromLegacy(
            id: 'ev_d2',
            type: PointType.hantei,
            side: Side.white,
            timestamp: SystemTimeSource().now(),
          ),
        ],
      );
      // 大将: 赤 0 - 0 白 (引き分け)
      final m3 = MatchModel(
        id: 'k_draw_3',
        tournamentId: 't_team_kata',
        order: 3.0,
        matchType: '大将戦',
        status: 'finished',
        redName: 'Aチーム:選手3',
        whiteName: 'Bチーム:選手3',
        groupName: 'Aチーム vs Bチーム',
        rule: kataRule,
        redScore: 0,
        whiteScore: 0,
      );

      final drawMatches = [m1, m2, m3];
      final calcResult = TeamMatchCalculator.calculate(drawMatches);

      // 勝数: 赤1勝, 白1勝 (同数)
      // 旗数(本数): 赤4本, 白2本 (赤が多い)
      // 竹刀競技なら赤の本数勝ちだが、形競技には「本数」が存在しないため引き分け判定
      expect(calcResult.redWins, 1);
      expect(calcResult.whiteWins, 1);
      expect(calcResult.redPoints, 4);
      expect(calcResult.whitePoints, 2);
      expect(calcResult.isTie, isTrue);
      expect(calcResult.teamWinner, 'draw');

      // ProjectionMapper でも同様に引き分けとなること
      final tournament = TournamentModel(
        id: 't_team_kata',
        organizationId: 'org_1',
        name: '剣道形大会',
        categories: ['形の部'],
        date: DateTime(2026, 10, 14),
        venue: '武道館',
      );

      final projection = TournamentProjectionMapper.fromModels(
        tournament,
        drawMatches,
      );
      final proj = projection.teamMatches['Aチーム vs Bチーム'];
      expect(proj, isNotNull);
      expect(proj!.result.redWins, 1);
      expect(proj.result.whiteWins, 1);
      expect(proj.result.isTie, isTrue);
      expect(proj.result.teamWinner, 'draw');
    });
  });
}
