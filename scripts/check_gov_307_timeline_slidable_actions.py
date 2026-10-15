#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第307条 ガバナンス監査】🎨 タイムラインスワイプアクション3要素 ＆ 操作排他完全保証規約
================================================================================
本規約は、タイムライン上の全試合カード（対戦枠・個人戦カード・剣道形カード）において、
① スワイプアクション3要素（次戦追加・編集・削除）が過不足なく完全に実装されていること
② 観客席モード・権限分離時の非表示制御が厳格に守られていること
③ モバイルタッチ・Webスクロールジェスチャー排他制御が整合していること
を静的ソースコード検査により保証します。
"""

import subprocess
import sys


def main():
    print("=" * 72)
    print(" 📊 【第307条 ガバナンス監査】🎨 タイムラインスワイプアクション3要素 ＆ 操作排他保証規約")
    print("=" * 72)

    cmd = ["python3", "scripts/check_timeline_slidable_actions_governance.py"]
    res = subprocess.run(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    is_ok = res.returncode == 0

    if is_ok:
        print(" 🟢 適合 (Passed): 全タイムラインカードのスワイプアクション3要素が完全実装されています。")
        print("=" * 72)
        print(" 🟢 監査結果: 合格 (第307条 タイムラインスワイプアクション規約に完全適合！)")
        print("=" * 72)
        sys.exit(0)
    else:
        print(" 🔴 違反 (Failed): スワイプアクションの定義または排他制御に不整合があります。")
        print(res.stdout + res.stderr)
        print("=" * 72)
        print(" 🔴 監査結果: 違反 (第307条 タイムラインスワイプアクション規約に違反があります)")
        print("=" * 72)
        sys.exit(1)


if __name__ == "__main__":
    main()
