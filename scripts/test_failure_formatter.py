#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 Kendo OS - テスト失敗詳細フォーマッター (ファイル名・行番号・期待値不一致 抽出)
# ==============================================================================
import re

def parse_and_format_failures(output_text: str) -> str:
    """
    Flutter testの出力から失敗箇所（ファイル名、行番号、テスト名、Expected/Actual）を抽出し、
    ターミナル最下部にわかりやすく整形表示するサマリー文字列を生成します。
    """
    lines = output_text.splitlines()
    failures = []
    
    current_test_name = ""
    current_expected = []
    current_actual = []
    current_location = ""
    in_error = False
    
    for i, line in enumerate(lines):
        # テスト名の取得 (例: 00:05 +10 -1: test/widget/foo_test.dart: テスト名 [E])
        match_test = re.search(r'\d+:\d+\s+\+\d+\s+-\d+:\s+(.*?):\s+(.*?)(?:\s+\[E\])?$', line)
        if match_test:
            if current_location or current_expected:
                failures.append({
                    "test_name": current_test_name,
                    "location": current_location,
                    "expected": "\n".join(current_expected).strip(),
                    "actual": "\n".join(current_actual).strip(),
                })
                current_expected = []
                current_actual = []
                current_location = ""
            
            current_test_name = match_test.group(2).strip()
            in_error = True
            continue

        if "Expected:" in line:
            current_expected.append(line.strip())
            in_error = True
            continue
        elif "Actual:" in line:
            current_actual.append(line.strip())
            in_error = True
            continue
        elif "Which:" in line:
            current_actual.append(line.strip())
            continue

        # ファイルと行番号の特定 (例: test/widget/foo_test.dart 123:45 ...)
        match_loc = re.search(r'(test/[\w\./_-]+\.dart)\s+(\d+):(\d+)', line)
        if match_loc and not current_location:
            file_path = match_loc.group(1)
            line_num = match_loc.group(2)
            current_location = f"{file_path} ({line_num}行目)"

    # 最後の failure を追加
    if current_location or current_expected:
        failures.append({
            "test_name": current_test_name,
            "location": current_location,
            "expected": "\n".join(current_expected).strip(),
            "actual": "\n".join(current_actual).strip(),
        })

    if not failures:
        # パースできなかった場合の汎用抽出
        loc_matches = re.findall(r'(test/[\w\./_-]+\.dart)\s+(\d+):(\d+)', output_text)
        if loc_matches:
            unique_locs = list(dict.fromkeys([f"{m[0]} ({m[1]}行目)" for m in loc_matches]))
            return "\n".join([f"  ❌ 失敗箇所: {loc}" for loc in unique_locs])
        return "  ⚠️ 詳細は上記のテストログをご確認ください。"

    summary_lines = []
    summary_lines.append("=" * 60)
    summary_lines.append(" 🚨 【不合格サマリー】失敗したファイル・行番号・期待値の不一致")
    summary_lines.append("=" * 60)
    
    for idx, f in enumerate(failures, 1):
        loc = f['location'] if f['location'] else "テストファイル特定中 (ログ参照)"
        summary_lines.append(f" ❌ [{idx}] 失敗箇所: {loc}")
        if f['test_name']:
            summary_lines.append(f"    📝 テスト名: {f['test_name']}")
        if f['expected']:
            summary_lines.append(f"    🎯 {f['expected']}")
        if f['actual']:
            summary_lines.append(f"    🔍 {f['actual']}")
        summary_lines.append("-" * 60)

    summary_lines.append(" 💡 上記のファイルの該当行番号を確認・修正してください。")
    summary_lines.append("=" * 60)
    return "\n".join(summary_lines)
