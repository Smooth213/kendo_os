#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第201条 ガバナンス監査】🔒 セキュリティ・権限ロール ＆ マルチテナント空間隔離規約
================================================================================
① セキュリティ＆ロール露出規制（管理機能・PIN保護）
② マルチテナント道場・大会空間 隔離規約（dojoId / tournamentId 漏洩防止）
"""

import subprocess
import sys

SUB_AUDITS = [
    ("① セキュリティ＆ロール露出規制規約", ["python3", "scripts/check_security_governance.py"]),
    ("② マルチテナント道場・大会空間 隔離規約", ["python3", "scripts/check_tenant_isolation_governance.py"]),
    ("③ Firestore セキュリティルール＆ロール権限規約", ["python3", "scripts/check_firestore_rules_governance.py"]),
    ("④ ロール権限一元統治 ＆ ハードコードロール比較完全排除規約", ["python3", "scripts/gov_test_helper.py", "test/governance/role_permissions_centralized_governance_test.dart"]),
    ("⑤ セキュリティガード網羅的アクセス制御 ＆ 空間隔離保証規約", ["python3", "scripts/gov_test_helper.py", "test/governance/security_guards_access_control_governance_test.dart"]),
    ("⑥ マスター組織登録 ＆ 道場空間完全分離規約", ["python3", "scripts/gov_test_helper.py", "test/governance/master_organization_tenancy_governance_test.dart"]),
]

def main():
    print("=" * 68)
    print(" 📊 【第201条 ガバナンス監査】🔒 セキュリティ・権限ロール ＆ マルチテナント空間隔離規約")
    print("=" * 68)

    all_passed = True
    for label, cmd in SUB_AUDITS:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        is_ok = (res.returncode == 0)
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        if not is_ok:
            all_passed = False
            print(f"\n--- [詳細エラー: {label}] ---")
            print(res.stdout + res.stderr)
            print("-" * 40)

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (セキュリティ・権限ロール ＆ マルチテナント空間隔離規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第201条 セキュリティ・権限ロール ＆ マルチテナント空間隔離規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
