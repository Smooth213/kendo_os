#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🌐 Web境界全走査・ネイティブ直接import遮断 ガバナンス監査スクリプト（第5条拡充）
================================================================================
Web/PWAの安定稼働を100%保証するため、lib/ 配下のDartファイルを走査対象とし、
Web環境で動作するコードへのネイティブ専用ライブラリ（dart:io, dart:ffi 等）の
直接import混入を完全検知・遮断します。
"""

import os
import re
import sys

# ネイティブ専用であることが設計上保証されている特定ファイル群の明示的許可リスト
NATIVE_ONLY_ALLOWLIST = {
    "lib/shared/platform/platform_file_io.dart",
    "lib/shared/infrastructure/persistence/twin_match_persistence_helper.dart",
    "lib/shared/infrastructure/repository/local_match_repository.dart",
    "lib/shared/infrastructure/repository/local_match_emergency_backup.dart",
    "lib/shared/infrastructure/repository/program_repository.dart",
    "lib/shared/infrastructure/repository/sync_engine.dart",
    "lib/shared/infrastructure/services/manual_download_service.dart",
    "lib/shared/infrastructure/services/manual_print_share_service.dart",
    "lib/shared/errors/emergency_crash_preserver.dart",
    "lib/shared/utils/payload_compression_helper.dart",
    "lib/admin/presentation/components/master_data_cleanup_dialog.dart",
    "lib/features/p2p/infrastructure/local_p2p_broadcaster.dart",
    "lib/features/pdf/pdf_service.dart",
    "lib/features/tournament/presentation/components/manual/manual_full_manual_tab_view.dart",
    "lib/shared/presentation/screens/embedded_manual_tab_views.dart",
    "lib/features/tournament/presentation/components/program_management/program_title_preview_dialog.dart",
    "lib/features/tournament/presentation/operate/helpers/clipboard_program_helper.dart",
    "lib/features/tournament/presentation/operate/screens/program_management_screen.dart",
    "lib/features/tournament/presentation/operate/providers/sync_backup_helper.dart",
    "lib/shared/presentation/screens/embedded_manual_screen.dart",
}

FORBIDDEN_IMPORTS = [
    ("dart:io", re.compile(r"import\s+['\"]dart:io['\"]")),
    ("dart:ffi", re.compile(r"import\s+['\"]dart:ffi['\"]")),
]

def check_isolation():
    violations = []
    base_dir = "lib"

    if not os.path.exists(base_dir):
        return violations

    for root, _, files in os.walk(base_dir):
        for file in files:
            if file.endswith(".dart"):
                raw_path = os.path.join(root, file)
                normalized_path = raw_path.replace("\\", "/")
                
                # ネイティブ専用許可ファイルはスキップ
                if normalized_path in NATIVE_ONLY_ALLOWLIST:
                    continue

                with open(raw_path, "r", encoding="utf-8") as f:
                    content = f.read()
                    for lib_name, pattern in FORBIDDEN_IMPORTS:
                        if pattern.search(content):
                            violations.append((normalized_path, lib_name))

    return violations

def main():
    print("=" * 68)
    print(" 📊 【ガバナンス第5条拡充】🌐 Web境界全走査・ネイティブ直接import遮断 監査")
    print("=" * 68)

    violations = check_isolation()

    if not violations:
        print(" 🟢 適合 (Passed): lib/ 配下の全Web稼働コードにおいてネイティブ直接import混入ゼロを確認！")
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
