#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第5条 第4項 ガバナンス監査】
入力フォーカス時ビューポート安定性・跳ね上がり防止保証規約
================================================================================
ソフトウェアキーボード表示時に入力欄やダイアログが画面外へ跳ね上がる現象を
恒久的に根絶するため、以下の3大規約を静的コード解析により厳密に検証します：

1. 【基盤統一TextField】AppTextField のデフォルト scrollPadding が EdgeInsets.zero であること
2. 【全入力フィールド共通】lib/ 配下のすべての TextField / TextFormField は AppTextField であるか、または scrollPadding: EdgeInsets.zero が明示されていること
3. 【フォームモーダル統一】主要入力モーダルが showAppDialog ではなく showAppBottomSheet (isScrollControlled: true) を使用していること
"""

import os
import re
import sys

def check_app_text_field_scroll_padding():
    """AppTextField のデフォルト scrollPadding が EdgeInsets.zero であることを検証"""
    target = "lib/shared/widgets/app_text_field.dart"
    if not os.path.exists(target):
        return False, f"❌ {target} が存在しません"

    with open(target, "r", encoding="utf-8") as f:
        content = f.read()

    if "this.scrollPadding = EdgeInsets.zero" not in content:
        return False, f"❌ {target} のデフォルト scrollPadding が EdgeInsets.zero に設定されていません"

    return True, "🟢 AppTextField のデフォルト scrollPadding は EdgeInsets.zero に設定されています"

def check_modal_input_bottom_sheet():
    """主要な入力モーダルが showAppDialog ではなく showAppBottomSheet を利用していることを検証"""
    targets = [
        ("lib/features/tournament/presentation/operate/components/timeline/timeline_unified_announce_dialog.dart", "アナウンス一斉発信"),
        ("lib/features/tournament/presentation/operate/components/timeline/timeline_edit_comment_dialog.dart", "コメント編集"),
        ("lib/shared/widgets/room_join_qr_dialog.dart", "道場ID入力"),
        ("lib/admin/presentation/components/master_player_edit_bottom_sheet.dart", "選手マスタ登録"),
    ]

    errors = []
    for path, name in targets:
        if not os.path.exists(path):
            errors.append(f"❌ {path} ({name}) が存在しません")
            continue

        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        if "showAppDialog(" in content:
            errors.append(f"❌ {path} ({name}) で showAppDialog が使われています。跳ね上がり防止のため showAppBottomSheet を使用してください")

        if "showAppBottomSheet(" not in content:
            errors.append(f"❌ {path} ({name}) で showAppBottomSheet が使われていません")

        if "isScrollControlled: true" not in content:
            errors.append(f"❌ {path} ({name}) で isScrollControlled: true が設定されていません")

    if errors:
        return False, "\n".join(errors)
    return True, "🟢 主要入力モーダルはすべて showAppBottomSheet (isScrollControlled: true) に統一されています"

def check_all_text_fields_scroll_padding_zero():
    """lib/配下のすべての TextField / TextFormField が scrollPadding: EdgeInsets.zero を保証しているか検証"""
    allowlist = {
        "lib/shared/widgets/app_text_field.dart",  # AppTextField 自身
        "lib/features/p2p/presentation/assets/web_viewer_html.dart",  # HTML文字列内
    }

    errors = []
    for root, _, files in os.walk("lib"):
        for file in files:
            if not file.endswith(".dart"):
                continue
            path = os.path.join(root, file)
            if path in allowlist or path.endswith(".freezed.dart") or path.endswith(".g.dart"):
                continue

            with open(path, "r", encoding="utf-8") as f:
                content = f.read()

            # TextField( または TextFormField( を検出
            # ただし AppTextField( は除外
            matches = list(re.finditer(r'(?<!App)\b(TextField|TextFormField)\s*\(', content))
            if not matches:
                continue

            # 各マッチの後に scrollPadding: EdgeInsets.zero が存在するかスコープ検査
            for m in matches:
                start_idx = m.start()
                # 括弧の終わりまたは次の30行程度を取得
                snippet = content[start_idx:start_idx + 800]
                if "scrollPadding: EdgeInsets.zero" not in snippet:
                    line_num = content[:start_idx].count("\n") + 1
                    errors.append(
                        f"❌ {path}:{line_num} で生の {m.group(1)} が使用されていますが、"
                        "scrollPadding: EdgeInsets.zero が明示されていません (AppTextField を使用するか scrollPadding: EdgeInsets.zero を指定してください)"
                    )

    if errors:
        return False, "\n".join(errors)
    return True, "🟢 lib/ 配下の全入力フィールドで scrollPadding: EdgeInsets.zero または AppTextField が100%保証されています"

def main():
    print("=" * 72)
    print(" 🥋 【第5条 第4項 ガバナンス監査】入力フォーカス時ビューポート安定性・跳ね上がり防止保証")
    print("=" * 72)

    checks = [
        ("1. AppTextField scrollPadding ゼロ設定検証", check_app_text_field_scroll_padding),
        ("2. 全入力フィールド scrollPadding ゼロ保証検証", check_all_text_fields_scroll_padding_zero),
        ("3. 主要入力モーダルのボトムシート＆キーボード追従構造検証", check_modal_input_bottom_sheet),
    ]

    all_passed = True
    for title, check_fn in checks:
        print(f"\n🔍 実行中: {title}")
        passed, msg = check_fn()
        print(f" {msg}")
        if not passed:
            all_passed = False

    print("\n" + "-" * 72)
    if all_passed:
        print(" 🟢 監査結果: 合格 (入力フォーカス時ビューポート安定性・跳ね上がり防止規約に完全適合！)")
        print("=" * 72)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (入力フォーカス時ビューポート安定性・跳ね上がり防止規約に違反があります)")
        print("=" * 72)
        sys.exit(1)

if __name__ == "__main__":
    main()
