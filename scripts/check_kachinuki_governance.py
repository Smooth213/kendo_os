#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第1条 ガバナンス監査 ⑥】勝ち抜き戦（5人制 / 3人制）選択・適応・実行 総合保証規約
================================================================================
勝ち抜き戦（5人制）および勝ち抜き戦（3人制）が、
1. チーム登録・編集・取り込み・部門別ルール設定の全UI画面で選択できること
2. 基準スロット定義（先鋒・中堅・大将 / 5人制スロット）およびルールモデルに適応されること
3. 試合生成から勝者残留・敗者交代・大将戦決着までのライフサイクルが完全に実行されること
を静的整合性およびテスト実行により保証します。
"""

import os
import subprocess
import sys

TARGET_FILES = [
    "lib/features/tournament/domain/share_import/tournament_team_auto_register_service.dart",
    "lib/features/tournament/domain/share_import/tournament_text_parser_helper.dart",
    "lib/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart",
    "lib/features/tournament/presentation/operate/components/category_rules/category_rule_editor_header_card.dart",
    "lib/features/tournament/presentation/components/kachinuki/kachinuki_bracket_painter.dart",
    "test/governance/kachinuki_selection_and_execution_governance_test.dart",
    "test/governance/kachinuki_bracket_layout_governance_test.dart",
    "test/golden/pixel_kachinuki_bracket_golden_test.dart",
]

REQUIRED_PATTERNS = [
    (
        "lib/features/tournament/domain/share_import/tournament_team_auto_register_service.dart",
        "勝ち抜き戦（5人制）",
        "candidateMatchTypes に 勝ち抜き戦（5人制） が含まれていること",
    ),
    (
        "lib/features/tournament/domain/share_import/tournament_team_auto_register_service.dart",
        "勝ち抜き戦（3人制）",
        "candidateMatchTypes に 勝ち抜き戦（3人制） が含まれていること",
    ),
    (
        "lib/features/tournament/domain/share_import/tournament_team_auto_register_service.dart",
        "勝ち抜き戦（7人制）",
        "candidateMatchTypes に 勝ち抜き戦（7人制） が含まれていること",
    ),
    (
        "lib/features/tournament/domain/share_import/tournament_team_auto_register_service.dart",
        "勝ち抜き戦（それ以上）",
        "candidateMatchTypes に 勝ち抜き戦（それ以上） が含まれていること",
    ),
    (
        "lib/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart",
        "勝ち抜き戦（3人制）",
        "TeamRegistrationCategoryStep の mainMatchTypes に 勝ち抜き戦（3人制） が配置されていること",
    ),
    (
        "lib/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart",
        "勝ち抜き戦（7人制）",
        "TeamRegistrationCategoryStep の extraMatchTypes に 勝ち抜き戦（7人制） が配置されていること",
    ),
    (
        "lib/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart",
        "勝ち抜き戦（それ以上）",
        "TeamRegistrationCategoryStep の extraMatchTypes に 勝ち抜き戦（それ以上） が配置されていること",
    ),
    (
        "lib/features/tournament/presentation/operate/components/category_rules/category_rule_editor_header_card.dart",
        "勝ち抜き戦（3人制）",
        "CategoryRuleEditorHeaderCard のドロップダウンに 勝ち抜き戦（3人制） が配置されていること",
    ),
    (
        "lib/features/tournament/presentation/operate/components/category_rules/category_rule_editor_header_card.dart",
        "勝ち抜き戦（7人制）",
        "CategoryRuleEditorHeaderCard のドロップダウンに 勝ち抜き戦（7人制） が配置されていること",
    ),
    (
        "lib/features/tournament/presentation/operate/components/category_rules/category_rule_editor_header_card.dart",
        "勝ち抜き戦（それ以上）",
        "CategoryRuleEditorHeaderCard のドロップダウンに 勝ち抜き戦（それ以上） が配置されていること",
    ),
    (
        "lib/features/tournament/presentation/components/kachinuki/kachinuki_bracket_painter.dart",
        "const double y3 = 220.0;",
        "KachinukiBracketPainter の表高さがPDF準拠スリム寸法（220.0px）であること",
    ),
    (
        "lib/features/tournament/presentation/components/kachinuki/kachinuki_bracket_painter.dart",
        "KachinukiDrawingHelper.drawTeamNameHorizontal(",
        "KachinukiBracketPainter で横書きチーム名描画が使用されていること",
    ),
]

def main():
    print("=" * 68)
    print(" 🥋 【第1条 ガバナンス監査 ⑥】勝ち抜き戦（5人制 / 3人制）選択・適応・実行 総合保証規約")
    print("=" * 68)

    violations = []

    # 1. 必須ファイルの存在確認
    for path in TARGET_FILES:
        if not os.path.exists(path):
            violations.append(f"❌ 必須ファイルが存在しません: {path}")

    # 2. 必須パターンの検証
    for path, req, desc in REQUIRED_PATTERNS:
        if not os.path.exists(path):
            continue
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        if req not in content:
            violations.append(f"❌ {path}: {desc} ('{req}' が見つかりません)")

    # 3. ガバナンステストの実行検証
    test_paths = [
        "test/governance/kachinuki_selection_and_execution_governance_test.dart",
        "test/governance/kachinuki_bracket_layout_governance_test.dart",
    ]
    for test_path in test_paths:
        if os.path.exists(test_path):
            res = subprocess.run(
                ["python3", "scripts/gov_test_helper.py", test_path],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            if res.returncode != 0:
                violations.append(f"❌ {test_path} の実行に失敗しました:\n{res.stdout}\n{res.stderr}")

    if violations:
        print("🔴 違反が検出されました:")
        for v in violations:
            print(f"  {v}")
        print("=" * 68)
        sys.exit(1)
    else:
        print("🟢 監査合格: 勝ち抜き戦（5人制 / 3人制）選択・適応・実行 総合保証規約に完全適合！")
        print("=" * 68)
        sys.exit(0)

if __name__ == "__main__":
    main()
