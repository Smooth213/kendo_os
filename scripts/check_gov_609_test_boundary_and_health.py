#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第609条 ガバナンス監査】🧪 静的・動的テスト責務分離境界 ＆ テストスイート健全性完全保証規約
================================================================================
【目的】
kendo OS のテストスイート（全1,000+ファイル・3,300+テスト）において、
① 静的テストと動的テストの責務境界（静的解析の Dart 逆流ゼロ）
② テストスキップ放置の完全排除（skip: true ゼロ）
③ 同期スリープによるハング・タイムアウト誘発の完全排除（sleep(Duration) ゼロ）
④ アサーション欠落・空テストの完全排除（expect/verify 必須化）
⑤ 無制限 pumpAndSettle() による10分ハング・フレーキー化の完全排除（safePumpAndSettle 必須化）
を自動監査し、テスト全体の健全性と高速性を恒久的に保証します。
"""

import os
import re
import sys
from typing import Dict, List, Tuple
from gov_static_scanner import GovStaticScanner


def check_no_test_skips(scanner: GovStaticScanner) -> Tuple[bool, List[str]]:
    """② テストスキップ放置ゼロ規約 (skip: true, test.skip, @Skip)"""
    test_files = scanner.get_test_files()
    violations = []

    skip_pattern = re.compile(r'\bskip:\s*(true|["\'][^"\']+["\'])|\btest\.skip\b|@Skip\(')

    for rel_path, content in test_files.items():
        lines = content.splitlines()
        for idx, line in enumerate(lines, 1):
            # コメントアウトされた行は無視
            stripped = line.strip()
            if stripped.startswith("//") or stripped.startswith("*"):
                continue
            if skip_pattern.search(line):
                violations.append(f"{rel_path}:{idx} - スキップが設定されています: {stripped}")

    return len(violations) == 0, violations


def check_no_sync_sleep(scanner: GovStaticScanner) -> Tuple[bool, List[str]]:
    """③ 同期スリープ・ハング誘発完全排除規約 (sleep(Duration))"""
    test_files = scanner.get_test_files()
    violations = []

    # dart:io の sleep(Duration(...)) を検出 (tester.pump / fakeAsync / Future.delayed は許可)
    sleep_pattern = re.compile(r'\bsleep\s*\(\s*Duration\(')

    for rel_path, content in test_files.items():
        lines = content.splitlines()
        for idx, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith("//") or stripped.startswith("*"):
                continue
            if sleep_pattern.search(line):
                violations.append(
                    f"{rel_path}:{idx} - 同期 sleep が使用されています (tester.pump または Future.delayed を使用してください): {stripped}"
                )

    return len(violations) == 0, violations


def check_no_empty_assertions(scanner: GovStaticScanner) -> Tuple[bool, List[str]]:
    """④ アサーション欠落・空テスト完全検知規約"""
    test_files = scanner.get_test_files()
    violations = []

    # test( または testWidgets( を検出
    test_decl_pattern = re.compile(r'\b(test|testWidgets)\s*\(\s*["\']([^"\']+)["\']\s*,\s*(\([^)]*\)\s*(async\s*)?{)')
    assertion_pattern = re.compile(
        r'\b(expect\w*|verify\w*|assert\w*|_expect\w*|_verify\w*|testWidgetWith\w*|pumpAndVerify\w*|fail)\b'
    )

    for rel_path, content in test_files.items():
        # 単純な走査: 各テスト関数ブロック内にアサーションが存在するか
        matches = list(test_decl_pattern.finditer(content))
        for i, match in enumerate(matches):
            test_name = match.group(2)
            start_pos = match.end()
            # 次のテスト宣言またはファイル末尾までをテストボディとみなす
            end_pos = matches[i + 1].start() if i + 1 < len(matches) else len(content)
            body = content[start_pos:end_pos]

            if not assertion_pattern.search(body):
                # 宣言の行番号を算出
                line_no = content[:match.start()].count("\n") + 1
                violations.append(
                    f"{rel_path}:{line_no} - テスト '{test_name}' 内に expect / verify アサーションが存在しません"
                )

    return len(violations) == 0, violations


def check_static_dynamic_separation_boundary(scanner: GovStaticScanner) -> Tuple[bool, List[str]]:
    """① 静的解析 Dart 逆流ゼロ規約 (新設テストでのプロダクションコード全走査アンチパターン防止)"""
    test_files = scanner.get_test_files()
    violations = []

    # プロダクションコード (lib/) を直接走査するパターンの検出
    # File('lib/...').readAsStringSync() や Directory('lib').listSync()
    lib_scan_pattern = re.compile(r'Directory\s*\(\s*[\'\"]lib[\'\"]\s*\)|File\s*\(\s*[\'\"]lib/[^\'\"]+[\'\"]\s*\)\s*\.readAs')

    # 既存の残存レガシーテスト（今後のリファクタリング対象）はホワイトリストで管理し、新規混入を厳格遮断
    KNOWN_LEGACY_ALLOWLIST = {
        "test/unit/domain/no_hardcoded_specific_names_test.dart",
        "test/unit/security/firestore_rules_governance_test.dart",
        "test/unit/security/storage_rules_governance_test.dart",
        "test/governance/web_browser_optimization_governance_test.dart",
        "test/governance/role_permissions_centralized_governance_test.dart",
        "test/governance/event_history_partition_governance_test.dart",
        "test/governance/bunaiksen_dock_isolation_governance_test.dart",
        "test/governance/security_guards_access_control_governance_test.dart",
        "test/governance/match_calculator_governance_test.dart",
        "test/governance/floating_dock_lifecycle_governance_test.dart",
        "test/governance/router_fallback_access_denied_governance_test.dart",
        "test/governance/mounted_safety_governance_test.dart",
        "test/governance/dock_slot_layout_governance_test.dart",
        "test/governance/text_scale_overflow_governance_test.dart",
        "test/governance/tournament_edit_sheet_governance_test.dart",
        "test/governance/kachinuki_bracket_layout_governance_test.dart",
        "test/governance/dock_subsheet_and_navigation_governance_test.dart",
        "test/governance/master_organization_tenancy_governance_test.dart",
        "test/governance/web_native_isolation_governance_test.dart",
        "test/governance/team_match_order_governance_test.dart",
        "test/governance/bottom_sheet_keyboard_tracking_governance_test.dart",
        "test/governance/route_guard_integrity_governance_test.dart",
        "test/governance/share_url_governance_test.dart",
        "test/governance/dock_timer_input_parity_governance_test.dart",
        "test/governance/cross_platform_parity_governance_test.dart",
        "test/governance/input_viewport_stability_governance_test.dart",
        "test/governance/screens_and_bottom_sheets_governance_test.dart",
        "test/governance/projection_updater_memory_leak_governance_test.dart",
        "test/governance/band_live_integration_governance_test.dart",
        "test/widget/features/bunaiksen/bunaiksen_dock_button_test.dart",
        "test/widget/features/dock/viewer_no_dock_governance_test.dart",
        "test/unit/repositories/isar_integer_safety_test.dart",
        "test/widget/features/bunaiksen/bunaiksen_score_screen_integration_test.dart",
        "test/widget/features/match/match_screen_test.dart",
        "test/unit/crdt/web_pwa_touch_sync_governance_test.dart",
    }

    for rel_path, content in test_files.items():
        if rel_path in KNOWN_LEGACY_ALLOWLIST:
            continue

        lines = content.splitlines()
        for idx, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith("//") or stripped.startswith("*"):
                continue
            if lib_scan_pattern.search(line):
                violations.append(
                    f"{rel_path}:{idx} - 新規テスト内でプロダクションコード (lib/) の直接ファイル走査が検出されました (静的解析は Python ガバナンス法典 GovStaticScanner で実装してください): {stripped}"
                )

    return len(violations) == 0, violations


def check_no_unbounded_pump_and_settle(scanner: GovStaticScanner) -> Tuple[bool, List[str]]:
    """⑤ [無制限待機排除規約] 引数なし pumpAndSettle() ゼロ保証 (safePumpAndSettle または pump を使用)"""
    test_files = scanner.get_test_files()
    violations = []
    pattern = re.compile(r'\bpumpAndSettle\s*\(\s*\)')

    for rel_path, content in test_files.items():
        lines = content.splitlines()
        for idx, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith("//") or stripped.startswith("*"):
                continue
            if pattern.search(line):
                violations.append(
                    f"{rel_path}:{idx} - 引数なし pumpAndSettle() が検出されました (10分ハング防止のため safePumpAndSettle() または tester.pump() を使用してください): {stripped}"
                )

    return len(violations) == 0, violations


def main():
    print("=" * 68)
    print(" 📊 【第609条 ガバナンス監査】🧪 静的・動的テスト責務分離境界 ＆ テストスイート健全性完全保証規約")
    print("=" * 68)

    scanner = GovStaticScanner.get_instance()

    ok1, v1 = check_static_dynamic_separation_boundary(scanner)
    ok2, v2 = check_no_test_skips(scanner)
    ok3, v3 = check_no_sync_sleep(scanner)
    ok4, v4 = check_no_empty_assertions(scanner)
    ok5, v5 = check_no_unbounded_pump_and_settle(scanner)

    rules = [
        ("① [責務分離境界] 静的解析 Dart 逆流ゼロ ＆ プロダクション直接走査新設完全禁止規約", ok1, v1),
        ("② [スキップ排除] テストスキップ放置（skip: true）ゼロ規約", ok2, v2),
        ("③ [ハング防止] 同期 sleep(Duration) によるブロッキング完全排除規約", ok3, v3),
        ("④ [テスト有効性] アサーション欠落・空テスト完全検知規約", ok4, v4),
        ("⑤ [無制限待機排除] 引数なし pumpAndSettle() による10分ハング完全排除規約", ok5, v5),
    ]

    all_passed = all(r[1] for r in rules)
    for label, ok, viols in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        if not ok:
            for v in viols[:5]:
                print(f"    ❌ {v}")
            if len(viols) > 5:
                print(f"    ... 他 {len(viols) - 5} 件")

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (静的・動的テスト責務分離境界 ＆ テストスイート健全性規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (テスト責務分離またはテストスイート健全性に違反が検出されました)")
        print("=" * 68)
        sys.exit(1)


if __name__ == "__main__":
    main()
