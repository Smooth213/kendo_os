import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/utils/kendo_position_sorter.dart';

void main() {
  group('KendoPositionSorter Tests', () {
    test('toKanjiNumber converts numbers to kanji correctly', () {
      expect(MatchFormatSetupHelper.toKanjiNumber(1), '一');
      expect(MatchFormatSetupHelper.toKanjiNumber(3), '三');
      expect(MatchFormatSetupHelper.toKanjiNumber(10), '十');
      expect(MatchFormatSetupHelper.toKanjiNumber(11), '十一');
      expect(MatchFormatSetupHelper.toKanjiNumber(20), '二十');
      expect(MatchFormatSetupHelper.toKanjiNumber(25), '二十五');
    });

    test(
      'generatePositions generates correct positions for various team sizes',
      () {
        expect(MatchFormatSetupHelper.generatePositions(3), ['先鋒', '中堅', '大将']);
        expect(MatchFormatSetupHelper.generatePositions(4), [
          '先鋒',
          '次鋒',
          '副将',
          '大将',
        ]);
        expect(MatchFormatSetupHelper.generatePositions(5), [
          '先鋒',
          '次鋒',
          '中堅',
          '副将',
          '大将',
        ]);
        expect(MatchFormatSetupHelper.generatePositions(6), [
          '先鋒',
          '次鋒',
          '四将',
          '三将',
          '副将',
          '大将',
        ]);
        expect(MatchFormatSetupHelper.generatePositions(7), [
          '先鋒',
          '次鋒',
          '五将',
          '中堅',
          '三将',
          '副将',
          '大将',
        ]);
        expect(MatchFormatSetupHelper.generatePositions(8), [
          '先鋒',
          '次鋒',
          '六将',
          '五将',
          '四将',
          '三将',
          '副将',
          '大将',
        ]);
        expect(MatchFormatSetupHelper.generatePositions(9), [
          '先鋒',
          '次鋒',
          '七将',
          '六将',
          '中堅',
          '四将',
          '三将',
          '副将',
          '大将',
        ]);
        expect(MatchFormatSetupHelper.generatePositions(10), [
          '先鋒',
          '次鋒',
          '八将',
          '七将',
          '六将',
          '五将',
          '四将',
          '三将',
          '副将',
          '大将',
        ]);
        expect(MatchFormatSetupHelper.generatePositions(12), [
          '先鋒',
          '次鋒',
          '十将',
          '九将',
          '八将',
          '七将',
          '六将',
          '五将',
          '四将',
          '三将',
          '副将',
          '大将',
        ]);
      },
    );

    test('getPositionPriority returns correct priority for positions', () {
      expect(KendoPositionSorter.getPositionPriority('先鋒'), 10);
      expect(KendoPositionSorter.getPositionPriority('【先鋒】'), 10);
      expect(KendoPositionSorter.getPositionPriority('次鋒'), 20);
      expect(KendoPositionSorter.getPositionPriority('五将'), 26);
      expect(KendoPositionSorter.getPositionPriority('中堅'), 30);
      expect(KendoPositionSorter.getPositionPriority('副将'), 40);
      expect(KendoPositionSorter.getPositionPriority('大将'), 50);
      expect(KendoPositionSorter.getPositionPriority('代表戦'), 100);
      expect(KendoPositionSorter.getPositionPriority('順位決定戦'), 110);
      expect(KendoPositionSorter.getPositionPriority('追加試合'), 120);
      expect(KendoPositionSorter.getPositionPriority('その他'), 999);
      expect(KendoPositionSorter.getPositionPriority(null), 999);
    });

    test('sortMatches sorts scrambled 8-person team matches correctly', () {
      final positions = MatchFormatSetupHelper.generatePositions(8);
      // ['先鋒', '次鋒', '六将', '五将', '四将', '三将', '副将', '大将']
      final matches = positions
          .map(
            (p) => MatchModel(
              id: 'm_$p',
              order: 0,
              matchType: p,
              redName: '赤: $p',
              whiteName: '白: $p',
            ),
          )
          .toList();

      final scrambled = matches.reversed.toList();
      final sorted = KendoPositionSorter.sortMatches(scrambled);
      expect(sorted.map((m) => m.matchType).toList(), positions);
    });

    test(
      'sortMatches sorts scrambled 9-person team matches correctly with Chuken',
      () {
        final positions = MatchFormatSetupHelper.generatePositions(9);
        // ['先鋒', '次鋒', '七将', '六将', '中堅', '四将', '三将', '副将', '大将']
        final matches = positions
            .map(
              (p) => MatchModel(
                id: 'm_$p',
                order: 0,
                matchType: p,
                redName: '赤: $p',
                whiteName: '白: $p',
              ),
            )
            .toList();

        // あえてシャッフル（大将、中堅、先鋒、四将、副将...）
        final scrambled = [
          matches[8], // 大将
          matches[4], // 中堅
          matches[0], // 先鋒
          matches[5], // 四将
          matches[7], // 副将
          matches[2], // 七将
          matches[1], // 次鋒
          matches[6], // 三将
          matches[3], // 六将
        ];
        final sorted = KendoPositionSorter.sortMatches(scrambled);
        expect(sorted.map((m) => m.matchType).toList(), positions);
      },
    );

    test('sortMatches sorts scrambled 10-person team matches correctly', () {
      final positions = MatchFormatSetupHelper.generatePositions(10);
      final matches = positions
          .map(
            (p) => MatchModel(
              id: 'm_$p',
              order: 0,
              matchType: p,
              redName: '赤: $p',
              whiteName: '白: $p',
            ),
          )
          .toList();

      final scrambled = matches.reversed.toList();
      final sorted = KendoPositionSorter.sortMatches(scrambled);
      expect(sorted.map((m) => m.matchType).toList(), positions);
    });

    test('sortMatches handles arabic fallback positions correctly', () {
      final matches = [
        MatchModel(
          id: 'm_taisho',
          order: 0,
          matchType: '大将',
          redName: '',
          whiteName: '',
        ),
        MatchModel(
          id: 'm_sempo',
          order: 0,
          matchType: '先鋒',
          redName: '',
          whiteName: '',
        ),
        MatchModel(
          id: 'm_4',
          order: 0,
          matchType: '4将',
          redName: '',
          whiteName: '',
        ),
        MatchModel(
          id: 'm_6',
          order: 0,
          matchType: '6将',
          redName: '',
          whiteName: '',
        ),
      ];
      final sorted = KendoPositionSorter.sortMatches(matches);
      expect(sorted.map((m) => m.matchType).toList(), ['先鋒', '6将', '4将', '大将']);
    });

    test('sortMatches sorts scrambled 3-person team matches correctly', () {
      // ユーザーの画像にあった「中堅 ➔ 大将 ➔ 先鋒」の乱れを再現
      final chuken = MatchModel(
        id: 'm_chuken',
        order: 2.0,
        matchType: '中堅',
        redName: '道上剣友会: 皿田 史朗',
        whiteName: '相手0012: 相手 選手2',
      );
      final taisho = MatchModel(
        id: 'm_taisho',
        order: 3.0,
        matchType: '大将',
        redName: '道上剣友会: 久安 達也',
        whiteName: '相手0012: 相手 選手3',
      );
      final sempo = MatchModel(
        id: 'm_sempo',
        order: 1.0,
        matchType: '先鋒',
        redName: '道上剣友会: 塚本 達也',
        whiteName: '相手0012: 相手 選手1',
      );

      final scrambled = [chuken, taisho, sempo];
      final sorted = KendoPositionSorter.sortMatches(scrambled);

      expect(sorted.map((m) => m.matchType).toList(), ['先鋒', '中堅', '大将']);
      expect(sorted.first.redName, contains('塚本'));
      expect(sorted[1].redName, contains('皿田'));
      expect(sorted.last.redName, contains('久安'));
    });

    test('sortMatches prioritizes position over incorrect order', () {
      // order がバグで逆順になっていても、剣道ポジション順序が優先されること
      final sempo = MatchModel(
        id: 'm_sempo',
        order: 99.0,
        matchType: '先鋒',
        redName: '赤: 先鋒',
        whiteName: '白: 先鋒',
      );
      final taisho = MatchModel(
        id: 'm_taisho',
        order: 1.0,
        matchType: '大将',
        redName: '赤: 大将',
        whiteName: '白: 大将',
      );

      final sorted = KendoPositionSorter.sortMatches([taisho, sempo]);
      expect(sorted.first.matchType, '先鋒');
      expect(sorted.last.matchType, '大将');
    });

    test('sortProjections sorts 5-person plus daihyo match correctly', () {
      final pDaihyo = MatchListProjection(
        id: 'p_daihyo',
        tournamentId: 't1',
        matchOrder: 0,
        matchType: '代表戦',
        status: 'finished',
        redName: 'A: 塚本',
        whiteName: 'B: 田中',
        redScore: 1,
        whiteScore: 0,
        groupName: 'G1',
        isKachinuki: false,
        note: '',
        firstPointSide: 'red',
        redPointMarks: ['メ'],
        whitePointMarks: [],
      );

      final pSempo = MatchListProjection(
        id: 'p_sempo',
        tournamentId: 't1',
        matchOrder: 0,
        matchType: '先鋒',
        status: 'finished',
        redName: 'A: 先鋒',
        whiteName: 'B: 先鋒',
        redScore: 0,
        whiteScore: 0,
        groupName: 'G1',
        isKachinuki: false,
        note: '',
        firstPointSide: '',
        redPointMarks: [],
        whitePointMarks: [],
      );

      final pTaisho = MatchListProjection(
        id: 'p_taisho',
        tournamentId: 't1',
        matchOrder: 0,
        matchType: '大将',
        status: 'finished',
        redName: 'A: 大将',
        whiteName: 'B: 大将',
        redScore: 0,
        whiteScore: 0,
        groupName: 'G1',
        isKachinuki: false,
        note: '',
        firstPointSide: '',
        redPointMarks: [],
        whitePointMarks: [],
      );

      final pJiho = MatchListProjection(
        id: 'p_jiho',
        tournamentId: 't1',
        matchOrder: 0,
        matchType: '次鋒',
        status: 'finished',
        redName: 'A: 次鋒',
        whiteName: 'B: 次鋒',
        redScore: 0,
        whiteScore: 0,
        groupName: 'G1',
        isKachinuki: false,
        note: '',
        firstPointSide: '',
        redPointMarks: [],
        whitePointMarks: [],
      );

      final pFukusho = MatchListProjection(
        id: 'p_fukusho',
        tournamentId: 't1',
        matchOrder: 0,
        matchType: '副将',
        status: 'finished',
        redName: 'A: 副将',
        whiteName: 'B: 副将',
        redScore: 0,
        whiteScore: 0,
        groupName: 'G1',
        isKachinuki: false,
        note: '',
        firstPointSide: '',
        redPointMarks: [],
        whitePointMarks: [],
      );

      final pChuken = MatchListProjection(
        id: 'p_chuken',
        tournamentId: 't1',
        matchOrder: 0,
        matchType: '中堅',
        status: 'finished',
        redName: 'A: 中堅',
        whiteName: 'B: 中堅',
        redScore: 0,
        whiteScore: 0,
        groupName: 'G1',
        isKachinuki: false,
        note: '',
        firstPointSide: '',
        redPointMarks: [],
        whitePointMarks: [],
      );

      // 完全シャッフル状態
      final projections = [pDaihyo, pTaisho, pChuken, pSempo, pFukusho, pJiho];
      final sorted = KendoPositionSorter.sortProjections(projections);

      expect(sorted.map((p) => p.matchType).toList(), [
        '先鋒',
        '次鋒',
        '中堅',
        '副将',
        '大将',
        '代表戦',
      ]);
    });

    test(
      'resolveMatchPriority extracts position from note or player name if matchType is empty',
      () {
        final p1 = MatchListProjection(
          id: 'p1',
          tournamentId: 't1',
          matchOrder: 0,
          matchType: '',
          status: 'pending',
          redName: '道上: 皿田 [大将]',
          whiteName: '相手: 選手3',
          redScore: 0,
          whiteScore: 0,
          groupName: 'G1',
          isKachinuki: false,
          note: '',
          firstPointSide: '',
          redPointMarks: [],
          whitePointMarks: [],
        );

        final p2 = MatchListProjection(
          id: 'p2',
          tournamentId: 't1',
          matchOrder: 0,
          matchType: '',
          status: 'pending',
          redName: '道上: 塚本',
          whiteName: '相手: 選手1',
          redScore: 0,
          whiteScore: 0,
          groupName: 'G1',
          isKachinuki: false,
          note: '第1試合 【先鋒戦】',
          firstPointSide: '',
          redPointMarks: [],
          whitePointMarks: [],
        );

        final sorted = KendoPositionSorter.sortProjections([p1, p2]);
        expect(sorted.first.id, 'p2'); // 先鋒が最初
        expect(sorted.last.id, 'p1'); // 大将が後
      },
    );
  });
}
