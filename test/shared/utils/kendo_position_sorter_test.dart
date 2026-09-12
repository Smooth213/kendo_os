import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/utils/kendo_position_sorter.dart';

void main() {
  group('KendoPositionSorter Tests', () {
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
