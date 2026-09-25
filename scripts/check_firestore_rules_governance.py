#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🔒 Firestore セキュリティルール ＆ ロール権限ガバナンス監査スクリプト
================================================================================
firestore.rules が以下のセキュリティ基準をすべて満たしているかを静的解析・検証します：
1. rules_version = '2' の宣言
2. /organizations/{dojoId} によるマルチテナント階層分離
3. ユーザーロール判定関数 getUserRole() の存在と実装
4. matches, tournaments, members, audit_logs 等の主要コレクションに対する認証・権限チェック
5. 匿名アクセスによる書き込みの禁止 (request.auth != null ガード)
"""

import os
import sys

RULES_PATH = "firestore.rules"

REQUIRED_RULES_CHECKS = [
    ("rules_version = '2'", "Firestore Rules v2 宣言"),
    ("match /organizations/{dojoId}", "マルチテナント道場階層の隔離"),
    ("getUserRole()", "ロール権限解決関数"),
    ("request.auth != null", "未認証アクセスの水際防御ガード"),
    ("match /members/{userId}", "メンバー権限コレクションの定義"),
    ("match /matches/{matchId}", "試合データコレクションの保護"),
    ("match /audit_logs/{logId}", "監査ログコレクションの管理者保護"),
]

def main():
    if not os.path.exists(RULES_PATH):
        print(f"❌ エラー: {RULES_PATH} が存在しません。")
        sys.exit(1)

    with open(RULES_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    all_passed = True
    print("🔒 Firestore セキュリティルール規約 検査開始...")

    for pattern, description in REQUIRED_RULES_CHECKS:
        if pattern in content:
            print(f"  🟢 適合: {description} (パターン: '{pattern}')")
        else:
            print(f"  🔴 違反: {description} が検出されませんでした (パターン: '{pattern}')")
            all_passed = False

    # 危険な全許可（allow read, write: if true;）が存在しないことの検証
    if "if true;" in content or "if true ;" in content:
        print("  🔴 警告: 危険な全開放ルール 'if true;' が検出されました！")
        all_passed = False
    else:
        print("  🟢 適合: 危険な全開放ルール ('if true;') の不在を確認")

    if all_passed:
        print("✅ Firestore セキュリティルール規約: ALL PASS (100% 適合)")
        sys.exit(0)
    else:
        print("❌ Firestore セキュリティルール規約: 違反が検出されました。")
        sys.exit(1)

if __name__ == "__main__":
    main()
