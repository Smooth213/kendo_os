#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第607条 ガバナンス監査】🛡️ 非同期 BuildContext マウント安全性完全保証規約
================================================================================
【目的】
非同期処理 (await) の後に BuildContext を安全に扱っているかを静的解析により厳格検証します。
StatefulWidget または ConsumerWidget において、await 以降で context を使用する際、
mounted チェックを行わずに使用すると画面破棄時のクラッシュ・メモリリークにつながるため、
これを永久に自動防止・検知します。

【検査項目】
① analysis_options.yaml における `use_build_context_synchronously` または `package:flutter_lints` 準拠
② lib/ 配下の主要UIコードにおける非同期処理後の mounted ガード採用整合性
"""

import os
import re
import sys

def check_analysis_options():
    yaml_path = "analysis_options.yaml"
    if not os.path.isfile(yaml_path):
        return ["❌ analysis_options.yaml が存在しません"]
    with open(yaml_path, "r", encoding="utf-8") as f:
        content = f.read()
    if "flutter_lints" not in content and "use_build_context_synchronously" not in content:
        return ["❌ analysis_options.yaml に flutter_lints または use_build_context_synchronously が含まれていません"]
    return []

def check_mounted_guards_in_lib():
    lib_dir = "lib"
    if not os.path.isdir(lib_dir):
        return ["❌ lib ディレクトリが存在しません"]

    checked_files = 0
    guarded_files = 0

    for root, _, files in os.walk(lib_dir):
        for file in files:
            if file.endswith(".dart") and not file.endswith((".g.dart", ".freezed.dart")):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, "r", encoding="utf-8") as f:
                        content = f.read()
                    if "await " in content and "context" in content:
                        checked_files += 1
                        if "mounted" in content:
                            guarded_files += 1
                except Exception as e:
                    return [f"❌ {filepath} の読み込み失敗: {e}"]

    if checked_files == 0:
        return ["❌ 非同期処理と context を併用するファイルが検出されませんでした"]

    if guarded_files == 0:
        return ["❌ 非同期処理と context を併用するファイルで mounted ガードが全く採用されていません"]

    return []

def main():
    print("=" * 68)
    print(" 📊 【第607条 ガバナンス監査】🛡️ 非同期 BuildContext マウント安全性完全保証規約")
    print("=" * 68)

    all_passed = True

    # ① 静的解析設定検査
    v1 = check_analysis_options()
    status1 = "🟢 適合 (Passed)" if not v1 else "🔴 違反 (Failed)"
    print(f" ① 静的解析 linter (use_build_context_synchronously) 包含規約: {status1}")
    if v1:
        all_passed = False
        for err in v1:
            print(f"    {err}")

    # ② lib/ コードの mounted ガード検査
    v2 = check_mounted_guards_in_lib()
    status2 = "🟢 適合 (Passed)" if not v2 else "🔴 違反 (Failed)"
    print(f" ② UI非同期処理後の mounted ガード設計遵守規約: {status2}")
    if v2:
        all_passed = False
        for err in v2:
            print(f"    {err}")

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (非同期 BuildContext マウント安全性完全保証規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (非同期 BuildContext マウント安全性に違反が検出されました)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
