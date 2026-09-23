import 'package:flutter/foundation.dart';

/// 取り込まれた選手情報
@immutable
class ParsedTeamMember {
  final String position; // 先鋒, 次鋒, 中堅, 副将, 大将, 補欠 等
  final String name; // 選手氏名（記号クレンジング済み）

  const ParsedTeamMember({required this.position, required this.name});

  Map<String, dynamic> toMap() => {'position': position, 'name': name};

  factory ParsedTeamMember.fromMap(Map<String, dynamic> map) {
    return ParsedTeamMember(
      position: map['position'] as String? ?? '',
      name: map['name'] as String? ?? '',
    );
  }

  ParsedTeamMember copyWith({String? position, String? name}) {
    return ParsedTeamMember(
      position: position ?? this.position,
      name: name ?? this.name,
    );
  }
}

/// 取り込まれたチーム＆オーダー情報
@immutable
class ParsedTeamOrder {
  final String teamName; // 例: 〇〇剣友会, 低学年, 中学生A
  final String category; // 例: 小学生低学年の部, 中学生の部, 一般の部
  final String matchType; // 例: 団体戦（5人制）, 勝ち抜き戦, リーグ団体戦 等
  final List<ParsedTeamMember> members;

  const ParsedTeamOrder({
    required this.teamName,
    this.category = '',
    this.matchType = '',
    required this.members,
  });

  Map<String, dynamic> toMap() => {
    'teamName': teamName,
    'category': category,
    'matchType': matchType,
    'members': members.map((m) => m.toMap()).toList(),
  };

  factory ParsedTeamOrder.fromMap(Map<String, dynamic> map) {
    return ParsedTeamOrder(
      teamName: map['teamName'] as String? ?? '',
      category: map['category'] as String? ?? '',
      matchType: map['matchType'] as String? ?? '',
      members: (map['members'] as List<dynamic>? ?? [])
          .map((m) => ParsedTeamMember.fromMap(m as Map<String, dynamic>))
          .toList(),
    );
  }

  ParsedTeamOrder copyWith({
    String? teamName,
    String? category,
    String? matchType,
    List<ParsedTeamMember>? members,
  }) {
    return ParsedTeamOrder(
      teamName: teamName ?? this.teamName,
      category: category ?? this.category,
      matchType: matchType ?? this.matchType,
      members: members ?? this.members,
    );
  }
}

/// 外部アプリ等から取り込まれた大会情報構造体
@immutable
class TournamentShareData {
  final String tournamentName;
  final DateTime? date;
  final String venue;
  final String address;
  final String notes;
  final List<ParsedTeamOrder> teams;
  final String rawText;

  const TournamentShareData({
    required this.tournamentName,
    this.date,
    this.venue = '',
    this.address = '',
    this.notes = '',
    this.teams = const [],
    this.rawText = '',
  });

  bool get hasTeams => teams.isNotEmpty;
  int get totalPlayerCount =>
      teams.fold(0, (sum, team) => sum + team.members.length);

  /// 大会名・開催日・会場・チームオーダー等の有効な大会情報が含まれているか
  bool get hasEffectiveContent =>
      tournamentName.isNotEmpty ||
      date != null ||
      venue.isNotEmpty ||
      teams.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'tournamentName': tournamentName,
    'date': date?.toIso8601String(),
    'venue': venue,
    'address': address,
    'notes': notes,
    'teams': teams.map((t) => t.toMap()).toList(),
    'rawText': rawText,
  };

  factory TournamentShareData.fromMap(Map<String, dynamic> map) {
    return TournamentShareData(
      tournamentName: map['tournamentName'] as String? ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String)
          : null,
      venue: map['venue'] as String? ?? '',
      address: map['address'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      teams: (map['teams'] as List<dynamic>? ?? [])
          .map((t) => ParsedTeamOrder.fromMap(t as Map<String, dynamic>))
          .toList(),
      rawText: map['rawText'] as String? ?? '',
    );
  }

  TournamentShareData copyWith({
    String? tournamentName,
    DateTime? date,
    String? venue,
    String? address,
    String? notes,
    List<ParsedTeamOrder>? teams,
    String? rawText,
  }) {
    return TournamentShareData(
      tournamentName: tournamentName ?? this.tournamentName,
      date: date ?? this.date,
      venue: venue ?? this.venue,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      teams: teams ?? this.teams,
      rawText: rawText ?? this.rawText,
    );
  }
}
