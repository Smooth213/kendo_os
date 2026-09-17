import 'package:flutter/material.dart';

/// 🥋 試合形式タイプ
enum MatchFormatType {
  singleLeague, // 1リーグ総当たり
  multiLeague, // 複数リーグ総当たり
  tournament, // トーナメント戦
  prelimLeagueAndTournament, // 予選リーグ＋決勝トーナメント
}

extension MatchFormatTypeExtension on MatchFormatType {
  String get label {
    switch (this) {
      case MatchFormatType.singleLeague:
        return '1リーグ総当たり';
      case MatchFormatType.multiLeague:
        return '複数リーグ総当たり';
      case MatchFormatType.tournament:
        return 'トーナメント';
      case MatchFormatType.prelimLeagueAndTournament:
        return '予選L＋決勝T';
    }
  }

  IconData get icon {
    switch (this) {
      case MatchFormatType.singleLeague:
        return Icons.grid_view_rounded;
      case MatchFormatType.multiLeague:
        return Icons.grid_on_rounded;
      case MatchFormatType.tournament:
        return Icons.account_tree_rounded;
      case MatchFormatType.prelimLeagueAndTournament:
        return Icons.emoji_events_rounded;
    }
  }
}

/// 🥋 コート割り振りパターン
enum AllocationPattern {
  patternA, // インターバル優先・交互
  patternB, // コート均等負荷バランス
  patternC, // ブロック専任進行
  minimalMovement, // コート移動少ないモード
}

extension AllocationPatternExtension on AllocationPattern {
  String get title {
    switch (this) {
      case AllocationPattern.patternA:
        return 'パターンA (インターバル優先)';
      case AllocationPattern.patternB:
        return 'パターンB (コート均等負荷)';
      case AllocationPattern.patternC:
        return 'パターンC (ブロック専任)';
      case AllocationPattern.minimalMovement:
        return 'コート移動最少モード';
    }
  }

  String get shortTitle {
    switch (this) {
      case AllocationPattern.patternA:
        return 'インターバル優先';
      case AllocationPattern.patternB:
        return '均等負荷';
      case AllocationPattern.patternC:
        return 'ブロック専任';
      case AllocationPattern.minimalMovement:
        return '移動最少';
    }
  }

  String get description {
    switch (this) {
      case AllocationPattern.patternA:
        return 'リーグ間・対戦カードを交互に進行し、選手の連続試合を防止します。';
      case AllocationPattern.patternB:
        return '全コートの試合数を均等に分配し、各コートの終了時刻を揃えます。';
      case AllocationPattern.patternC:
        return '第1コート＝Aリーグ、第2コート＝Bリーグのようにコートをブロック専任にします。';
      case AllocationPattern.minimalMovement:
        return '選手・審判のコート移動を最小化し、コート内で間隔を空けて進行します。';
    }
  }

  IconData get icon {
    switch (this) {
      case AllocationPattern.patternA:
        return Icons.swap_calls_rounded;
      case AllocationPattern.patternB:
        return Icons.balance_rounded;
      case AllocationPattern.patternC:
        return Icons.view_column_rounded;
      case AllocationPattern.minimalMovement:
        return Icons.pin_drop_rounded;
    }
  }
}

/// 🥋 計算機設定
@immutable
class CalculatorSettings {
  final MatchFormatType format;
  final AllocationPattern pattern;
  final int participantCount;
  final int leagueCount;
  final int courtCount;
  final bool hasThirdPlaceMatch;
  final int advancingCountPerLeague;
  final double matchDurationMinutes;
  final double intervalDurationMinutes;
  final TimeOfDay startTime;
  final List<int>? customLeagueParticipants;
  final bool useCustomLeagueMatchDurations;
  final List<double>? customLeagueMatchDurations;
  final double? customTournamentMatchDuration;

  const CalculatorSettings({
    this.format = MatchFormatType.multiLeague,
    this.pattern = AllocationPattern.patternA,
    this.participantCount = 8,
    this.leagueCount = 2,
    this.courtCount = 2,
    this.hasThirdPlaceMatch = true,
    this.advancingCountPerLeague = 2,
    this.matchDurationMinutes = 2.0,
    this.intervalDurationMinutes = 1.0,
    this.startTime = const TimeOfDay(hour: 9, minute: 0),
    this.customLeagueParticipants,
    this.useCustomLeagueMatchDurations = false,
    this.customLeagueMatchDurations,
    this.customTournamentMatchDuration,
  });

  /// リーグごとの人数リスト（未設定の場合は均等配分）
  List<int> get leagueParticipantCounts {
    if (customLeagueParticipants != null &&
        customLeagueParticipants!.length == leagueCount) {
      return customLeagueParticipants!;
    }
    final count = leagueCount.clamp(1, 8);
    final baseCount = participantCount ~/ count;
    final remainder = participantCount % count;
    return List.generate(
      count,
      (i) => (baseCount + (i < remainder ? 1 : 0)).clamp(2, 999),
    );
  }

