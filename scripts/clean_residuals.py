#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 残存違反完全クレンジング (Residual Cleaner)
=========================================================
1. rendering_optimization_test.dart などの 1. / 2A-1. / 2B-1. / P-1. などの連番完全除去
2. Rule X-Y: などのガバナンス連番の完全除去
3. [Unit] Unitにおいて などの不要な重ねタグプレフィックスの除去
4. 残存英文タイトルの完全日本語化
5. 文末「こと」の自然化
"""

import os
import re

PATTERNS = [
    # rendering_optimization_test.dart
    (r'\b1\.\s+cacheExtent値が正しく計算できること', 'cacheExtent値が正しく計算できること'),
    (r'\b2A-\d+\.\s*', ''),
    (r'\b2B-\d+\.\s*', ''),
    (r'\bP-\d+\.\s*', ''),
    
    # ガバナンス連番
    (r'\bRule\s*\d+(?:-\d+)?:\s*', ''),

    # 不要な重畳プレフィックス
    (r'\[(Unit|Widget|Governance|Golden|E2E|Security)\]\s+\1において\s*', r'[\1] '),
    (r'\[(Unit|Widget|Governance|Golden|E2E|Security)\]\s+Composite \1において\s*', r'[\1] '),
    (r'\[(Unit|Widget|Governance|Golden|E2E|Security)\]\s+\1\s+([A-Za-z]+)\s+テスト', r'[\1] \2テスト'),

    # 残存英文タイトル
    (r'onReorderMatches correctly reorders matches listこと', '試合並び替え操作により試合一覧が正しく再順序化されること'),
    (r'Handles selection mode tapこと', '選択モード時のタップ操作が正しく処理されること'),
    (r'initial timer display and toggles on tapが正しく描画されること', '初期タイマー表示が行われタップ時にトグル動作が正しく描画されること'),
    (r'BulkRuleDataHelper groups matches into units correctlyこと', '一括ルールデータヘルパーにより試合がユニット単位へ正しくグループ化されること'),
    (r'OrderSetupMatchGenerator generates matches correctlyこと', 'オーダー設定マッチジェネレーターにより試合が正しく生成されること'),
    (r'Removing players \(leaving\) removes them without disturbing other playersこと', '選手の離脱削除時に他の選手データに影響を与えることなく正常に削除されること'),

    # 文末
    (r'個人リーグ戦（matchType:\s*.*?\)\s*こと', '個人リーグ戦の試合種別が正しく処理されること'),
    (r'Müller.*?\)\s*こと', 'ドイツ語ウムラウトやフランス語等の特殊文字が正しく処理されること'),
    (r'各全出力モードが正しく反映されること\)\s*こと', '各全出力モードが正しく反映されること'),
    (r'重複UUIDコマンド排除配備規約が遵守されていることこと', '重複UUIDコマンド排除配備規約が遵守されていること'),
    (r'末尾が「こと」で終わり、「〜べき」や二重語尾が存在しないことこと', '末尾が「こと」で終わり、「〜べき」や二重語尾が存在しないこと'),
    (r'スコア白2-赤0で白の勝ちこと', 'スコア白2-赤0で白の勝ちとなること'),
    (r'白2-赤1で白の勝ちこと', '白2-赤1で白の勝ちとなること'),
    (r'白2-赤0で白の勝ちこと', '白2-赤0で白の勝ちとなること'),
    (r'「判定」が100%非表示こと', '「判定」が100%非表示となること'),
    (r'打突アクションボタン群レイアウト整合性こと', '打突アクションボタン群のレイアウト整合性が保証されること'),
    (r'QrDialog, ViewerShareDialog）の描画完全性こと', 'QrDialog, ViewerShareDialog）の描画完全性が保証されること'),
    (r'URL生成保証こと', 'URL生成が保証されること'),
    (r'同点サドンデス突入判定こと', '同点サドンデス突入と判定されること'),
    (r'ゼロ除算の完全防止こと', 'ゼロ除算が完全に防止されること'),
    (r'安全に保護され、次回の同期へ持ち越されることこと', '安全に保護され、次回の同期へ持ち越されること'),
    (r'両者のスコア・反則が互いに干渉せず完全独立更新されることこと', '両者のスコア・反則が互いに干渉せず完全独立更新されること'),
    (r'各行・各列が正しく結合され、行の高さが均等に配分されることこと', '各行・各列が正しく結合され、行の高さが均等に配分されること'),
    (r'フォールバックウィジェットが生成されることこと', 'フォールバックウィジェットが生成されること'),
    (r'コールバックが正しく動作することこと', 'コールバックが正しく動作すること'),
    (r'操作が処理できることこと', '操作が処理できること'),
]

def main():
    total_files = 0
    total_replaces = 0
    for root, _, files in os.walk('test'):
        for file in files:
            if file.endswith('_test.dart'):
                p = os.path.join(root, file)
                with open(p, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                
                new_content = content
                file_replaces = 0
                for pattern, repl in PATTERNS:
                    new_c, n = re.subn(pattern, repl, new_content)
                    if n > 0:
                        new_content = new_c
                        file_replaces += n
                
                if file_replaces > 0:
                    total_files += 1
                    total_replaces += file_replaces
                    with open(p, 'w', encoding='utf-8') as f:
                        f.write(new_content)

    print(f"徹底解消完了: {total_files} ファイル / {total_replaces} 箇所修正")

if __name__ == '__main__':
    main()
