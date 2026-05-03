import 'package:freezed_annotation/freezed_annotation.dart';

part 'organization.freezed.dart';
part 'organization.g.dart';

@freezed
abstract class Organization with _$Organization {
  const factory Organization({
    required String id,
    required String name,
    @Default([]) List<String> memberNames, // シンプルに名前のリストで管理
  }) = _Organization;

  factory Organization.fromJson(Map<String, dynamic> json) => _$OrganizationFromJson(json);
}
@freezed
abstract class TeamTemplate with _$TeamTemplate {
  const factory TeamTemplate({
    required String id,
    required String name, // 例：「Aチーム」「中学男子部」
    @Default([]) List<String> orderedMemberNames, // 先鋒, 次鋒...の順に名前を格納
  }) = _TeamTemplate;

  factory TeamTemplate.fromJson(Map<String, dynamic> json) => _$TeamTemplateFromJson(json);
}