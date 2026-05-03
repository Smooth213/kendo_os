import 'package:freezed_annotation/freezed_annotation.dart';
import '../../infrastructure/persistence/converters/json_converters.dart'; // ★ コンバーターを読み込む

part 'tournament_model.freezed.dart';
part 'tournament_model.g.dart';

@freezed
abstract class TournamentModel with _$TournamentModel {
  const factory TournamentModel({
    required String id,
    required String name,
    @TimestampConverter() required DateTime date, 
    required String venue,
    @Default([]) List<String> categories,
    @Default('active') String status, 
    @Default('') String notes,        
    // ★ Phase 8: バックエンド防弾化用のセキュリティレベル（初期値2: 標準）
    @Default(2) int securityLevel,
  }) = _TournamentModel;

  factory TournamentModel.fromJson(Map<String, dynamic> json) => _$TournamentModelFromJson(json);
}