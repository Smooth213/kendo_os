import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_allocation_engine.dart';

void main() {
  group('🧮 MatchAllocationEngine Unit Tests', () {
    test('1リーグ総当たり: 4名で6試合、5名で10試合になること', () {
      final s4 = const CalculatorSettings(
        format: MatchFormatType.singleLeague,
        participantCount: 4,
        courtCount: 1,
      );
      final r4 = MatchAllocationEngine.calculate(s4);
      expect(r4.totalMatches, 6);
      expect(r4.courtMatches[1]?.length, 6);

      final s5 = const CalculatorSettings(
        format: MatchFormatType.singleLeague,
        participantCount: 5,
        courtCount: 1,
      );
      final r5 = MatchAllocationEngine.calculate(s5);
      expect(r5.totalMatches, 10);
    });

    test('複数リーグ総当たり: 8名2リーグ（各4名）で計12試合になること', () {
      final s = const CalculatorSettings(
        format: MatchFormatType.multiLeague,
        participantCount: 8,
        leagueCount: 2,
        courtCount: 2,
      );
      final r = MatchAllocationEngine.calculate(s);
      expect(r.totalMatches, 12);
      expect(r.matchesPerCategory['Aリーグ'], 6);
      expect(r.matchesPerCategory['Bリーグ'], 6);
    });

    test('ユーザー要求: 出場10名でAリーグ4名・Bリーグ6人のカスタム配分で計21試合になること', () {
      final s = const CalculatorSettings(
        format: MatchFormatType.multiLeague,
        participantCount: 10,
        leagueCount: 2,
        courtCount: 2,
        customLeagueParticipants: [4, 6],
      );
      final r = MatchAllocationEngine.calculate(s);
      // Aリーグ4名: 4*3/2 = 6試合
      // Bリーグ6名: 6*5/2 = 15試合
      // 合計 = 21試合
      expect(r.totalMatches, 21);
      expect(r.matchesPerCategory['Aリーグ'], 6);
      expect(r.matchesPerCategory['Bリーグ'], 15);
      expect(s.effectiveParticipantCount, 10);
    });

    test('30秒単位のカスタム時間設定（例: 2分30秒 + 30秒 = 3分枠）で正確に時間計算されること', () {
      final s = const CalculatorSettings(
        format: MatchFormatType.singleLeague,
        participantCount: 4, // 6試合
        courtCount: 1,
        matchDurationMinutes: 2.5, // 2分30秒
        intervalDurationMinutes: 0.5, // 30秒
        startTime: TimeOfDay(hour: 13, minute: 0),
      );
      final r = MatchAllocationEngine.calculate(s);
      // 6試合 * 2.5分 + 5インターバル * 0.5分 = 15分 + 2.5分 = 17.5分 (17分30秒 => inMinutesは17)
      expect(r.totalEstimatedMinutes, 17);
      expect(r.estimatedEndTime.hour, 13);
      expect(r.estimatedEndTime.minute, 17);
      expect(r.estimatedEndTime.second, 30);
    });

    test('トーナメント戦: 8名で3決あり8試合、3決なし7試合になること', () {
      final sWith3rd = const CalculatorSettings(
        format: MatchFormatType.tournament,
        participantCount: 8,
        hasThirdPlaceMatch: true,
      );
      final rWith3rd = MatchAllocationEngine.calculate(sWith3rd);
      expect(rWith3rd.totalMatches, 8);

      final sNo3rd = const CalculatorSettings(
        format: MatchFormatType.tournament,
        participantCount: 8,
        hasThirdPlaceMatch: false,
      );
      final rNo3rd = MatchAllocationEngine.calculate(sNo3rd);
      expect(rNo3rd.totalMatches, 7);
    });

    test('予選リーグ＋決勝トーナメント: 予選12試合＋決勝T(4名3決あり)4試合＝計16試合になること', () {
      final s = const CalculatorSettings(
        format: MatchFormatType.prelimLeagueAndTournament,
        participantCount: 8,
        leagueCount: 2,
        advancingCountPerLeague: 2,
        hasThirdPlaceMatch: true,
      );
      final r = MatchAllocationEngine.calculate(s);
      expect(r.totalMatches, 16);
      expect(r.matchesPerCategory['予選Aリーグ'], 6);
      expect(r.matchesPerCategory['予選Bリーグ'], 6);
      expect(r.matchesPerCategory['決勝トーナメント'], 4);
    });

    test('所要時間と終了時刻のシミュレーション計算が正確であること', () {
      // 試合3分 + インターバル1分 = 1試合4分枠
      // 1コートで6試合の場合: 6 * 3分(試合) + 5 * 1分(インターバル) = 18 + 5 = 23分
      final s = const CalculatorSettings(
        format: MatchFormatType.singleLeague,
        participantCount: 4,
        courtCount: 1,
        matchDurationMinutes: 3,
        intervalDurationMinutes: 1,
        startTime: TimeOfDay(hour: 10, minute: 0),
      );
      final r = MatchAllocationEngine.calculate(s);
      expect(r.totalEstimatedMinutes, 23);
      expect(r.estimatedEndTime.hour, 10);
      expect(r.estimatedEndTime.minute, 23);
    });

    test('パターンA (インターバル優先): 2コートに均等・交互に配分されること', () {
      final s = const CalculatorSettings(
        format: MatchFormatType.multiLeague,
        pattern: AllocationPattern.patternA,
        participantCount: 8,
        leagueCount: 2,
        courtCount: 2,
      );
      final r = MatchAllocationEngine.calculate(s);
      expect(r.totalMatches, 12);
      final c1Matches = r.courtMatches[1]!.length;
      final c2Matches = r.courtMatches[2]!.length;
      expect(c1Matches + c2Matches, 12);
      expect((c1Matches - c2Matches).abs(), lessThanOrEqualTo(1));
    });

    test('パターンB (コート均等負荷): 3コートに均等に分配されること', () {
      final s = const CalculatorSettings(
        format: MatchFormatType.singleLeague,
        pattern: AllocationPattern.patternB,
        participantCount: 5, // 10試合
        courtCount: 3,
      );
      final r = MatchAllocationEngine.calculate(s);
      expect(r.totalMatches, 10);
      expect(r.courtMatches[1]!.length, 4);
      expect(r.courtMatches[2]!.length, 3);
      expect(r.courtMatches[3]!.length, 3);
    });

    test('パターンC (ブロック専任): Aリーグがコート1、Bリーグがコート2に割り当てられること', () {
      final s = const CalculatorSettings(
        format: MatchFormatType.multiLeague,
        pattern: AllocationPattern.patternC,
        participantCount: 8,
        leagueCount: 2,
        courtCount: 2,
      );
      final r = MatchAllocationEngine.calculate(s);
      expect(r.totalMatches, 12);

      // コート1はすべてAリーグ
      for (final m in r.courtMatches[1]!) {
        expect(m.categoryName, 'Aリーグ');
      }
      // コート2はすべてBリーグ
      for (final m in r.courtMatches[2]!) {
        expect(m.categoryName, 'Bリーグ');
      }
    });

    test('コート移動最少モード: 同一グループが同一コートに集中すること', () {
      final s = const CalculatorSettings(
        format: MatchFormatType.multiLeague,
        pattern: AllocationPattern.minimalMovement,
        participantCount: 8,
        leagueCount: 2,
        courtCount: 2,
      );
      final r = MatchAllocationEngine.calculate(s);
      expect(r.totalMatches, 12);
      expect(r.courtMatches[1]!.length, 6);
      expect(r.courtMatches[2]!.length, 6);

      final court1Category = r.courtMatches[1]!.first.categoryName;
      for (final m in r.courtMatches[1]!) {
        expect(m.categoryName, court1Category);
      }
    });

    test('ユーザー要求: リーグごとに異なる試合時間（A:2分, B:2.5分, C:3分）が各試合に正しく反映されること', () {
      final s = const CalculatorSettings(
        format: MatchFormatType.multiLeague,
        participantCount: 9,
        leagueCount: 3,
        courtCount: 3,
        customLeagueParticipants: [3, 3, 3], // 各3名 → 各3試合、計9試合
        useCustomLeagueMatchDurations: true,
        customLeagueMatchDurations: [2.0, 2.5, 3.0], // A=2分, B=2.5分, C=3分
        pattern: AllocationPattern.patternC, // ブロック専任
        intervalDurationMinutes: 1.0,
      );
      final r = MatchAllocationEngine.calculate(s);
      expect(r.totalMatches, 9);

      // コート1 (Aリーグ): 試合時間は各2分
      for (final m in r.courtMatches[1]!) {
        expect(m.categoryName, 'Aリーグ');
        expect(m.durationMinutes, 2.0);
      }

      // コート2 (Bリーグ): 試合時間は各2.5分
      for (final m in r.courtMatches[2]!) {
        expect(m.categoryName, 'Bリーグ');
        expect(m.durationMinutes, 2.5);
      }

      // コート3 (Cリーグ): 試合時間は各3分
      for (final m in r.courtMatches[3]!) {
        expect(m.categoryName, 'Cリーグ');
        expect(m.durationMinutes, 3.0);
      }
    });

    test('クリップボードコピー用文字列が正しく生成されること', () {
      final s = const CalculatorSettings(
        format: MatchFormatType.singleLeague,
        participantCount: 4,
        courtCount: 1,
      );
      final r = MatchAllocationEngine.calculate(s);
      final text = MatchAllocationEngine.formatSummaryForClipboard(s, r);

      expect(text.contains('【部内戦 コート配分・進行計画】'), isTrue);
      expect(text.contains('・形式: 1リーグ総当たり'), isTrue);
      expect(text.contains('・総試合数: 6試合'), isTrue);
      expect(text.contains('■ 第1コート'), isTrue);
    });
  });
}
