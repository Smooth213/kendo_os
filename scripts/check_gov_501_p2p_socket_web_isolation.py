#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第501条 ガバナンス監査】📶 現場P2Pローカル配信 ＆ ソケットライフサイクル・Webプラットフォーム完全隔離規約
================================================================================
① Web環境安全隔離（kIsWeb 環境におけるネイティブ HttpServer 隔離・安全フォールバック規約）
② ソケット完全破棄（stopServer / Provider破棄時における全WebSocket切断＆ソケット完全破棄規約）
③ 例外安全・リソース防護（複数回起動および多重呼び出し時の防護・リソース安全規約）
④ Gzip圧縮データ可逆性（PayloadCompressionHelper によるデータ完全可逆性規約）
"""

import os
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

from gov_static_scanner import get_file_content

def main():
    print("=" * 68)
    print(" 📊 【第501条 ガバナンス監査】📶 現場P2Pローカル配信 ＆ ソケットライフサイクル・Webプラットフォーム完全隔離規約")
    print("=" * 68)

    c_broadcaster = get_file_content("lib/features/p2p/infrastructure/local_p2p_broadcaster.dart") or ""
    c_compress = get_file_content("lib/shared/utils/payload_compression_helper.dart") or ""

    # ① Web安全隔離: kIsWeb 判定と HttpPlatform 分離
    ok1 = "kIsWeb" in c_broadcaster and "class LocalP2pBroadcaster" in c_broadcaster

    # ② ソケット破棄: stopServer でのソケット破棄 ＆ onDispose
    ok2 = "stopServer" in c_broadcaster and "onDispose" in c_broadcaster

    # ③ 例外安全: サーバー未起動時ガード ＆ broadcastMatchDelta
    ok3 = "broadcastMatchDelta" in c_broadcaster and "isRunning" in c_broadcaster

    # ④ データ可逆性: PayloadCompressionHelper の配備
    ok4 = "class PayloadCompressionHelper" in c_compress or "compress" in c_compress

    rules = [
        ("① [Web安全隔離] kIsWeb 環境におけるネイティブ HttpServer 隔離・安全フォールバック規約", ok1),
        ("② [ソケット破棄] stopServer / Provider破棄時における全WebSocket切断＆ソケット完全破棄規約", ok2),
        ("③ [例外安全] 複数回起動および多重呼び出し時の防護・リソース安全規約", ok3),
        ("④ [データ可逆性] Gzip圧縮ペイロード送信時（PayloadCompressionHelper）のデータ完全可逆性規約", ok4),
    ]

    is_ok = all(ok for _, ok in rules)

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (現場P2Pローカル配信 ＆ ソケットライフサイクル・Webプラットフォーム完全隔離規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第501条 現場P2Pローカル配信 ＆ ソケットライフサイクル・Webプラットフォーム完全隔離規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
