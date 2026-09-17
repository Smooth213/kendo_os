import 'package:intl/intl.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_generation_helper.dart';

/// 🥋 試合数計算＆コート配分シミュレーションエンジン
class MatchAllocationEngine {
  MatchAllocationEngine._();

  /// 設定に基づいて割り振りを実行
  static AllocationResult calculate(CalculatorSettings settings) {
    final courtCount = settings.courtCount.clamp(1, 12);
    final rawMatches = MatchGenerationHelper.generateMatches(settings);
    final totalMatches = rawMatches.length;

    // カテゴリごとの試合数集計
    final matchesPerCategory = <String, int>{};
    for (final m in rawMatches) {
      matchesPerCategory[m.categoryName] =
          (matchesPerCategory[m.categoryName] ?? 0) + 1;
    }

    // 4つのモードに応じたコートへの分配
    final courtBuckets = <int, List<GeneratedMatch>>{};
    for (int i = 1; i <= courtCount; i++) {
      courtBuckets[i] = [];
    }

    switch (settings.pattern) {
      case AllocationPattern.patternA:
        _allocatePatternA(rawMatches, courtBuckets, courtCount);
        break;
      case AllocationPattern.patternB:
        _allocatePatternB(rawMatches, courtBuckets, courtCount);
        break;
      case AllocationPattern.patternC:
        _allocatePatternC(rawMatches, courtBuckets, courtCount);
        break;
      case AllocationPattern.minimalMovement:
        _allocateMinimalMovement(rawMatches, courtBuckets, courtCount);
        break;
    }

    // 各コートの試合に推定時間を付与
    final now = DateTime.now();
    final baseStart = DateTime(
      now.year,
      now.month,
      now.day,
      settings.startTime.hour,
      settings.startTime.minute,
    );

    final intervalDuration = Duration(
      seconds: (settings.intervalDurationMinutes * 60).round(),
    );

    final courtMatchesResult = <int, List<AllocatedMatch>>{};
    int maxMatches = 0;
    DateTime latestEndTime = baseStart;

    for (int c = 1; c <= courtCount; c++) {
      final matchesInCourt = courtBuckets[c] ?? [];
      final allocatedList = <AllocatedMatch>[];
      DateTime currentStart = baseStart;

      for (int i = 0; i < matchesInCourt.length; i++) {
        final raw = matchesInCourt[i];
        final matchDuration = Duration(
          seconds: (raw.durationMinutes * 60).round(),
        );
        final matchEnd = currentStart.add(matchDuration);
        allocatedList.add(
          AllocatedMatch(
            courtNumber: c,
            matchOrder: i + 1,
            categoryName: raw.categoryName,
            matchTitle: raw.matchTitle,
            pairDescription: raw.pairDescription,
            durationMinutes: raw.durationMinutes,
            estimatedStart: currentStart,
            estimatedEnd: matchEnd,
          ),
        );
        // 次の試合の開始時刻（試合終了 + インターバル）
        currentStart = matchEnd.add(intervalDuration);
      }

      courtMatchesResult[c] = allocatedList;
      if (allocatedList.length > maxMatches) {
        maxMatches = allocatedList.length;
      }
      if (allocatedList.isNotEmpty) {
        final lastEnd = allocatedList.last.estimatedEnd;
        if (lastEnd.isAfter(latestEndTime)) {
          latestEndTime = lastEnd;
        }
      }
    }

    // 全体の所要分
    final totalMinutes = latestEndTime.difference(baseStart).inMinutes;

    return AllocationResult(
      totalMatches: totalMatches,
      courtMatches: courtMatchesResult,
      maxCourtMatches: maxMatches,
      totalEstimatedMinutes: totalMinutes,
      estimatedEndTime: latestEndTime,
      matchesPerCategory: matchesPerCategory,
    );
  }

  /// パターンA: インターバル優先・交互
  static void _allocatePatternA(
    List<GeneratedMatch> matches,
    Map<int, List<GeneratedMatch>> buckets,
    int courtCount,
  ) {
    // グループ別・ラウンド別にインターリーブして各コートへ分散
    // グループをキーにして試合キューを作成
    final groupMap = <int, List<GeneratedMatch>>{};
    for (final m in matches) {
      groupMap.putIfAbsent(m.groupIndex, () => []).add(m);
    }

    final groups = groupMap.keys.toList()..sort();
    int currentCourt = 1;

    // ラウンドロビンで各グループから1試合ずつ取り出してコートに均等配分
    bool hasMore = true;
    while (hasMore) {
      hasMore = false;
      for (final g in groups) {
        final queue = groupMap[g]!;
        if (queue.isNotEmpty) {
          final m = queue.removeAt(0);
          buckets[currentCourt]!.add(m);
          currentCourt = (currentCourt % courtCount) + 1;
          hasMore = true;
        }
      }
    }
  }

