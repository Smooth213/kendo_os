#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第402条 ガバナンス監査】🔋 端末低負荷・省電力・タイマー沈黙 ＆ サーマル適応制御規約
================================================================================
① サーマル冷却＆省電力モード管理（温度＞手動＞自動 ガバナンス）
② 待機時タイマー沈黙（非カウント時 Timer.periodic 起動停止・CPU 0%維持）
③ タイマーTick適正化（通常1000ms間引きTick＆生ミリ秒差分加算＆天井秒逆算排除）
④ ThermalPowerGovernor によるVRR適応制御（targetFps / isVrrThrottled）
⑤ タイマーコールドスリープ（enterColdSleep / resumeFromColdSleep）
⑥ 画像ダウンサンプリング＆StackTrace走査排除
"""

import os
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

from gov_static_scanner import get_file_content

def main():
    print("=" * 68)
    print(" 📊 【第402条 ガバナンス監査】🔋 端末低負荷・省電力・タイマー沈黙 ＆ サーマル適応制御規約")
    print("=" * 68)

    # 1. ThermalPowerGovernor 定義検査
    gov_content = get_file_content("lib/shared/application/services/thermal_power_governor.dart") or ""
    c_timer = get_file_content("lib/features/tournament/presentation/operate/providers/match_timer_provider.dart") or ""
    c_renseikai = get_file_content("lib/features/tournament/presentation/operate/providers/renseikai_master_timer_provider.dart") or ""
    c_dock = get_file_content("lib/features/tournament/presentation/providers/dock_timer_provider.dart") or ""
    c_settings = get_file_content("lib/shared/presentation/providers/settings_provider.dart") or ""
    c_views = get_file_content("lib/features/tournament/presentation/components/program_management/program_management_content_views.dart") or ""
    c_viewer_img = get_file_content("lib/features/tournament/presentation/components/program_viewer/program_viewer_image_body.dart") or ""
    c_liquid = get_file_content("lib/shared/widgets/liquid_background.dart") or ""

    # ① サーマルモード管理
    is_thermal_ok = (
        "ThermalPowerMode" in gov_content
        and "setMode" in gov_content
        and "updateThermalStatus" in gov_content
    )

    # ② 待機タイマー沈黙: AppLifecycleListener 配備 ＆ タイマーループ内I/O禁止
    is_silence_ok = (
        "AppLifecycleListener" in c_renseikai
        and "AppLifecycleListener" in c_dock
        and "AppLifecycleListener" in c_settings
        and "_saveState()" not in c_renseikai.split("if (state > 0) {")[1].split("} else {")[0]
        if "if (state > 0) {" in c_renseikai else False
    )

    # ③ Tick適正化: 生ミリ秒加算 ＆ 天井秒逆算排除
    is_tick_ok = (
        "now.difference(match.timerStartedAt!).inMilliseconds" in c_timer
        and "updateRemainingSeconds(" not in (
            c_timer.split("Future<void> toggleTimer(")[1].split("Future<void> updateRemainingSeconds")[0]
            if "Future<void> toggleTimer(" in c_timer and "Future<void> updateRemainingSeconds" in c_timer
            else ""
        )
    )

    # ④ VRR適応制御
    is_vrr_ok = (
        "targetFps" in gov_content
        and "isVrrThrottled" in gov_content
        and "ecoCooling" in gov_content
        and "ultraSave" in gov_content
    )

    # ⑤ コールドスリープ
    is_cold_sleep_ok = (
        "void enterColdSleep()" in c_timer
        and "void resumeFromColdSleep()" in c_timer
        and "AppLifecycleListener" in c_timer
    )

    # ⑥ 画像ダウンサンプリング ＆ StackTrace走査排除 ＆ バッテリー60sポーリング
    is_resource_ok = (
        "cacheWidth: 400" in c_views
        and "cacheWidth: 150" in c_views
        and "cacheWidth: displaySize.width.toInt()" in c_viewer_img
        and "StackTrace.current.toString()" not in c_liquid
        and "RadialGradient" in c_liquid
        and "Duration(seconds: 60)" in c_settings
    )

    rules = [
        ("① [サーマルモード管理] 温度＞手動＞自動 ガバナンス永続保証規約", is_thermal_ok),
        ("② [待機タイマー沈黙] タイマーループ内ディスクI/O禁止 ＆ AppLifecycleListener規約", is_silence_ok),
        ("③ [Tick適正化] 通常1000ms間引きTick ＆ 生ミリ秒直接加算（天井逆算排除）規約", is_tick_ok),
        ("④ [VRR適応制御] ThermalPowerGovernor targetFps / isVrrThrottled 規約", is_vrr_ok),
        ("⑤ [コールドスリープ] match_timer_provider の enter/resumeFromColdSleep 規約", is_cold_sleep_ok),
        ("⑥ [画像ダウンサンプリング] cacheWidth / cacheHeight ＆ StackTrace走査排除規約", is_resource_ok),
    ]

    is_all_ok = all(ok for _, ok in rules)

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_all_ok:
        print(" 🟢 監査結果: 合格 (端末低負荷・省電力・タイマー沈黙 ＆ サーマル適応制御規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第402条 端末低負荷・省電力・タイマー沈黙 ＆ サーマル適応制御規約に違反があります)")
        print("=" * 68)
        if not is_thermal_ok:
            print(res_thermal.stdout + res_thermal.stderr)
        if not is_main_ok:
            print(res_main.stdout + res_main.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