  /// リーグごとの試合時間（個別設定が無効または未設定の場合は共通デフォルト値）
  double getLeagueMatchDuration(int leagueIndex) {
    if (useCustomLeagueMatchDurations &&
        customLeagueMatchDurations != null &&
        leagueIndex < customLeagueMatchDurations!.length) {
      return customLeagueMatchDurations![leagueIndex];
    }
    return matchDurationMinutes;
  }

  /// 決勝トーナメントの試合時間
  double get tournamentMatchDuration =>
      (useCustomLeagueMatchDurations && customTournamentMatchDuration != null)
      ? customTournamentMatchDuration!
      : matchDurationMinutes;

  /// 実際の有効参加人数（複数リーグの場合はリーグ別合計）
  int get effectiveParticipantCount {
    if (format == MatchFormatType.multiLeague ||
        format == MatchFormatType.prelimLeagueAndTournament) {
      return leagueParticipantCounts.fold<int>(0, (sum, c) => sum + c);
    }
    return participantCount;
  }

  double get slotDurationMinutes =>
      matchDurationMinutes + intervalDurationMinutes;

  static String formatMinutes(double minutes) {
    if (minutes <= 0) return '0分';
    final mins = minutes.floor();
    final secs = ((minutes - mins) * 60).round();
    if (mins == 0) return '$secs秒';
    if (secs == 0) return '$mins分';
    return '$mins分$secs秒';
  }

  String get matchDurationFormatted => formatMinutes(matchDurationMinutes);
  String get intervalDurationFormatted =>
      formatMinutes(intervalDurationMinutes);
  String get slotDurationFormatted => formatMinutes(slotDurationMinutes);

  CalculatorSettings copyWith({
    MatchFormatType? format,
    AllocationPattern? pattern,
    int? participantCount,
    int? leagueCount,
    int? courtCount,
    bool? hasThirdPlaceMatch,
    int? advancingCountPerLeague,
    double? matchDurationMinutes,
    double? intervalDurationMinutes,
    TimeOfDay? startTime,
    List<int>? customLeagueParticipants,
    bool? useCustomLeagueMatchDurations,
    List<double>? customLeagueMatchDurations,
    double? customTournamentMatchDuration,
  }) {
    return CalculatorSettings(
      format: format ?? this.format,
      pattern: pattern ?? this.pattern,
      participantCount: participantCount ?? this.participantCount,
      leagueCount: leagueCount ?? this.leagueCount,
      courtCount: courtCount ?? this.courtCount,
      hasThirdPlaceMatch: hasThirdPlaceMatch ?? this.hasThirdPlaceMatch,
      advancingCountPerLeague:
          advancingCountPerLeague ?? this.advancingCountPerLeague,
      matchDurationMinutes: matchDurationMinutes ?? this.matchDurationMinutes,
      intervalDurationMinutes:
          intervalDurationMinutes ?? this.intervalDurationMinutes,
      startTime: startTime ?? this.startTime,
      customLeagueParticipants:
          customLeagueParticipants ?? this.customLeagueParticipants,
      useCustomLeagueMatchDurations:
          useCustomLeagueMatchDurations ?? this.useCustomLeagueMatchDurations,
      customLeagueMatchDurations:
          customLeagueMatchDurations ?? this.customLeagueMatchDurations,
      customTournamentMatchDuration:
          customTournamentMatchDuration ?? this.customTournamentMatchDuration,
    );
  }
}

/// 🥋 コートに割り振られた1試合情報
@immutable
class AllocatedMatch {
  final int courtNumber; // 1-indexed (例: 1コート, 2コート)
  final int matchOrder; // コート内試合順 (1, 2, 3...)
  final String categoryName; // "Aリーグ", "Bリーグ", "決勝T", "トーナメント" 等
  final String matchTitle; // "第1試合", "準決勝第1試合" 等
  final String pairDescription; // "選手1 vs 選手2" 等
  final double durationMinutes; // その試合の試合時間（分）
  final DateTime estimatedStart;
  final DateTime estimatedEnd;

  const AllocatedMatch({
    required this.courtNumber,
    required this.matchOrder,
    required this.categoryName,
    required this.matchTitle,
    required this.pairDescription,
    this.durationMinutes = 2.0,
    required this.estimatedStart,
    required this.estimatedEnd,
  });
}

/// 🥋 割り振りシミュレーション計算結果
@immutable
class AllocationResult {
  final int totalMatches;
  final Map<int, List<AllocatedMatch>>
  courtMatches; // courtNumber -> List<AllocatedMatch>
  final int maxCourtMatches;
  final int totalEstimatedMinutes;
  final DateTime estimatedEndTime;
  final Map<String, int> matchesPerCategory;

  const AllocationResult({
    required this.totalMatches,
    required this.courtMatches,
    required this.maxCourtMatches,
    required this.totalEstimatedMinutes,
    required this.estimatedEndTime,
    required this.matchesPerCategory,
  });

  int getCourtMatchCount(int courtNumber) =>
      courtMatches[courtNumber]?.length ?? 0;

  DateTime? getCourtEndTime(int courtNumber) {
    final list = courtMatches[courtNumber];
    if (list == null || list.isEmpty) return null;
    return list.last.estimatedEnd;
  }
}
