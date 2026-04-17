import 'package:freezed_annotation/freezed_annotation.dart';

part 'team_model.freezed.dart';
part 'team_model.g.dart';

@freezed
abstract class TeamModel with _$TeamModel {
  const factory TeamModel({
    required String id,
    required String tournamentId,
    required String category, 
    required String teamName, 
    @Default('団体戦（5人制）') String matchType, // ★ 追加：試合形式
    @Default([]) List<String> playerNames, 
  }) = _TeamModel;

  factory TeamModel.fromJson(Map<String, dynamic> json) => _$TeamModelFromJson(json);
}