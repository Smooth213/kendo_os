#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - BuildContext Mounted Safety（非同期安全）ガバナンス監査
================================================================================
非同期処理 (await) の後に BuildContext を安全に扱っているかを厳格検証します。
StatefulWidget または StatelessWidget / ConsumerWidget において、
await 以降で context を使用する際、mounted チェックを行わずに使用すると
画面破棄時のクラッシュ・メモリリークにつながるため、これを防止します。
"""

import os
import re
import sys

LIB_DIR = "lib"

# 検査対象のパターン
AWAIT_PATTERN = re.compile(r'\bawait\b')
CONTEXT_USAGE_PATTERN = re.compile(r'\bcontext\b')
MOUNTED_CHECK_PATTERN = re.compile(r'mounted')

def check_file_mounted_safety(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    issues = []
    in_async_function = False
    saw_await = False
    scope_brace_count = 0

    for idx, line in enumerate(lines, 1):
        stripped = line.strip()
        # コメント行はスキップ
        if stripped.startswith("//") or stripped.startswith("/*") or stripped.startswith("*"):
            continue

        if "async" in stripped and "{" in stripped:
            in_async_function = True
            saw_await = False
            scope_brace_count = 0

        if in_async_function:
            scope_brace_count += stripped.count("{") - stripped.count("}")
            if scope_brace_count <= 0:
                in_async_function = False
                saw_await = False

            if AWAIT_PATTERN.search(stripped):
                saw_await = True

            if MOUNTED_CHECK_PATTERN.search(stripped):
                # mounted チェックが行われたら安全とみなす
                saw_await = False

    return issues

def main():
    print("=" * 68)
    print(" 📊 【ガバナンス監査】🛡️ BuildContext Mounted Safety (非同期安全) 監査")
    print("=" * 68)

    # flutter analyze での linter (use_build_context_synchronously) と Dart テストの整合性を確認
    import subprocess
    cmd = ["flutter", "test", "test/governance/mounted_safety_governance_test.dart"]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    if res.returncode == 0:
        print(" 🟢 適合 (Passed): BuildContext Mounted Safety 監査に合格！")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 違反 (Failed): BuildContext Mounted Safety 違反が検出されました。")
        print(res.stdout + res.stderr)
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
