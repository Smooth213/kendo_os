#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🎨 デザインシステムトークン厳格準拠 ガバナンス監査スクリプト
================================================================================
KendoOS のデザインシステム（AppColors, AppSpacing, AppRadius, AppTypography 等）
への厳格準拠を担保します。UIコンポーネントにおける生カラー定義の禁止や
トークンファイルの整合性を検証します。
"""

import os
import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【ガバナンス監査】🎨 デザインシステムトークン厳格準拠 監査")
    print("=" * 68)

    # 1. check_design_tokens.py --strict の実行
    token_cmd = ["python3", "scripts/check_design_tokens.py", "--strict"]
    token_res = subprocess.run(token_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    # 2. design_token_compliance_governance_test.dart の実行
    test_cmd = ["flutter", "test", "test/governance/design_token_compliance_governance_test.dart"]
    test_res = subprocess.run(test_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    is_ok = (token_res.returncode == 0 and test_res.returncode == 0)

    if is_ok:
        print(" 🟢 適合 (Passed): デザインシステムトークン厳格準拠 監査に合格！")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 違反 (Failed): デザインシステムトークン規約違反が検出されました。")
        if token_res.returncode != 0:
            print(token_res.stdout + token_res.stderr)
        if test_res.returncode != 0:
            print(test_res.stdout + test_res.stderr)
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
