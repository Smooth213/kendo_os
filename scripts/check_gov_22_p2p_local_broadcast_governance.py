#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第22条 ガバナンス監査】📶 現場P2Pローカル配信 ＆ ソケットライフサイクル・Webプラットフォーム完全隔離規約
================================================================================
① Web環境安全隔離（kIsWeb 環境におけるネイティブ HttpServer 隔離・安全フォールバック規約）
② ソケット完全破棄（stopServer / Provider破棄時における全WebSocket切断＆ソケット完全破棄規約）
③ 例外安全・リソース防護（複数回起動および多重呼び出し時の防護・リソース安全規約）
④ Gzip圧縮データ可逆性（PayloadCompressionHelper によるデータ完全可逆性規約）
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第22条 ガバナンス監査】📶 現場P2Pローカル配信 ＆ ソケットライフサイクル・Webプラットフォーム完全隔離規約")
    print("=" * 68)

    cmd = [
        "flutter",
        "test",
        "test/governance/p2p_local_broadcast_governance_test.dart",
        "--reporter=expanded",
    ]

    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok = (res.returncode == 0)

    rules = [
        ("① [Web安全隔離] kIsWeb 環境におけるネイティブ HttpServer 隔離・安全フォールバック規約", is_ok),
        ("② [ソケット破棄] stopServer / Provider破棄時における全WebSocket切断＆ソケット完全破棄規約", is_ok),
        ("③ [例外安全] 複数回起動および多重呼び出し時の防護・リソース安全規約", is_ok),
        ("④ [データ可逆性] Gzip圧縮ペイロード送信時（PayloadCompressionHelper）のデータ完全可逆性規約", is_ok),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (現場P2Pローカル配信 ＆ ソケットライフサイクル・Webプラットフォーム完全隔離規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第22条 現場P2Pローカル配信 ＆ ソケットライフサイクル・Webプラットフォーム完全隔離規約に違反があります)")
        print("=" * 68)
        print(res.stdout + res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
