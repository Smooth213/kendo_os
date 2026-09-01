#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - ファイル行数ガバナンス監査スクリプト
==================================================
lib/ 配下のDartファイルが肥大化（デフォルト上限: 500行）していないかを厳格に検証します。
自動生成ファイル（*.g.dart, *.freezed.dart等）や設定ファイルは自動除外されます。
"""

import os
import sys
import argparse

# デフォルト閾値
DEFAULT_MAX_LINES = 500
DEFAULT_WARN_LINES = 450

# 除外するファイル拡張子および特定ファイル名
EXCLUDE_EXTENSIONS = ('.g.dart', '.freezed.dart')
EXCLUDE_FILENAMES = ('firebase_options.dart',)

def count_lines(filepath):
    """ファイルの有効行数をカウント"""
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        return len(f.readlines())

def scan_dart_files(target_dir, max_lines, warn_lines):
    """ディレクトリ配下のDartファイルをスキャンして監査"""
    files_stats = []
    errors = []
    warnings = []

    for root, _, filenames in os.walk(target_dir):
        for f in filenames:
            if not f.endswith('.dart'):
                continue
            if any(f.endswith(ext) for ext in EXCLUDE_EXTENSIONS):
                continue
            if f in EXCLUDE_FILENAMES:
                continue

            filepath = os.path.join(root, f)
            lines = count_lines(filepath)
            rel_path = os.path.relpath(filepath, os.getcwd())
            files_stats.append((lines, rel_path))

            if lines >= max_lines:
                errors.append((lines, rel_path))
            elif lines >= warn_lines:
                warnings.append((lines, rel_path))

    files_stats.sort(reverse=True)
    return files_stats, errors, warnings

def main():
    parser = argparse.ArgumentParser(description="Kendo OS ファイル行数ガバナンス監査")
    parser.add_argument("--dir", default="lib", help="スキャン対象ディレクトリ (デフォルト: lib)")
    parser.add_argument("--max-lines", type=int, default=DEFAULT_MAX_LINES, help=f"エラーとなる上限行数 (デフォルト: {DEFAULT_MAX_LINES})")
    parser.add_argument("--warn-lines", type=int, default=DEFAULT_WARN_LINES, help=f"警告となる上限行数 (デフォルト: {DEFAULT_WARN_LINES})")
    parser.add_argument("--strict", action="store_true", help="警告（warn-lines以上）が存在する場合もエラーとして終了")
    args = parser.parse_args()

    if not os.path.isdir(args.dir):
        print(f"❌ ディレクトリが見つかりません: {args.dir}")
        sys.exit(1)

    files_stats, errors, warnings = scan_dart_files(args.dir, args.max_lines, args.warn_lines)

    total_files = len(files_stats)
    total_lines = sum(lines for lines, _ in files_stats)
    avg_lines = total_lines / total_files if total_files > 0 else 0

    print("=" * 60)
    print(" 📊 【ガバナンス監査 1/10】📏 コード行数・アーキテクチャ 監査レポート")
    print("=" * 60)
    print(f" 📂 監査対象: {args.dir}/")
    print(f" 📄 総実コードファイル数: {total_files} ファイル")
    print(f" 📏 総行数: {total_lines:,} 行 (平均: {avg_lines:.1f} 行/ファイル)")
    print(f" 🚨 エラー閾値 (上限): {args.max_lines} 行以上")
    print(f" ⚠️  警告閾値: {args.warn_lines} 行以上")
    print("-" * 60)

    if errors:
        print(f"\n🚨 【エラー】{args.max_lines}行以上の肥大化ファイル ({len(errors)} 件):")
        for lines, path in errors:
            print(f"  ❌ {lines:4d} 行: {path}")

    if warnings:
        print(f"\n⚠️  【注意】{args.warn_lines}〜{args.max_lines-1}行の注意ファイル ({len(warnings)} 件):")
        for lines, path in warnings:
            print(f"  ⚠️  {lines:4d} 行: {path}")

    print("-" * 60)
    if errors:
        print(f" 🔴 監査結果: 不合格 ({len(errors)} 件の肥大化ファイルが存在します)")
        print("    👉 単一責任原則に基づき、パーツやヘルパーに切り出して500行未満にスリム化してください。")
        print("=" * 60)
        sys.exit(1)
    elif args.strict and warnings:
        print(f" 🔴 監査結果 (strictモード): 不合格 ({len(warnings)} 件の警告ファイルが存在します)")
        print("=" * 60)
        sys.exit(1)
    else:
        print(f" 🟢 監査結果: 合格 (すべてのファイルが {args.max_lines} 行未満です！)")
        print("=" * 60)
        sys.exit(0)

if __name__ == "__main__":
    main()
