#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 特定固有名詞ハードコード完全禁止 監査スクリプト
================================================================================
プロダクトコード (lib/) 配下に、特定道場・団体等の固有名詞（「道上」「道上剣友会」）が
直接ハードコードされていないかを厳格に検査します。
"""

import os
import sys

FORBIDDEN_KEYWORDS = ['道上剣友会', '道上']
TARGET_DIR = 'lib'

def check_no_hardcoded_names():
    if not os.path.isdir(TARGET_DIR):
        print(f"❌ エラー: '{TARGET_DIR}' ディレクトリが見つかりません。")
        sys.exit(1)

    violations = []

    for root, _, files in os.walk(TARGET_DIR):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        for line_num, line in enumerate(f, 1):
                            for keyword in FORBIDDEN_KEYWORDS:
                                if keyword in line:
                                    violations.append({
                                        'file': file_path,
                                        'line_num': line_num,
                                        'keyword': keyword,
                                        'content': line.strip(),
                                    })
                except Exception as e:
                    print(f"⚠️ ファイル読み込みエラー: {file_path} ({e})")

    if violations:
        print(f"🔴 【規約違反】lib/ 配下に特定固有名詞が {len(violations)} 件検出されました！")
        print("   汎用的な名称（〇〇剣友会, 山田 など）を使用してください:\n")
        for v in violations:
            print(f"  ❌ {v['file']}:{v['line_num']} -> 禁止キーワード \"{v['keyword']}\" を検出:")
            print(f"     \"{v['content']}\"")
        return False

    print("🟢 lib/ 配下の全Dartファイルに特定固有名詞（道上・道上剣友会）は検出されませんでした (0件)")
    return True

if __name__ == "__main__":
    success = check_no_hardcoded_names()
    sys.exit(0 if success else 1)
