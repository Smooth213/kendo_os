import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_settings.freezed.dart';
part 'event_settings.g.dart';

enum MatchFormat { individual, team }

@freezed
abstract class EventSettings with _$EventSettings {
  const factory EventSettings({
    @Default('test_event_v2') String id,
    @Default('新規大会') String name,
    @Default(MatchFormat.individual) MatchFormat defaultFormat,
    @Default(180) int defaultDurationSeconds,
  }) = _EventSettings;

  factory EventSettings.fromJson(Map<String, dynamic> json) => _$EventSettingsFromJson(json);
}