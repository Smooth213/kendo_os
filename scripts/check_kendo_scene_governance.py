#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 試合シーン（本戦・錬成・申合せ）表記 ＆ 配色ガバナンス監査スクリプト
=============================================================================
目的:
  アプリ全体で「本戦」「錬成」「申合せ」の表記およびカラー定義が
  Single Source of Truth (KendoSceneHelper) に完全準拠しているかを厳格に検証します。

検査項目:
  1. 禁止UI表記の混入検知:
     - '申し合わせ' / '【申し合わせ】' -> '申合せ' / '【申合せ】' を使用すること
     - '【錬成会】' -> '【錬成】' を使用すること
  2. ハードコードされたシーン色分岐の検知:
     - 'isMoushiawase ? context.appColors.warningColor : ...' などの画面個別色指定を検知
     - 必ず KendoSceneHelper / KendoSceneBadge を経由すること
=============================================================================
"""

import os
import re
import sys

LIB_DIR = "lib"

# 許容される内部識別子・プロパティ名（除外対象）
ALLOWED_PROPERTY_NAMES = [
    "useMoushiawaseRule",
    "moushiawaseRule",
    "moushiawaseTime",
    "moushiawaseIsRunningTime",
    "moushiawaseHasHantei",
    "moushiawaseType",
    "moushiawaseOverallTime",
    "onUseMoushiawaseRuleChanged",
    "onMoushiawaseTimeChanged",
    "onMoushiawaseRunningChanged",
    "onMoushiawaseHanteiChanged",
    "onMoushiawaseTypeChanged",
    "onMoushiawaseOverallTimeChanged",
    "useRenseikaiRule",
    "renseikaiRule",
]

def check_scene_governance():
    violations = []
    
    # 監査対象ファイル拡張子
    target_extensions = (".dart",)

    for root, _, files in os.walk(LIB_DIR):
        for file in files:
            if not file.endswith(target_extensions):
                continue
            
            file_path = os.path.join(root, file)
            
            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                lines = f.readlines()
            
            for line_idx, line in enumerate(lines, start=1):
                raw_line = line.strip()
                
                # 1. 禁止UI表記の検査
                # '申し合わせ'（文字列リテラルまたはUIテキスト内）
                if "申し合わせ" in raw_line:
                    # kendo_scene_badge.dart内部の下位互換マッチングロジックは除外
                    if "kendo_scene_badge.dart" in file_path and "contains('申し合わせ')" in raw_line:
                        continue
                    # 過去データ後方互換用（detectScene / import / cleanCategoryBaseName 等）は除外
                    if "note.contains('申し合わせ')" in raw_line or "category.contains('申し合わせ')" in raw_line or "cleanCategoryBaseName" in raw_line or "RegExp(" in raw_line:
                        continue
                    
                    violations.append({
                        "file": file_path,
                        "line": line_idx,
                        "content": raw_line,
                        "message": "禁止UI表記「申し合わせ」が検出されました。公式表記「申合せ」に統一してください。"
                    })
                
                # '【錬成会】'
                if "【錬成会】" in raw_line:
                    violations.append({
                        "file": file_path,
                        "line": line_idx,
                        "content": raw_line,
                        "message": "禁止UI表記「【錬成会】」が検出されました。公式表記「【錬成】」に統一してください。"
                    })

                # 2. ハードコードされたシーン色分岐の検査 (isMoushiawase ? ... : ...)
                if "isMoushiawase ?" in raw_line and ("warningColor" in raw_line or "primaryAccent" in raw_line or "AppKendoColors" in raw_line):
                    violations.append({
                        "file": file_path,
                        "line": line_idx,
                        "content": raw_line,
                        "message": "画面個別でのシーン色分岐（isMoushiawase ? ...）が検出されました。KendoSceneBadge または KendoSceneHelper を使用してください。"
                    })

    return violations

def main():
    print("=" * 70)
    print(" 🥋 Kendo OS - 試合シーン（本戦・錬成・申合せ）表記＆配色ガバナンス監査")
    print("=" * 70)
    
    violations = check_scene_governance()
    
    if violations:
        print(f"\n🚨 【ガバナンス違反】{len(violations)} 件の表記・配色違反が検出されました:\n")
        for v in violations:
            print(f"  ❌ {v['file']}:{v['line']}")
            print(f"     コード: {v['content']}")
            print(f"     理由  : {v['message']}\n")
        print("💡 表記は「本戦」「錬成」「申合せ」とし、配色は KendoSceneHelper を使用してください。")
        sys.exit(1)
    else:
        print("\n✅ [PASS] 試合シーン表記・カラーガバナンス監査: 100% 遵守 (違反 0 件)")
        print("=" * 70)
        sys.exit(0)

if __name__ == "__main__":
    main()
