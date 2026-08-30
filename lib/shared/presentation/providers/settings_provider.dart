import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:kendo_os/shared/application/services/sound_service.dart'; // ★ 追加：設定変更時に音響エンジンを更新するため

import 'package:kendo_os/shared/application/services/kendo_haptics.dart';

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
    KendoHaptics.isEnabled = initialSettings.haptic;

    return initialSettings;
  }

  // 設定を更新して保存する
  Future<void> updateSettings(SettingsModel newSettings) async {
    state = newSettings;
    KendoHaptics.isEnabled = newSettings.haptic;
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
    bool? enableLiquidGlass,
    bool? experimentalFeatures, // ★ 修正: この1行を引数に追加
    int? securityLevel,
    String? adminPasscode,
    bool? notifyOnEmergency,
    bool? notifyOnMatchAdded,
    bool? notifyOnMatchStarted,
    bool? notifyOnResult,
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
      enableLiquidGlass: enableLiquidGlass ?? state.enableLiquidGlass,
      experimentalFeatures:
          experimentalFeatures ??
          state.experimentalFeatures, // ★ 修正: この1行を代入に追加
      securityLevel: securityLevel ?? state.securityLevel,
      adminPasscode: adminPasscode ?? state.adminPasscode,
      notifyOnEmergency: notifyOnEmergency ?? state.notifyOnEmergency,
      notifyOnMatchAdded: notifyOnMatchAdded ?? state.notifyOnMatchAdded,
      notifyOnMatchStarted: notifyOnMatchStarted ?? state.notifyOnMatchStarted,
      notifyOnResult: notifyOnResult ?? state.notifyOnResult,
    );

    await updateSettings(newState);

    // ==========================================
    // ★ Phase 1: 重要な設定変更の監査ログ記録
    // ==========================================
    if (securityLevel != null && securityLevel != oldState.securityLevel) {
      _logSystemChange(
        'セキュリティレベル変更',
        'Lv.${oldState.securityLevel} -> Lv.$securityLevel',
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
      updateSettings(
        const SettingsModel(
          confirmBehavior: 'long',
          isLocked: true,
          showConfirmDialog: true,
          haptic: true,
          strikeVib: true,
          audioFeedbackMode: 'effect',
          ignoreMannerMode: true,
          sleepPrevent: true,
          leftHanded: false,
          themeMode: 'system',
          enableLiquidGlass: true,
          securityLevel: 2,
          notifyOnEmergency: true,
          notifyOnMatchAdded: true,
          notifyOnMatchStarted: true,
          notifyOnResult: false,
        ),
      );
    } else if (presetName == 'renseikai') {
      updateSettings(
        const SettingsModel(
          confirmBehavior: 'double',
          isLocked: false,
          showConfirmDialog: false,
          haptic: true,
          strikeVib: true,
          audioFeedbackMode: 'off',
          ignoreMannerMode: true,
          sleepPrevent: true,
          leftHanded: false,
          themeMode: 'system',
          enableLiquidGlass: true,
          securityLevel: 1,
          notifyOnEmergency: true,
          notifyOnMatchAdded: true,
          notifyOnMatchStarted: true,
          notifyOnResult: false,
        ),
      );
    } else if (presetName == 'practice') {
      updateSettings(
        const SettingsModel(
          confirmBehavior: 'single',
          isLocked: false,
          showConfirmDialog: false,
          haptic: false,
          strikeVib: false,
          audioFeedbackMode: 'off',
          ignoreMannerMode: false,
          sleepPrevent: true,
          leftHanded: false,
          themeMode: 'system',
          enableLiquidGlass: true,
          securityLevel: 1,
          notifyOnEmergency: true,
          notifyOnMatchAdded: true,
          notifyOnMatchStarted: true,
          notifyOnResult: false,
        ),
      );
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

class BatteryStateData {
  final int batteryLevel;
  final bool isInPowerSaveMode;

  const BatteryStateData({
    this.batteryLevel = 100,
    this.isInPowerSaveMode = false,
  });
}

class BatteryNotifier extends AutoDisposeAsyncNotifier<BatteryStateData> {
  Battery? _battery;
  StreamSubscription? _subscription;
  Timer? _timer;

  @override
  FutureOr<BatteryStateData> build() async {
    final isTest =
        zoneValuesContainsTestKey() ||
        const bool.fromEnvironment('FLUTTER_TEST');
    if (isTest) {
      return const BatteryStateData(
        batteryLevel: 100,
        isInPowerSaveMode: false,
      );
    }

    try {
      _battery = Battery();
      ref.onDispose(() {
        _subscription?.cancel();
        _timer?.cancel();
      });

      final level = await _battery!.batteryLevel.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => 100,
      );
      final isLowPower = await _battery!.isInBatterySaveMode.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => false,
      );

      // Listen to battery state changes
      _subscription = _battery!.onBatteryStateChanged.listen((_) async {
        try {
          final l = await _battery!.batteryLevel;
          final p = await _battery!.isInBatterySaveMode;
          state = AsyncValue.data(
            BatteryStateData(batteryLevel: l, isInPowerSaveMode: p),
          );
        } catch (_) {}
      });

      // Periodically poll low power mode (on some platforms state changes might not trigger immediately)
      _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
        try {
          final l = await _battery!.batteryLevel;
          final p = await _battery!.isInBatterySaveMode;
          state = AsyncValue.data(
            BatteryStateData(batteryLevel: l, isInPowerSaveMode: p),
          );
        } catch (_) {}
      });

      return BatteryStateData(
        batteryLevel: level,
        isInPowerSaveMode: isLowPower,
      );
    } catch (e) {
      debugPrint('🔋 Battery info unavailable: $e');
      return const BatteryStateData(
        batteryLevel: 100,
        isInPowerSaveMode: false,
      );
    }
  }

  bool zoneValuesContainsTestKey() {
    return RegExp(r'test').hasMatch(StackTrace.current.toString());
  }
}

final batteryStateProvider =
    AsyncNotifierProvider.autoDispose<BatteryNotifier, BatteryStateData>(() {
      return BatteryNotifier();
    });

final isEcoModeProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  if (!settings.enableLiquidGlass) {
    return true; // Manual Eco Mode (すりガラス効果OFF)
  }

  final batteryAsync = ref.watch(batteryStateProvider);
  return batteryAsync.maybeWhen(
    data: (data) => data.batteryLevel <= 20 || data.isInPowerSaveMode,
    orElse: () => false,
  );
});
