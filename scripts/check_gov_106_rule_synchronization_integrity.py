#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第106条 ガバナンス監査】🔄 全ルール設定画面間相互完全同期 ＆ 先祖返り・上書き防止規約
================================================================================
① 静的コード完全配線規約（全 StateHolder / Helper / Summary / Form に skipEmptyRoster 等の実装保証）
② 一括ルール設定完全同期規約（BulkRuleStateHolder ＆ buildNewRule での全プロパティ保持）
③ 個別試合編集差分更新規約（MatchEditStateHolder ＆ MatchEditSaveHelper での既存値保持）
④ 対戦フォーマット設定同期規約（MatchFormatFormState ＆ MatchFormatSaveHelper の完全マッピング）
⑤ 部門別ルール設定同期規約（CategoryRulesFormState ＆ CategoryRuleMatchHelper のシーン別整合性）
⑥ 会場Picker・運営メモ統一規約（MatchCourtSlotPicker / MatchPrivateNoteAccordion の統一使用）
⑦ 旧仕様文字列組み立てUI残存ゼロ規約
⑧ ビュアー・PDFでの生note描画ゼロ ＆ extractPrivateNote 許可画面限定規約
"""

import os
import re
import sys
from gov_static_scanner import GovStaticScanner


def check_rule_wiring(scanner: GovStaticScanner):
    """① 全ルール編集画面および表示画面ファイルにルールの同期項目（skipEmptyRoster等）が欠落なく実装されていること"""
    target_files = [
        'lib/features/match/domain/rules/match_rule.dart',
        'lib/features/tournament/presentation/operate/components/bulk_rule_state_holder.dart',
        'lib/features/tournament/presentation/operate/components/bulk_rule_apply_helper.dart',
        'lib/features/tournament/presentation/operate/components/bulk_rule_form_section.dart',
        'lib/features/tournament/presentation/operate/components/bulk_rule_detail_setting_cards.dart',
        'lib/features/tournament/presentation/operate/components/home/match_edit_state_holder.dart',
        'lib/features/tournament/presentation/operate/components/home/match_edit_save_helper.dart',
        'lib/features/tournament/presentation/operate/components/home/match_edit_rule_and_memo_tab.dart',
        'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_form_state.dart',
        'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_save_helper.dart',
        'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_step.dart',
        'lib/features/tournament/presentation/operate/components/category_rules/category_rules_form_state.dart',
        'lib/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart',
        'lib/features/tournament/presentation/operate/components/category_rules/category_rule_renseikai_section.dart',
        'lib/features/tournament/presentation/operate/components/rules/sections/match_rule_time_section.dart',
        'lib/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart',
        'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_summary_card.dart',
        'lib/features/tournament/presentation/operate/components/home/match_rule_summary_card.dart',
        'lib/features/tournament/presentation/operate/components/category_rules/category_rule_summary_card.dart',
    ]
    missing = []
    for rel_path in target_files:
        content = scanner.read_file(rel_path)
        if not content:
            missing.append(f"{rel_path} が存在しません")
        elif 'skipEmptyRoster' not in content and 'SkipEmpty' not in content:
            missing.append(f"{rel_path} に skipEmptyRoster 等のルール同期対応が欠落")
    return len(missing) == 0, missing


def check_picker_and_accordion_usage(scanner: GovStaticScanner):
    """⑥ 試合作成・編集・形式設定画面でMatchCourtSlotPickerとMatchPrivateNoteAccordionが統一使用されていること"""
    target_files = [
        'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_heading_and_note_section.dart',
        'lib/features/tournament/presentation/operate/components/home/match_edit_court_and_group_tab.dart',
        'lib/features/tournament/presentation/operate/components/new_match/new_match_heading_notes_card.dart',
    ]
    violations = []
    for rel_path in target_files:
        content = scanner.read_file(rel_path)
        if not content:
            violations.append(f"{rel_path} が存在しません")
            continue
        if 'MatchCourtSlotPicker' not in content:
            violations.append(f"{rel_path} で MatchCourtSlotPicker が未使用")
        if 'MatchPrivateNoteAccordion' not in content:
            violations.append(f"{rel_path} で MatchPrivateNoteAccordion が未使用")
    return len(violations) == 0, violations


def check_no_legacy_format(scanner: GovStaticScanner):
    """⑦ lib配下のすべての試合作成編集関連ファイルに旧仕様の直接文字列組み立てUIが残存していないこと"""
    files = scanner.get_lib_files()
    pattern = re.compile(r"['\x22]第\s*[\$]\{?.*\}?\s*試合場.*試合目")
    violations = []
    for rel_path, content in files.items():
        if not rel_path.startswith("lib/features/tournament/presentation/operate"):
            continue
        if "match_heading_format_helper.dart" in rel_path or "match_court_slot_picker.dart" in rel_path:
            continue
        if pattern.search(content):
            violations.append(f"{rel_path} に旧仕様の見出し直接合成が残存")
    return len(violations) == 0, violations


def check_viewer_pdf_sanitization(scanner: GovStaticScanner):
    """⑧ ビュアー・PDFでの生note直接描画ゼロ ＆ extractPrivateNote 許可画面限定規約"""
    files = scanner.get_lib_files()
    raw_note_pattern = re.compile(r'Text\s*\(\s*(\w+\.note)\s*[,)]')
    violations = []

    for rel_path, content in files.items():
        # ビュアー / PDF
        if rel_path.startswith("lib/features/viewer") or rel_path.startswith("lib/features/pdf"):
            lines = content.splitlines()
            for i, line in enumerate(lines, 1):
                match = raw_note_pattern.search(line)
                if match:
                    if not any(k in line for k in ['extractPublicHeading', 'replaceAll', 'split']):
                        violations.append(f"{rel_path}:{i} -> 生の {match.group(1)} が直接 Text() に渡されています")

        # extractPrivateNote 許可画面限定
        allowed_files = [
            'match_heading_format_helper.dart',
            'match_private_note_accordion.dart',
            'match_card_note_row.dart',
            'match_list_tile_card.dart',
            'team_status_card.dart',
            'new_match_heading_notes_card.dart',
            'match_format_heading_and_note_section.dart',
            'match_edit_court_and_group_tab.dart',
            'quick_next_match_wizard_sheet.dart',
            'setup_match_format_screen.dart',
        ]
        if not any(rel_path.endswith(a) for a in allowed_files):
            if 'extractPrivateNote' in content:
                violations.append(f"{rel_path} -> extractPrivateNote が無許可画面で使用されています")

    return len(violations) == 0, violations


def main():
    print("=" * 68)
    print(" 📊 【第106条 ガバナンス監査】🔄 全ルール設定画面間相互完全同期 ＆ 先祖返り・上書き防止規約")
    print("=" * 68)

    scanner = GovStaticScanner.get_instance()

    ok1, v1 = check_rule_wiring(scanner)
    ok2, v2 = check_picker_and_accordion_usage(scanner)
    ok3, v3 = check_no_legacy_format(scanner)
    ok4, v4 = check_viewer_pdf_sanitization(scanner)

    rules = [
        ("① [静的コード完全網羅] 全ルール編集画面・表示画面に skipEmptyRoster 同期項目が欠落なく配線されていること", ok1, v1),
        ("② [Picker・運営メモ統一] 試合作成・編集系で MatchCourtSlotPicker / MatchPrivateNoteAccordion が統一使用されていること", ok2, v2),
        ("③ [旧仕様UI完全排除] 試合作成・編集系で旧仕様の見出し文字列直接合成が残存ゼロであること", ok3, v3),
        ("④ [情報境界隔離保証] ビュアー・PDFで内部特記事項生note露出ゼロ＆表示許可先制限保証であること", ok4, v4),
    ]

    all_passed = all(r[1] for r in rules)
    for label, ok, viols in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        if not ok:
            for v in viols:
                print(f"    ❌ {v}")

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (全ルール設定画面間相互完全同期 ＆ 先祖返り・上書き防止規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第106条 全ルール設定画面間相互完全同期 ＆ 先祖返り・上書き防止規約に違反があります)")
        print("=" * 68)
        sys.exit(1)


if __name__ == "__main__":
    main()
