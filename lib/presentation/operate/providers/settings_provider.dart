import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:kendo_os/domain/entities/settings_model.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:kendo_os/application/services/sound_service.dart'; // ★ 追加：設定変更時に音響エンジンを更新するため

// SharedPreferencesのインスタンスを非同期で提供するProvider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('main.dartで上書き(override)する必要があります');
});

// 設定を管理するNotifier
class SettingsNotifier extends Notifier<SettingsModel> {
  static const _key = 'kendo_sync_settings';

  @override
  SettingsModel build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonString = prefs.getString(_key);
    
    // ★ 修正：アプリ初回起動時の「初期状態」を明示的に指定し、確認ダイアログをデフォルトOFF(false)にする
    SettingsModel initialSettings = SettingsModel(showConfirmDialog: false);
    if (jsonString != null) {
      try {
        initialSettings = SettingsModel.fromJson(jsonDecode(jsonString));
      } catch (e) {
        // パース失敗時はデフォルト値
      }
    }
    
    // 初期化時にスリープ防止設定を適用
    _applyWakelock(initialSettings.sleepPrevent);
    
    return initialSettings;
  }

  // 設定を更新して保存する
  Future<void> updateSettings(SettingsModel newSettings) async {
    state = newSettings;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, jsonEncode(newSettings.toJson()));
    
    // スリープ防止設定が変更されたら即座に適用
    _applyWakelock(newSettings.sleepPrevent);
    
    // ★ 追加：マナーモード設定が変更されたら、即座にオーディオエンジンを書き換える
    ref.read(soundServiceProvider).configureAudio(newSettings.ignoreMannerMode);
  }

  // 設定を更新し、かつ重要な変更（セキュリティ等）は監査ログに記録する
  Future<void> updateField({
    String? confirmBehavior,
    bool? isLocked,
    bool? haptic,
    bool? strikeVib,
    String? audioFeedbackMode, // ★ 変更
    bool? ignoreMannerMode,
    bool? sleepPrevent,
    bool? leftHanded,
    bool? showConfirmDialog,
    String? themeMode,
    bool? experimentalFeatures, // ★ 修正: この1行を引数に追加
    int? securityLevel,
    String? adminPasscode,
  }) async {
    final oldState = state;
    final newState = state.copyWith(
      confirmBehavior: confirmBehavior ?? state.confirmBehavior,
      isLocked: isLocked ?? state.isLocked,
      haptic: haptic ?? state.haptic,
      strikeVib: strikeVib ?? state.strikeVib,
      audioFeedbackMode: audioFeedbackMode ?? state.audioFeedbackMode,
      ignoreMannerMode: ignoreMannerMode ?? state.ignoreMannerMode,
      sleepPrevent: sleepPrevent ?? state.sleepPrevent,
      leftHanded: leftHanded ?? state.leftHanded,
      showConfirmDialog: showConfirmDialog ?? state.showConfirmDialog,
      themeMode: themeMode ?? state.themeMode,
      experimentalFeatures: experimentalFeatures ?? state.experimentalFeatures, // ★ 修正: この1行を代入に追加
      securityLevel: securityLevel ?? state.securityLevel,
      adminPasscode: adminPasscode ?? state.adminPasscode,
    );

    await updateSettings(newState);

    // ==========================================
    // ★ Phase 1: 重要な設定変更の監査ログ記録
    // ==========================================
    if (securityLevel != null && securityLevel != oldState.securityLevel) {
      _logSystemChange(
        'セキュリティレベル変更', 
        'Lv.${oldState.securityLevel} -> Lv.$securityLevel'
      );
    }
    if (adminPasscode != null && adminPasscode != oldState.adminPasscode) {
      _logSystemChange('管理者パスコード変更', 'パスコードが更新されました');
    }
  }

  // 内部ヘルパー：監査ログの発行
  void _logSystemChange(String action, String detail) {
    try {
      // 既存の auditLogProvider を利用して記録
      // ※ audit_provider.dart が AuditLog(action: action, details: detail) を
      //Firestoreへ送るメソッドを持っている前提
      // ref.read(auditProvider.notifier).addLog(action, detail); 
      debugPrint('📝 [AuditLog] $action: $detail'); // デバッグ用
    } catch (e) {
      debugPrint('🔥 AuditLog recording failed: $e');
    }
  }

  // 一括設定（プリセット）を適用する
  void applyPreset(String presetName) {
    if (presetName == 'official') {
      updateSettings(const SettingsModel(
        confirmBehavior: 'long', isLocked: true, showConfirmDialog: true, 
        haptic: true, strikeVib: true, audioFeedbackMode: 'effect', ignoreMannerMode: true,
        sleepPrevent: true, leftHanded: false, themeMode: 'system',
        securityLevel: 2,
      ));
    } else if (presetName == 'renseikai') {
      updateSettings(const SettingsModel(
        confirmBehavior: 'double', isLocked: false, showConfirmDialog: false, 
        haptic: true, strikeVib: true, audioFeedbackMode: 'off', ignoreMannerMode: true,
        sleepPrevent: true, leftHanded: false, themeMode: 'system',
        securityLevel: 1,
      ));
    } else if (presetName == 'practice') {
      updateSettings(const SettingsModel(
        confirmBehavior: 'single', isLocked: false, showConfirmDialog: false, 
        haptic: false, strikeVib: false, audioFeedbackMode: 'off', ignoreMannerMode: false,
        sleepPrevent: true, leftHanded: false, themeMode: 'system',
        securityLevel: 1,
      ));
    }
  }

  void _applyWakelock(bool enable) {
    if (enable) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsModel>(() {
  return SettingsNotifier();
});