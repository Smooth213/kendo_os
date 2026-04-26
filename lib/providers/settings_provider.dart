import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/settings_model.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/sound_service.dart'; // ★ 追加：設定変更時に音響エンジンを更新するため

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
    SettingsModel initialSettings = const SettingsModel(showConfirmDialog: false);
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

  // 特定の項目だけを更新するヘルパーメソッド
  // ★ Phase 3: themeMode を受け取れるように引数を追加
  void updateField({
    String? confirmBehavior,
    bool? isLocked,
    bool? haptic,
    bool? strikeVib,
    bool? sound,
    bool? ignoreMannerMode, // ★ 追加
    bool? sleepPrevent,
    bool? leftHanded,
    bool? showConfirmDialog, // ★ 追加
    String? themeMode,
    int? securityLevel, // ★ Phase 8: 1(自由), 2(標準), 3(厳格)
    String? adminPasscode, // ★ Phase 8: 英数8文字
  }) {
    updateSettings(state.copyWith(
      confirmBehavior: confirmBehavior ?? state.confirmBehavior,
      isLocked: isLocked ?? state.isLocked,
      haptic: haptic ?? state.haptic,
      strikeVib: strikeVib ?? state.strikeVib,
      sound: sound ?? state.sound,
      ignoreMannerMode: ignoreMannerMode ?? state.ignoreMannerMode, // ★ 追加
      sleepPrevent: sleepPrevent ?? state.sleepPrevent,
      leftHanded: leftHanded ?? state.leftHanded,
      showConfirmDialog: showConfirmDialog ?? state.showConfirmDialog, // ★ 追加
      themeMode: themeMode ?? state.themeMode,
      securityLevel: securityLevel ?? state.securityLevel,
      adminPasscode: adminPasscode ?? state.adminPasscode,
    ));
  }

  // 一括設定（プリセット）を適用する
  void applyPreset(String presetName) {
    if (presetName == 'official') {
      // 🏆 公式大会モード：絶対にミスが許されないためダイアログはON
      updateSettings(const SettingsModel(
        confirmBehavior: 'long', isLocked: true, showConfirmDialog: true, 
        haptic: true, strikeVib: true, sound: true, ignoreMannerMode: true, // ★ 追加
        sleepPrevent: true, leftHanded: false, themeMode: 'system',
        securityLevel: 2, // 🏆 公式はデフォルトで「標準」ガード
      ));
    } else if (presetName == 'renseikai') {
      // 🤺 試合・錬成会モード（アプリのデフォルト）：テンポ重視
      updateSettings(const SettingsModel(
        confirmBehavior: 'double', isLocked: false, showConfirmDialog: false, 
        haptic: true, strikeVib: true, sound: false, ignoreMannerMode: true, // ★ 追加
        sleepPrevent: true, leftHanded: false, themeMode: 'system',
        securityLevel: 1,
      ));
    } else if (presetName == 'practice') {
      // 🏠 練習・道場モード：極限までテンポと静かさを重視
      updateSettings(const SettingsModel(
        confirmBehavior: 'single', isLocked: false, showConfirmDialog: false, 
        haptic: false, strikeVib: false, sound: false, ignoreMannerMode: false, // ★ 追加
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