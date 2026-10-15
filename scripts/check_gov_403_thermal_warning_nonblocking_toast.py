#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第403条 ガバナンス監査】🚨 サーマル適応警告・省電力UIトースト非ブロッキング表示 ＆ メモリリークゼロ規約
================================================================================
① サーマル・省電力トースト非ブロッキング表示規約（タップ阻害完全ゼロ・モーダル不使用）
② 自動消去・OverlayEntry / Timer / StreamSubscription 明示的完全破棄規約
"""

import sys
from gov_static_scanner import GovStaticScanner


def check_thermal_toast_governance(scanner: GovStaticScanner):
    rel_path = "lib/shared/widgets/thermal_floating_toast.dart"
    content = scanner.read_file(rel_path)
    if not content:
        return False, [f"必須ファイルが存在しません: {rel_path}"]

    violations = []

    # ① 非ブロッキング検証
    if "return widget.child;" not in content:
        violations.append("ThermalToastListener が子ウィジェットをそのまま返していません (ブロッキングリスク)")
    if "showDialog" in content or "AlertDialog" in content:
        violations.append("モーダルダイアログが使用されています (非ブロッキング規約違反)")
    if "OverlayEntry" not in content:
        violations.append("OverlayEntry によるフローティング表示が実装されていません")

    # ② リソース完全解放・リークゼロ検証
    required_dispose_patterns = [
        "void dispose()",
        "_subscription?.cancel()",
        "_dismissTimer?.cancel()",
        "_overlayEntry?.remove()",
    ]
    for pattern in required_dispose_patterns:
        if pattern not in content:
            violations.append(f"dispose 内で '{pattern}' が呼ばれていません (リソースリーク規約違反)")

    # ③ 自動消去タイマー検証
    if "Duration(seconds:" not in content and "Timer(" not in content:
        violations.append("トーストの自動消去タイマーが定義されていません")

    return len(violations) == 0, violations


def main():
    print("=" * 68)
    print(" 📊 【第403条 ガバナンス監査】🚨 サーマル適応警告・省電力UIトースト非ブロッキング表示 ＆ メモリリークゼロ規約")
    print("=" * 68)

    scanner = GovStaticScanner.get_instance()
    is_ok, violations = check_thermal_toast_governance(scanner)

    rules = [
        ("① [非ブロッキング] トースト表示中のタップ操作阻害ゼロ ＆ 即時応答規約", is_ok),
        ("② [リソース完全解放] OverlayEntry / Timer / StreamSubscription dispose破棄規約", is_ok),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    if not is_ok:
        for v in violations:
            print(f"    ❌ {v}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (サーマル適応警告・省電力UIトースト非ブロッキング表示 ＆ メモリリークゼロ規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第403条 サーマル適応警告・省電力UIトースト非ブロッキング表示 ＆ メモリリークゼロ規約に違反があります)")
        print("=" * 68)
        sys.exit(1)


if __name__ == "__main__":
    main()
