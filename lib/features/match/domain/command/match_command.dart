import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_command.freezed.dart';
part 'match_command.g.dart';

/// [MatchCommand] represents an immutable write request in the CQRS architecture.
/// Every state mutation intent for a Kendo match must be encapsulated as a command
/// to enforce zero-trust operator validation and prevent replay drifting.
@freezed
abstract class MatchCommand with _$MatchCommand {
  const factory MatchCommand({
    required String id,
    required String matchId,
    required String commandType,
    required Map<String, dynamic> payload,
    required String operatorId,
    required DateTime createdAt,
  }) = _MatchCommand;

  factory MatchCommand.fromJson(Map<String, dynamic> json) =>
      _$MatchCommandFromJson(json);
}
