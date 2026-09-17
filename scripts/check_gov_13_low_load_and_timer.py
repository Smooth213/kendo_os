#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第13条 ガバナンス監査】🔋 端末低負荷・省電力・タイマー沈黙 ＆ サーマル適応制御規約
================================================================================
① サーマル冷却＆省電力モード管理（温度＞手動＞自動 ガバナンス）
② 待機時タイマー沈黙（非カウント時 Timer.periodic 起動停止・CPU 0%維持）
③ タイマーTick適正化（通常1000ms間引きTick＆生ミリ秒差分加算＆天井秒逆算排除）
④ ThermalPowerGovernor によるVRR適応制御（targetFps / isVrrThrottled）
⑤ タイマーコールドスリープ（enterColdSleep / resumeFromColdSleep）
⑥ 画像ダウンサンプリング＆StackTrace走査排除
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第13条 ガバナンス監査】🔋 端末低負荷・省電力・タイマー沈黙 ＆ サーマル適応制御規約")
    print("=" * 68)

    # 1. ThermalPowerGovernor 単体テスト
    res_thermal = subprocess.run(
        ["python3", "scripts/check_thermal_power_governance.py"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    is_thermal_ok = (res_thermal.returncode == 0)

    # 2. 低負荷＆タイマーガバナンステスト
    cmd = [
        "flutter",
        "test",
        "test/governance/low_load_and_timer_governance_test.dart",
        "--reporter=expanded",
    ]
    res_main = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_main_ok = (res_main.returncode == 0)

    is_all_ok = is_thermal_ok and is_main_ok

    rules = [
        ("① [サーマルモード管理] 温度＞手動＞自動 ガバナンス永続保証規約", is_thermal_ok),
        ("② [待機タイマー沈黙] タイマーループ内ディスクI/O禁止 ＆ AppLifecycleListener規約", is_main_ok),
        ("③ [Tick適正化] 通常1000ms間引きTick ＆ 生ミリ秒直接加算（天井逆算排除）規約", is_main_ok),
        ("④ [VRR適応制御] ThermalPowerGovernor targetFps / isVrrThrottled 規約", is_main_ok),
        ("⑤ [コールドスリープ] match_timer_provider の enter/resumeFromColdSleep 規約", is_main_ok),
        ("⑥ [画像ダウンサンプリング] cacheWidth / cacheHeight ＆ StackTrace走査排除規約", is_main_ok),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_all_ok:
        print(" 🟢 監査結果: 合格 (端末低負荷・省電力・タイマー沈黙 ＆ サーマル適応制御規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第13条 端末低負荷・省電力・タイマー沈黙 ＆ サーマル適応制御規約に違反があります)")
        print("=" * 68)
        if not is_thermal_ok:
            print(res_thermal.stdout + res_thermal.stderr)
        if not is_main_ok:
            print(res_main.stdout + res_main.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
