import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/pdf/models/pdf_view_model.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/presentation/utils/match_calculator_helper.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_score_box.dart';

void main() {
  group('🥋 反則マーク「△」の表示および先取丸囲み除外テスト', () {
    late KendoRuleEngine ruleEngine;
    final dummyMatch = MatchModel(
      id: 'm1',
      tournamentId: 't1',
      matchType: '個人戦',
      redName: '選手A',
      whiteName: '選手B',
      matchTimeMinutes: 3.0,
      rule: const MatchRule(),
    );

    setUp(() {
      ruleEngine = KendoRuleEngine();
    });

    test('1. 赤の反則1回の場合、赤のdisplaysに「△」が追加され、先取フラグはfalseであること', () {
      final now = DateTime(2026, 9, 3, 10, 0, 0);
      final events = [
        ScoreEvent(
          id: 'h1',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 10)),
        ),
      ];

      final analysis = ruleEngine.analyzeHistory(
        events,
        dummyMatch,
        const MatchRule(),
      );

      final redDisplays = analysis.displays[Side.red] ?? [];
      final whiteDisplays = analysis.displays[Side.white] ?? [];

      expect(redDisplays.length, 1);
      expect(redDisplays[0].mark, '△');
      expect(redDisplays[0].isFirstMatchPoint, isFalse);

      expect(whiteDisplays, isEmpty);
      expect(analysis.context.redIppon, 0);
      expect(analysis.context.whiteIppon, 0);
      expect(analysis.context.redHansoku, 1);
    });

    test('2. 赤の反則1回後に赤がメンを取った場合、赤のdisplaysは「△」と先取「メ」になること', () {
      final now = DateTime(2026, 9, 3, 10, 0, 0);
      final events = [
        ScoreEvent(
          id: 'h1',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 10)),
        ),
        ScoreEvent(
          id: 'm1',
          side: Side.red,
          strikeType: StrikeType.men,
          timestamp: now.add(const Duration(seconds: 20)),
        ),
      ];

      final analysis = ruleEngine.analyzeHistory(
        events,
        dummyMatch,
        const MatchRule(),
      );

      final redDisplays = analysis.displays[Side.red] ?? [];
      expect(redDisplays.length, 2);
      expect(redDisplays[0].mark, '△');
      expect(redDisplays[0].isFirstMatchPoint, isFalse);
      expect(redDisplays[1].mark, 'メ');
      expect(redDisplays[1].isFirstMatchPoint, isTrue); // 試合の最初の一本なので先取となる
    });

    test('3. 赤の反則2回の場合、赤の「△」が消えて白に「反」が1本付与されること', () {
      final now = DateTime(2026, 9, 3, 10, 0, 0);
      final events = [
        ScoreEvent(
          id: 'h1',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 10)),
        ),
        ScoreEvent(
          id: 'h2',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 20)),
        ),
      ];

      final analysis = ruleEngine.analyzeHistory(
        events,
        dummyMatch,
        const MatchRule(),
      );

      final redDisplays = analysis.displays[Side.red] ?? [];
      final whiteDisplays = analysis.displays[Side.white] ?? [];

      expect(redDisplays, isEmpty); // 反則2回で一本昇格したため△は消去
      expect(whiteDisplays.length, 1);
      expect(whiteDisplays[0].mark, '反');
      expect(whiteDisplays[0].isFirstMatchPoint, isTrue);

      expect(analysis.context.redIppon, 0);
      expect(analysis.context.whiteIppon, 1);
    });

    test('4. 赤の反則3回の場合、白に「反」が1本、赤に「△」が1つ付与されること', () {
      final now = DateTime(2026, 9, 3, 10, 0, 0);
      final events = [
        ScoreEvent(
          id: 'h1',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 10)),
        ),
        ScoreEvent(
          id: 'h2',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 20)),
        ),
        ScoreEvent(
          id: 'h3',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 30)),
        ),
      ];

      final analysis = ruleEngine.analyzeHistory(
        events,
        dummyMatch,
        const MatchRule(),
      );

      final redDisplays = analysis.displays[Side.red] ?? [];
      final whiteDisplays = analysis.displays[Side.white] ?? [];

      expect(redDisplays.length, 1);
      expect(redDisplays[0].mark, '△');
      expect(redDisplays[0].isFirstMatchPoint, isFalse);

      expect(whiteDisplays.length, 1);
      expect(whiteDisplays[0].mark, '反');
      expect(analysis.context.whiteIppon, 1);
    });

    test('5. KendoPointMark: △ および ▲ は isSpecialNonCircle が true であること', () {
      const markTriangle = KendoPointMark(mark: '△', isFirst: true);
      const markSolidTriangle = KendoPointMark(mark: '▲', isFirst: true);
      const markMen = KendoPointMark(mark: 'メ', isFirst: true);

      expect(markTriangle.isSpecialNonCircle, isTrue);
      expect(markSolidTriangle.isSpecialNonCircle, isTrue);
      expect(markMen.isSpecialNonCircle, isFalse);
    });

    test(
      '6. MatchCalculatorHelper.extractPointsFromProjection で先頭に△があっても次の技に先取フラグが付与されること',
      () {
        final proj = MatchListProjection(
          id: 'p1',
          tournamentId: 't1',
          matchOrder: 1,
          matchType: '個人戦',
          status: 'finished',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 1,
          whiteScore: 0,
          firstPointSide: 'red',
          redPointMarks: const ['△', 'メ'],
          whitePointMarks: const [],
        );

        final pts = MatchCalculatorHelper.extractPointsFromProjection(proj);
        final redPts = pts['red']!;

        expect(redPts.length, 2);
        expect(redPts[0].mark, '△');
        expect(redPts[0].isFirst, isFalse);
        expect(redPts[1].mark, 'メ');
        expect(redPts[1].isFirst, isTrue);
      },
    );

    test('7. PdfViewModel.calculatePointsRaw で先頭に△があっても正しく変換されること', () {
      final proj = MatchListProjection(
        id: 'p1',
        tournamentId: 't1',
        matchOrder: 1,
        matchType: '個人戦',
        status: 'finished',
        redName: '選手A',
        whiteName: '選手B',
        redScore: 1,
        whiteScore: 0,
        firstPointSide: 'red',
        redPointMarks: const ['△', 'メ'],
        whitePointMarks: const [],
      );

      final pts = PdfViewModel.calculatePointsRaw(proj);
      final redPts = pts['red']!;

      expect(redPts.length, 2);
      expect(redPts[0].mark, '△');
      expect(redPts[0].isFirstOverall, isFalse);
      expect(redPts[1].mark, 'メ');
      expect(redPts[1].isFirstOverall, isTrue);
    });
  });
}
