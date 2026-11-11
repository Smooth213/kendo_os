#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第301条 形状言語ガバナンス監査】📐 用途×形状 整合性保証スクリプト
================================================================================
design_system_manifest.json の形状仕様 (shape_spec) に基づき、
「トークン名は使っているが、用途に対して誤った角丸トークン（例: ボタンや1行入力に
カード用の AppRadius.medium 等）を指定している」すり抜けを全 Dart ファイルから検知します。

1. ボタン形状 (action_buttons):
   ElevatedButton / OutlinedButton / FilledButton / TextButton の styleFrom で
   RoundedRectangleBorder に非カプセル角丸 (medium/small/large等) を指定することを禁止。
   (StadiumBorder / AppSemanticTokens.buttonShape / AppRadius.capsule / AppRadius.full を強制)

2. 入力フォーム形状 (single_line_inputs / multiline_inputs):
   OutlineInputBorder に非カプセル・非Squircle16pxの角丸 (medium/small等) を指定することを禁止。
   (単一行は AppRadius.capsule / AppSemanticTokens.inputRadius、複数行は AppRadius.large / multilineInputRadius を強制)
"""

import os
import re
import sys

ALLOWED_BUTTON_RADIUS = ("capsule", "full", "buttonRadius")
ALLOWED_SINGLE_INPUT_RADIUS = ("capsule", "full", "inputRadius")
ALLOWED_MULTI_INPUT_RADIUS = ("large", "multilineInputRadius")


def extract_paren_block(content, start_idx):
    """start_idx の '(' から対応する ')' までの文字列を抽出する"""
    open_pos = content.find("(", start_idx)
    if open_pos == -1:
        return ""
    depth = 0
    for i in range(open_pos, len(content)):
        ch = content[i]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return content[open_pos : i + 1]
    return content[open_pos : open_pos + 600]


def scan_file(rel_path, content):
    violations = []

    # 1. ボタン形状チェック (*.styleFrom(...))
    btn_pattern = re.compile(
        r"(?:ElevatedButton|OutlinedButton|FilledButton|TextButton)\.styleFrom\("
    )
    for m in btn_pattern.finditer(content):
        block = extract_paren_block(content, m.start())
        shape_match = re.search(
            r"shape:\s*(?:const\s+)?RoundedRectangleBorder\(", block
        )
        if shape_match:
            rrb_block = extract_paren_block(
                block, shape_match.start() + block[shape_match.start() :].find("RoundedRectangleBorder(")
            )
            br_match = re.search(r"borderRadius:\s*([^,\)]+(?:\([^)]*\))?)", rrb_block)
            if br_match:
                br_val = br_match.group(1).strip()
                if not any(allowed in br_val for allowed in ALLOWED_BUTTON_RADIUS):
                    line = content[: m.start()].count("\n") + 1
                    violations.append(
                        (
                            rel_path,
                            line,
                            "ボタン形状違反",
                            f"ボタンに非カプセル角丸 ({br_val}) が指定されています。StadiumBorder() を使用してください。",
                        )
                    )

    # 2. 入力フォーム境界チェック (OutlineInputBorder(...))
    for m in re.finditer(r"OutlineInputBorder\(", content):
        # app_text_field.dart 自体は isMultiline 判定で両方を返す設計元なので除外
        if rel_path == "shared/widgets/app_text_field.dart":
            continue
        rrb_block = extract_paren_block(content, m.start())
        br_match = re.search(r"borderRadius:\s*([^,\)]+(?:\([^)]*\))?)", rrb_block)
        if br_match:
            br_val = br_match.group(1).strip()
            # 直近の TextField / TextFormField / AppTextField ブロック全体を抽出して maxLines を判定
            ctx_before = content[max(0, m.start() - 1200) : m.start()]
            last_tf = max(
                ctx_before.rfind("TextField("),
                ctx_before.rfind("TextFormField("),
                ctx_before.rfind("AppTextField("),
            )
            if last_tf != -1:
                tf_start = max(0, m.start() - 1200) + last_tf
                field_ctx = extract_paren_block(content, tf_start)
            else:
                field_ctx = ctx_before[-400:]
            is_multi = bool(
                re.search(r"maxLines:\s*(?:[2-9]|\d{2,}|null)", field_ctx)
                or "expands: true" in field_ctx
            )

            if is_multi:
                if not any(allowed in br_val for allowed in ALLOWED_MULTI_INPUT_RADIUS):
                    line = content[: m.start()].count("\n") + 1
                    violations.append(
                        (
                            rel_path,
                            line,
                            "複数行入力形状違反",
                            f"複数行入力の枠線に {br_val} が指定されています。Squircle 16px (AppSemanticTokens.multilineInputRadius / AppRadius.large) を使用してください。",
                        )
                    )
            else:
                if not any(allowed in br_val for allowed in ALLOWED_SINGLE_INPUT_RADIUS):
                    line = content[: m.start()].count("\n") + 1
                    violations.append(
                        (
                            rel_path,
                            line,
                            "単一行入力形状違反",
                            f"単一行入力の枠線に非カプセル角丸 ({br_val}) が指定されています。AppSemanticTokens.inputRadius (AppRadius.capsule) または AppTextField デフォルトを使用してください。",
                        )
                    )

    return violations


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.abspath(os.path.join(script_dir, ".."))
    lib_dir = os.path.join(root_dir, "lib")

    all_violations = []
    scanned_files = 0

    for root, _, files in os.walk(lib_dir):
        for fn in sorted(files):
            if not fn.endswith(".dart"):
                continue
            full_path = os.path.join(root, fn)
            rel_path = os.path.relpath(full_path, lib_dir)
            with open(full_path, "r", encoding="utf-8") as f:
                content = f.read()
            scanned_files += 1
            all_violations.extend(scan_file(rel_path, content))

    print("=" * 72)
    print(" 📐 【第301条 形状言語ガバナンス監査】用途×形状 整合性チェックレポート")
    print("=" * 72)
    print(f" 📂 走査対象: lib/ 配下全 {scanned_files} ファイル")
    print(f" 🚨 検出された形状規約違反: {len(all_violations)} 件")
    print("-" * 72)

    if all_violations:
        for rel_path, line, v_type, msg in all_violations:
            print(f"  ❌ {rel_path}:{line} [{v_type}] {msg}")
        print("=" * 72)
        print(" 🔴 監査結果: 違反 (用途に対して不適切な形状トークンが使用されています)")
        print("=" * 72)
        sys.exit(1)

    print(" 🟢 すべてのボタンおよび入力フォームが規定の形状言語（カプセル / Squircle 16px）に完全適合しています！")
    print("=" * 72)
    sys.exit(0)


if __name__ == "__main__":
    main()