  /// パターンB: コート均等負荷バランス
  static void _allocatePatternB(
    List<GeneratedMatch> matches,
    Map<int, List<GeneratedMatch>> buckets,
    int courtCount,
  ) {
    // 全体をラウンド順にソートし、コート1から均等に順番付け
    final sorted = List<GeneratedMatch>.from(matches)
      ..sort((a, b) {
        final rComp = a.roundIndex.compareTo(b.roundIndex);
        if (rComp != 0) return rComp;
        return a.groupIndex.compareTo(b.groupIndex);
      });

    for (int i = 0; i < sorted.length; i++) {
      final court = (i % courtCount) + 1;
      buckets[court]!.add(sorted[i]);
    }
  }

  /// パターンC: ブロック専任進行
  static void _allocatePatternC(
    List<GeneratedMatch> matches,
    Map<int, List<GeneratedMatch>> buckets,
    int courtCount,
  ) {
    // リーグ/ブロック（groupIndex）ごとに担当コートを固定
    for (final m in matches) {
      // 決勝トーナメント等は第1コートまたは全コートで分散
      final targetCourt = (m.groupIndex % courtCount) + 1;
      buckets[targetCourt]!.add(m);
    }
  }

  /// コート移動最少モード:
  /// 同一グループを同一コートにまとめ、同一コート内でラウンド順に間隔を空けて配置
  static void _allocateMinimalMovement(
    List<GeneratedMatch> matches,
    Map<int, List<GeneratedMatch>> buckets,
    int courtCount,
  ) {
    // 各グループの試合数を見て、負荷が均等になるようにグループ単位でコートを割り振り
    final groupMap = <int, List<GeneratedMatch>>{};
    for (final m in matches) {
      groupMap.putIfAbsent(m.groupIndex, () => []).add(m);
    }

    final sortedGroups = groupMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    for (final entry in sortedGroups) {
      // 最も試合数が少ないコートを探して割り当て
      int bestCourt = 1;
      int minMatches = buckets[1]!.length;
      for (int c = 2; c <= courtCount; c++) {
        if (buckets[c]!.length < minMatches) {
          minMatches = buckets[c]!.length;
          bestCourt = c;
        }
      }

      // コート内ではラウンド順に配置
      final groupMatches = entry.value
        ..sort((a, b) => a.roundIndex.compareTo(b.roundIndex));
      buckets[bestCourt]!.addAll(groupMatches);
    }
  }

  /// クリップボードやメモ貼付用の要約テキスト生成
  static String formatSummaryForClipboard(
    CalculatorSettings settings,
    AllocationResult result,
  ) {
    final timeFmt = DateFormat('HH:mm');
    final sb = StringBuffer();

    sb.writeln('【部内戦 コート配分・進行計画】');
    sb.writeln('・形式: ${settings.format.label}');
    if (settings.format == MatchFormatType.multiLeague ||
        settings.format == MatchFormatType.prelimLeagueAndTournament) {
      final counts = settings.leagueParticipantCounts;
      final details = List.generate(
        counts.length,
        (i) => '${String.fromCharCode(65 + i)}: ${counts[i]}名',
      ).join(', ');
      sb.writeln('・参加人数: 合計${settings.effectiveParticipantCount}名 ($details)');
      sb.writeln('・リーグ数: ${settings.leagueCount}ブロック');
    } else {
      sb.writeln('・参加人数: ${settings.participantCount}名');
    }
    sb.writeln('・コート数: ${settings.courtCount}面');
    sb.writeln('・配分モード: ${settings.pattern.title}');
    sb.writeln(
      '・試合時間: ${settings.matchDurationFormatted} (インターバル: ${settings.intervalDurationFormatted})',
    );
    sb.writeln('・総試合数: ${result.totalMatches}試合');
    sb.writeln('・総所要時間: 約${result.totalEstimatedMinutes}分');
    sb.writeln('・終了予定時刻: ${timeFmt.format(result.estimatedEndTime)}頃');
    sb.writeln('');

    for (int c = 1; c <= settings.courtCount; c++) {
      final list = result.courtMatches[c] ?? [];
      final count = list.length;
      final endTimeStr = list.isNotEmpty
          ? timeFmt.format(list.last.estimatedEnd)
          : '--:--';
      sb.writeln('■ 第$cコート ($count試合 / 終了予定 $endTimeStr)');
      for (final m in list) {
        final start = timeFmt.format(m.estimatedStart);
        final end = timeFmt.format(m.estimatedEnd);
        sb.writeln(
          '  [第${m.matchOrder}試合 $start~$end] ${m.categoryName} ${m.matchTitle} (${m.pairDescription})',
        );
      }
      sb.writeln('');
    }

    return sb.toString().trim();
  }
}
