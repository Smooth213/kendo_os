#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🌐 Web境界・ネイティブ直接import遮断 ガバナンス監査スクリプト
================================================================================
Web/PWAの安定稼働を保証するため、ドメイン層・共通ビジネスロジック・
Web観客ビューア層（features/match, features/viewer 等）において、
ネイティブ専用ライブラリ（dart:io, dart:ffi 等）の直接importを永久遮断します。
"""

import os
import re
import sys

# ネイティブ直接importを厳禁とするディレクトリ群
ISOLATED_DIRS = [
    "lib/features/match",
    "lib/features/viewer",
]

FORBIDDEN_IMPORTS = [
    ("dart:io", re.compile(r"import\s+['\"]dart:io['\"]")),
    ("dart:ffi", re.compile(r"import\s+['\"]dart:ffi['\"]")),
]

def check_isolation():
    violations = []

    for isolated_dir in ISOLATED_DIRS:
        if not os.path.exists(isolated_dir):
            continue
        for root, _, files in os.walk(isolated_dir):
            for file in files:
                if file.endswith(".dart"):
                    path = os.path.join(root, file)
                    with open(path, "r", encoding="utf-8") as f:
                        content = f.read()
                        for lib_name, pattern in FORBIDDEN_IMPORTS:
                            if pattern.search(content):
                                violations.append((path, lib_name))

    return violations

def main():
    print("=" * 68)
    print(" 📊 【ガバナンス監査】🌐 Web境界・ネイティブ直接import遮断 監査")
    print("=" * 68)

    violations = check_isolation()

    if not violations:
        print(" 🟢 適合 (Passed): Web共通層・観客ビューア層へのネイティブ直接import混入ゼロを確認！")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 違反 (Failed): 以下のファイルでWeb境界違反（ネイティブ直接import）が検出されました：")
        for path, lib_name in violations:
            print(f"  ❌ {path} -> {lib_name}")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
