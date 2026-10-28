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

    # 2. app_tokens.dart 基幹クラス整合性の直接検証 (Python自前検証)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    token_path = os.path.join(os.path.dirname(script_dir), "lib/shared/theme/app_tokens.dart")
    token_classes_ok = True
    token_errors = []

    if not os.path.isfile(token_path):
        token_classes_ok = False
        token_errors.append(f"❌ app_tokens.dart が存在しません: {token_path}")
    else:
        with open(token_path, "r", encoding="utf-8") as f:
            content = f.read()
        for required_class in ["class AppSpacing", "class AppRadius", "class AppFontSize", "class AppEdgeInsets", "class AppSemanticTokens"]:
            if required_class not in content:
                token_classes_ok = False
                token_errors.append(f"❌ 必須トークンクラスが未定義です: {required_class}")

    is_ok = (token_res.returncode == 0 and token_classes_ok)

    if is_ok:
        print(" 🟢 適合 (Passed): デザインシステムトークン厳格準拠 監査に合格！")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 違反 (Failed): デザインシステムトークン規約違反が検出されました。")
        if token_res.returncode != 0:
            print(token_res.stdout + token_res.stderr)
        if not token_classes_ok:
            for err in token_errors:
                print(err)
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
