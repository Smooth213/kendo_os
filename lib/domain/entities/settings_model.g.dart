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
      audioFeedbackMode: json['audioFeedbackMode'] as String? ?? 'off',
      ignoreMannerMode: json['ignoreMannerMode'] as bool? ?? true,
      sleepPrevent: json['sleepPrevent'] as bool? ?? true,
      leftHanded: json['leftHanded'] as bool? ?? false,
      themeMode: json['themeMode'] as String? ?? 'system',
      enableLiquidGlass: json['enableLiquidGlass'] as bool? ?? true,
      experimentalFeatures: json['experimentalFeatures'] as bool? ?? false,
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
      'audioFeedbackMode': instance.audioFeedbackMode,
      'ignoreMannerMode': instance.ignoreMannerMode,
      'sleepPrevent': instance.sleepPrevent,
      'leftHanded': instance.leftHanded,
      'themeMode': instance.themeMode,
      'enableLiquidGlass': instance.enableLiquidGlass,
      'experimentalFeatures': instance.experimentalFeatures,
      'securityLevel': instance.securityLevel,
      'adminPasscode': instance.adminPasscode,
    };
