import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_meta.freezed.dart';
part 'match_meta.g.dart';

// ==========================================
// ★ ② Meta分離：表示や大会進行のための付帯情報
// ==========================================
@freezed
abstract class MatchMeta with _$MatchMeta {
  const MatchMeta._();

  const factory MatchMeta({
    required String matchType,
    required String redName,
    required String whiteName,
    @Default('') String note,
    String? tournamentId,
    String? category,
    String? groupName,
    int? matchOrder,
    @Default([]) List<String> refereeNames,
    @Default(false) bool countForStandings,
    @Default(false) bool isAutoAssigned,
  }) = _MatchMeta;

  factory MatchMeta.fromJson(Map<String, dynamic> json) => _$MatchMetaFromJson(json);
}