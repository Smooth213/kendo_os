import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_model.freezed.dart';
part 'settings_model.g.dart';

@freezed
abstract class SettingsModel with _$SettingsModel {
  const factory SettingsModel({
    // 【操作・安全設定】
    // ★ アプリの初期状態を「大会・錬成会」プリセットに完全統一
    @Default('double') String confirmBehavior, 
    @Default(false) bool isLocked,            
    @Default(false) bool showConfirmDialog, // ★ 変更：初期値をOFF（ダイアログなし）に統一
    
    // 【フィードバック】
    @Default(true) bool haptic,              
    @Default(true) bool strikeVib,           
    @Default(false) bool sound, // ★ 錬成会モードに合わせて初期値はオフ
    @Default(true) bool ignoreMannerMode, // ★ 追加：マナーモード時も強制的に音を鳴らす（初期値ON）
    
    // 【システム・表示】
    @Default(true) bool sleepPrevent,        // スリープ(画面消灯)防止
    @Default(false) bool leftHanded,         // 左利きモード（赤白反転）
    @Default('system') String themeMode,     // ★ ダークモード対応 ('system', 'light', 'dark')
    
    // 【セキュリティ・権限】 (Phase 8)
    @Default(1) int securityLevel, // ★ Phase 8: 1(自由), 2(標準), 3(厳格)
    String? adminPasscode,        // ★ Phase 8: 英数8文字パスコード
  }) = _SettingsModel;

  factory SettingsModel.fromJson(Map<String, dynamic> json) => _$SettingsModelFromJson(json);
}