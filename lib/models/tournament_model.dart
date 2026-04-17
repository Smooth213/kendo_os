import 'package:freezed_annotation/freezed_annotation.dart';
import 'json_converters.dart'; // ★ コンバーターを読み込む

part 'tournament_model.freezed.dart';
part 'tournament_model.g.dart';

@freezed
abstract class TournamentModel with _$TournamentModel {
  const factory TournamentModel({
    required String id,
    required String name,
    @TimestampConverter() required DateTime date, // ★ これで日付エラーが永遠に起きなくなる！
    required String venue,
    @Default([]) List<String> categories,
    @Default('active') String status, // ★ エラーログにあったstatusを維持
    @Default('') String notes,        // ★ notesを追加
  }) = _TournamentModel;

  factory TournamentModel.fromJson(Map<String, dynamic> json) => _$TournamentModelFromJson(json);
}