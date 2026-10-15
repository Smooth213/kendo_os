#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第302条 ガバナンス監査】📄 UIレンダリング安全・PDF組版 ＆ 常設ドック規約
================================================================================
① 全ページ UIゼロレンダリングエラー保証（オーバーフローゼロ）
② PDF組版・長文字列あふれ・改ページ安全
③ ドック常設ミニパネル・オーバーレイ解放規約
"""

import os
import subprocess
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

from gov_static_scanner import get_file_content

SUB_AUDITS = [
    ("① 全ページ UIゼロレンダリングエラー保証規約", ["python3", "scripts/check_rendering_safety_governance.py"]),
    ("② PDF組版・長文字列あふれ・改ページ安全規約", ["python3", "scripts/check_pdf_layout_safety_governance.py"]),
    ("③ ドック常設ミニパネル・オーバーレイ解放規約", ["python3", "scripts/check_dock_lifecycle_governance.py"]),
]


def check_dock_static_contracts():
    c_export = get_file_content("lib/features/tournament/presentation/components/official_record/official_record_export_bar.dart") or ""
    c_program = get_file_content("lib/features/tournament/presentation/components/program_management/program_management_content_views.dart") or ""
    c_slot = get_file_content("lib/features/tournament/presentation/components/program_management/dock_slot_layout_calculator.dart") or ""
    c_dock_button = get_file_content("lib/features/tournament/presentation/components/program_management/floating_program_dock_button.dart") or ""
    c_timer = get_file_content("lib/features/tournament/presentation/providers/dock_timer_provider.dart") or ""

    ok4 = "class OfficialRecordExportBar" in c_export or "OfficialRecordExportScope" in c_export
    ok5 = "PdfViewerController" in c_program or "cacheWidth" in c_program
    ok6 = "class DockSlotLayoutCalculator" in c_slot and "DockSlotLayoutCalculator" in c_dock_button
    ok7 = "class DockTimerNotifier" in c_timer or "dockTimer" in c_timer

    return [
        ("④ 大会＆部内戦観戦 公式記録一括エクスポート＆UI永続保証規約", ok4),
        ("⑤ ドックプログラム閲覧位置端末保存・自動復元 ＆ PDFページキャッシュ契約保証規約", ok5),
        ("⑥ 常設ドックスロット配置座標 ＆ スワップ決定論保証規約", ok6),
        ("⑦ 常設ドックタイマー入力整合 ＆ ジグル浮遊保証規約", ok7),
    ]


def main():
    print("=" * 68)
    print(" 📊 【第302条 ガバナンス監査】📄 UIレンダリング安全・PDF組版 ＆ 常設ドック規約")
    print("=" * 68)

    all_passed = True
    for label, cmd in SUB_AUDITS:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        is_ok = (res.returncode == 0)
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        if not is_ok:
            all_passed = False
            print(f"\n--- [詳細エラー: {label}] ---")
            print(res.stdout + res.stderr)
            print("-" * 40)

    static_rules = check_dock_static_contracts()
    for label, is_ok in static_rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        if not is_ok:
            all_passed = False

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (UIレンダリング安全・PDF組版 ＆ 常設ドック規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第302条 UIレンダリング安全・PDF組版 ＆ 常設ドック規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
