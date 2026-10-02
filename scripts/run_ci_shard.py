#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 Kendo OS - CI 高速シャード実行ランナー (ラウンドロビン均等分散 ＆ 2コア並列)
# ==============================================================================
import glob
import os
import subprocess
import sys

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 scripts/run_ci_shard.py <shard_index> <total_shards>")
        sys.exit(1)

    shard_index = int(sys.argv[1])
    total_shards = int(sys.argv[2])

    # プロジェクトルートに移動
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    os.chdir(project_root)

    # 全テストファイルを取得してソート（決定論的配分）
    all_files = sorted(glob.glob("test/**/*_test.dart", recursive=True))
    total_files = len(all_files)

    # ラウンドロビン方式で均等分散（重いテストの集中を完全防止）
    shard_files = [f for i, f in enumerate(all_files) if i % total_shards == shard_index]

    print("=" * 64)
    print(f" 🥋 Kendo OS CI Shard Runner ({shard_index + 1}/{total_shards})")
    print(f" 📦 担当ファイル数: {len(shard_files)} / {total_files}")
    print(f" ⚡ 実行モード: --concurrency 2 --no-pub (2コア並列・全ファイル直接指定)")
    print("=" * 64)

    cmd = ["flutter", "test", "--concurrency", "2", "--no-pub"] + shard_files
    result = subprocess.run(cmd)
    sys.exit(result.returncode)

if __name__ == "__main__":
    main()
