// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SettingsModel _$SettingsModelFromJson(Map<String, dynamic> json) =>
    _SettingsModel(
      confirmBehavior: json['confirmBehavior'] as String? ?? 'double',
      isLocked: json['isLocked'] as bool? ?? false,
      showConfirmDialog: json['showConfirmDialog'] as bool? ?? false,
      haptic: json['haptic'] as bool? ?? true,
      strikeVib: json['strikeVib'] as bool? ?? true,
      sound: json['sound'] as bool? ?? false,
      sleepPrevent: json['sleepPrevent'] as bool? ?? true,
      leftHanded: json['leftHanded'] as bool? ?? false,
      themeMode: json['themeMode'] as String? ?? 'system',
      securityLevel: (json['securityLevel'] as num?)?.toInt() ?? 1,
      adminPasscode: json['adminPasscode'] as String?,
    );

Map<String, dynamic> _$SettingsModelToJson(_SettingsModel instance) =>
    <String, dynamic>{
      'confirmBehavior': instance.confirmBehavior,
      'isLocked': instance.isLocked,
      'showConfirmDialog': instance.showConfirmDialog,
      'haptic': instance.haptic,
      'strikeVib': instance.strikeVib,
      'sound': instance.sound,
      'sleepPrevent': instance.sleepPrevent,
      'leftHanded': instance.leftHanded,
      'themeMode': instance.themeMode,
      'securityLevel': instance.securityLevel,
      'adminPasscode': instance.adminPasscode,
    };
