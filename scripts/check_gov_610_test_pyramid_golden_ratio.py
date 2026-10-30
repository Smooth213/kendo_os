#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第610条 ガバナンス監査】⚖️ テストピラミッド黄金比 ＆ 資産構造維持規約
================================================================================
【目的】
kendo OS の全テスト資産において、テストピラミッドの真の黄金比率
（Unit土台 ＞ Widget ＞ Integration ＞ E2E頂点厳選）と資産構造を自動監査し、
名実一致（抜け穴の完全排除）と健全な開発サイクルを恒久的に固定化・保証します。

【監査基準】:
① [Unit比率規約] 単体テスト比率 42.0% 以上保持規約（土台の強固さ）
② [Widget比率規約] UIコンポーネントテスト比率 42.0% 以下維持規約（実態統合＆UI過剰肥大防止）
③ [Integration比率規約] ヘッドレス結合テスト比率 3.0%〜8.0% 維持規約（業務シナリオ網羅性）
④ [E2E比率規約] 現場UI結合E2Eテスト比率 3.0% 以下維持規約（頂点厳選・不安定要素排除）
⑤ [Others排除規約] 分類外（その他）テスト 5件以下（目標0件）維持規約（構造明瞭性）
⑥ [資産保護＆Goldenスリム化規約] ガバナンステスト（45件以上保護）＆ Goldenテスト（10件以下厳選）
⑦ [セマンティック内容規約] E2EへのUIテスト強制 ＆ Integrationへのヘッドレス強制（抜け穴完全封鎖）
================================================================================
"""

import os
import sys
from typing import Dict, List, Tuple


def scan_test_assets() -> Dict[str, List[str]]:
    """test/ 配下の全テストファイルをレイヤー別に分類スキャンする"""
    categories: Dict[str, List[str]] = {
        'unit': [],
        'widget': [],
        'governance': [],
        'integration': [],
        'golden': [],
        'e2e': [],
        'others': [],
    }

    test_dir = 'test'
    if not os.path.exists(test_dir):
        return categories

    for root, _, files in os.walk(test_dir):
        for f in files:
            if f.endswith('_test.dart'):
                full_path = os.path.join(root, f)
                rel_path = os.path.relpath(full_path, test_dir)
                first_dir = rel_path.split(os.sep)[0]

                if first_dir in ('unit', 'widget', 'governance', 'integration', 'e2e'):
                    categories[first_dir].append(rel_path)
                elif first_dir.startswith('golden'):
                    categories['golden'].append(rel_path)
                else:
                    categories['others'].append(rel_path)

    return categories


def check_unit_ratio(categories: Dict[str, List[str]], total: int) -> Tuple[bool, List[str]]:
    """① [Unit比率規約] 単体テスト比率 42.0% 以上保持規約"""
    unit_count = len(categories['unit'])
    pct = (unit_count / total * 100) if total > 0 else 0
    passed = pct >= 42.0
    msgs = [f"Unitテスト: {unit_count} 件 ({pct:.1f}%) / 基準: 42.0% 以上"]
    if not passed:
        msgs.append("Unitテスト比率が基準を下回っています。ドメイン・ロジック層のUnitテストを拡充してください。")
    return passed, msgs


def check_widget_ratio(categories: Dict[str, List[str]], total: int) -> Tuple[bool, List[str]]:
    """② [Widget比率規約] UIコンポーネントテスト比率 42.0% 以下維持規約"""
    widget_count = len(categories['widget'])
    pct = (widget_count / total * 100) if total > 0 else 0
    passed = pct <= 42.0
    msgs = [f"Widgetテスト: {widget_count} 件 ({pct:.1f}%) / 基準: 42.0% 以下"]
    if not passed:
        msgs.append("Widgetテスト比率が過剰です。UIテストの過度な細分化を抑制し、小コンポーネントは親コンポーネントへ集約してください。")
    return passed, msgs


def check_integration_ratio(categories: Dict[str, List[str]], total: int) -> Tuple[bool, List[str]]:
    """③ [Integration比率規約] ヘッドレス結合テスト比率 3.0%〜8.0% 維持規約"""
    int_count = len(categories['integration'])
    pct = (int_count / total * 100) if total > 0 else 0
    passed = 3.0 <= pct <= 8.0
    msgs = [f"Integrationテスト: {int_count} 件 ({pct:.1f}%) / 基準: 3.0% 〜 8.0%"]
    if not passed:
        if pct < 3.0:
            msgs.append("Integrationテスト比率が不足しています。複数サービス結合シナリオを適切に維持してください。")
        else:
            msgs.append("Integrationテストが過剰肥大化しています。単体テスト層への責務移譲を検討してください。")
    return passed, msgs


def check_e2e_ratio(categories: Dict[str, List[str]], total: int) -> Tuple[bool, List[str]]:
    """④ [E2E比率規約] 現場UI結合E2Eテスト比率 3.0% 以下維持規約（頂点厳選）"""
    e2e_count = len(categories['e2e'])
    pct = (e2e_count / total * 100) if total > 0 else 0
    passed = pct <= 3.0
    msgs = [f"E2Eテスト: {e2e_count} 件 ({pct:.1f}%) / 基準: 3.0% 以下（厳格上限）"]
    if not passed:
        msgs.append("E2Eテスト比率が過剰です。真のUI結合操作フローのみを厳選し、ヘッドレス結合は integration/ へ移譲してください。")
    return passed, msgs


def check_others_count(categories: Dict[str, List[str]]) -> Tuple[bool, List[str]]:
    """⑤ [Others排除規約] 分類外（その他）テスト 5件以下（目標0件）維持規約"""
    others = categories['others']
    count = len(others)
    passed = count <= 5
    msgs = [f"Others（分類外）: {count} 件 / 基準: 5件 以下 (現行目標: 0件)"]
    if not passed:
        msgs.append(f"分類外のテストディレクトリが存在します: {others[:5]}")
    return passed, msgs


def check_protected_assets(categories: Dict[str, List[str]]) -> Tuple[bool, List[str]]:
    """⑥ [資産保護＆Goldenスリム化規約] ガバナンステスト（45件以上保護）＆ Goldenテスト（10件以下厳選）"""
    gov_count = len(categories['governance'])
    golden_count = len(categories['golden'])
    
    gov_ok = gov_count >= 45
    golden_ok = golden_count <= 10
    passed = gov_ok and golden_ok
    
    msgs = [
        f"Governanceテスト: {gov_count} 件 (実質検証最低保護基準: 45件) - {'🟢 適合' if gov_ok else '🔴 欠落検知'}",
        f"Goldenテスト: {golden_count} 件 (上限基準: 10件以下・厳選中核UI) - {'🟢 適合' if golden_ok else '🔴 過剰肥大検知'}"
    ]
    if not gov_ok:
        msgs.append("永久保護対象の実質ガバナンステストが削減・削除されています。直ちに復元してください。")
    if not golden_ok:
        msgs.append("Goldenテストが上限を超過しています。実画像比較を行わないテストは widget/ へ統合してください。")
    return passed, msgs


def check_semantic_integrity(test_dir: str = 'test') -> Tuple[bool, List[str]]:
    """⑦ [セマンティック内容規約] E2EへのUIテスト強制 ＆ Integrationへのヘッドレス強制（抜け穴完全封鎖）"""
    violations = []
    
    e2e_dir = os.path.join(test_dir, 'e2e')
    if os.path.exists(e2e_dir):
        for root, _, files in os.walk(e2e_dir):
            for f in files:
                if f.endswith('_test.dart'):
                    path = os.path.join(root, f)
                    with open(path, 'r', encoding='utf-8') as file:
                        content = file.read()
                    if 'testWidgets(' not in content:
                        violations.append(f"E2E違反: '{f}' に UI待機・testWidgets が含まれていません。integration/ へ移管してください。")

    int_dir = os.path.join(test_dir, 'integration')
    if os.path.exists(int_dir):
        for root, _, files in os.walk(int_dir):
            for f in files:
                if f.endswith('_test.dart'):
                    path = os.path.join(root, f)
                    with open(path, 'r', encoding='utf-8') as file:
                        content = file.read()
                    if 'testWidgets(' in content:
                        violations.append(f"Integration違反: '{f}' に UIテスト (testWidgets) が混入しています。widget/ または e2e/ へ移管してください。")

    passed = len(violations) == 0
    msgs = [
        f"セマンティック検証: 検査完了 - {'🟢 適合 (全ファイルの責務・中身が完全一致)' if passed else '🔴 責務違反検知'}"
    ]
    if not passed:
        msgs.extend(violations)
    return passed, msgs


def main():
    print("=" * 68)
    print(" 📊 【第610条 ガバナンス監査】⚖️ テストピラミッド黄金比 ＆ 資産構造維持規約")
    print("=" * 68)

    categories = scan_test_assets()
    total = sum(len(v) for v in categories.values())

    print(f" 📦 テスト総ファイル数: {total} 件")
    print("-" * 68)

    ok1, m1 = check_unit_ratio(categories, total)
    ok2, m2 = check_widget_ratio(categories, total)
    ok3, m3 = check_integration_ratio(categories, total)
    ok4, m4 = check_e2e_ratio(categories, total)
    ok5, m5 = check_others_count(categories)
    ok6, m6 = check_protected_assets(categories)
    ok7, m7 = check_semantic_integrity()

    rules = [
        ("① [Unit比率規約] 単体テスト比率 42.0% 以上保持規約", ok1, m1),
        ("② [Widget比率規約] UIコンポーネントテスト比率 42.0% 以下維持規約", ok2, m2),
        ("③ [Integration比率規約] ヘッドレス結合テスト比率 3.0%〜8.0% 維持規約", ok3, m3),
        ("④ [E2E比率規約] 現場UI結合E2Eテスト比率 3.0% 以下維持規約", ok4, m4),
        ("⑤ [Others排除規約] 分類外（その他）テスト 5件以下（目標0件）維持規約", ok5, m5),
        ("⑥ [資産保護＆Goldenスリム化規約] ガバナンステスト（45件以上）＆ Goldenテスト（10件以下）規約", ok6, m6),
        ("⑦ [セマンティック内容規約] E2E・Integration名実一致規約（抜け穴完全封鎖）", ok7, m7),
    ]

    all_passed = all(r[1] for r in rules)
    for label, ok, msgs in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        for m in msgs:
            prefix = "    ℹ️" if ok else "    ❌"
            print(f"{prefix} {m}")

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (真のテストピラミッド黄金比 ＆ 資産構造維持規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (テストピラミッドの比率または資産構造に違反が検出されました)")
        print("=" * 68)
        sys.exit(1)


if __name__ == "__main__":
    main()
