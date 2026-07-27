import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kendo_os/shared/infrastructure/persistence/converters/json_converters.dart'; // ★ コンバーターを読み込む
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';

part 'tournament_model.freezed.dart';
part 'tournament_model.g.dart';

@freezed
abstract class TournamentModel with _$TournamentModel {
  const factory TournamentModel({
    required String id,

    /// ★ 新・同期空間統治キー：この大会がどの道場/所属に帰属するかを指し示す最上位キー
    required String organizationId,
    required String name,
    @TimestampConverter() required DateTime date,
    required String venue,
    @Default([]) List<String> categories,
    @Default('active') String status,
    @Default('') String notes,
    // ★ Phase 8: バックエンド防弾化用のセキュリティレベル（初期値2: 標準）
    @Default(2) int securityLevel,
    @Default({}) Map<String, CategoryRuleSet> categoryRules,
  }) = _TournamentModel;

  factory TournamentModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentModelFromJson(json);
}
