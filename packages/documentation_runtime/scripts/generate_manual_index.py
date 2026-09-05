#!/usr/bin/env python3
import os
import re
import json
from datetime import datetime

MANUALS_DIR = "packages/documentation_runtime/manuals"
OUTPUT_JSON = os.path.join(MANUALS_DIR, "manual_search_index.json")

# 定義された順序とカテゴリ
CATEGORIES = [
    ("quickstart", 10),
    ("recovery", 20),
    ("operator", 30),
    ("viewer", 40),
    ("faq", 50),
]

# 特定ファイルごとのキーワード拡張（同義語・検索補助）
CUSTOM_TAGS = {
    "quickstart/index.md": ["クイック", "目次", "スタート", "早見表"],
    "quickstart/3min_setup.md": ["3分", "セットアップ", "準備", "開始", "簡単", "初心者"],
    "quickstart/operator_1pager.md": ["記録係", "机上", "1枚", "Undo", "取り消し", "スコア", "タイマー"],
    "quickstart/viewer_1pager.md": ["観客", "保護者", "1枚", "スマホ", "QR", "見方"],
    "recovery/index.md": ["障害", "復旧", "トラブル", "監査", "目次"],
    "recovery/failure_catalog.md": ["障害", "オフライン", "切断", "バッテリー", "熱暴走", "ミス", "Undo", "紙運用"],
    "recovery/observability_dashboard.md": ["監視", "同期", "キュー", "ダッシュボード", "再送", "リプレイ"],
    "operator/index.md": ["運営", "記録", "目次", "総合"],
    "operator/create_tournament.md": ["大会作成", "新規", "会場", "コート数", "個人戦", "団体戦"],
    "operator/team_registration.md": ["チーム登録", "選手登録", "学校", "道場", "オーダー", "並び順"],
    "operator/category_rules.md": ["ルール設定", "部門", "試合時間", "延長", "勝敗判定", "代表戦", "判定基準", "独立"],
    "operator/setup_match.md": ["試合作成", "対戦カード", "コート", "試合順", "オーダー", "ルール選択"],
    "operator/home_guide.md": ["大会ホーム", "試合一覧", "タブ", "対戦サマリー", "進行状況", "カード"],
    "operator/match.md": ["試合記録", "スコア入力", "タイマー", "面", "小手", "胴", "突き", "反則", "Undo", "一本"],
    "operator/bulk_rule_edit.md": ["一括ルール編集", "一括変更", "複数コート", "時間変更", "延長変更"],
    "operator/team_match_status.md": ["チーム試合状況", "団体戦", "勝者数", "総本数", "先鋒", "次鋒", "中堅", "副将", "大将", "代表戦"],
    "operator/standings.md": ["成績表", "順位表", "トーナメント表", "予選リーグ", "決勝"],
    "operator/official_record.md": ["公式記録", "PDF出力", "CSV出力", "印刷", "結果共有", "修正"],
    "operator/dock_guide.md": ["ドック", "常設パネル", "背面操作", "Googleマップ型", "ミニパネル", "並行操作"],
    "operator/program_management.md": ["大会プログラム", "進行表", "試合順", "コート割", "タイムスケジュール"],
    "operator/bunaiksen.md": ["部内戦", "練習試合", "総当たり", "勝抜戦", "紅白戦", "自由対戦", "途中離脱"],
    "operator/master_management.md": ["選手マスタ", "新年度一括進級", "学年繰り上げ", "卒業", "CSV取込", "アーカイブ"],
    "operator/settings.md": ["設定", "サンシャインモード", "高コントラスト", "サーマル冷却", "フォントサイズ", "省電力"],
    "operator/audit_log.md": ["監査ログ", "操作履歴", "タイムスタンプ", "改ざん防止", "疑義確認"],
    "viewer/index.md": ["観客", "保護者", "閲覧", "目次"],
    "viewer/viewer_home.md": ["観客ホーム", "コート一覧", "進行中", "リアルタイム", "スコア速報"],
    "viewer/viewer_match.md": ["リアルタイム試合", "一本速報", "タイマー", "スコアボード", "観客"],
    "viewer/viewer_team_match_status.md": ["団体戦", "チーム状況", "観客", "勝者数", "取得本数", "サマリー"],
    "viewer/viewer_program.md": ["大会プログラム", "個人メモ", "マーカー", "試合順", "保護者"],
    "viewer/viewer_official_record.md": ["試合結果", "公式記録", "閲覧", "過去結果", "PDF"],
    "viewer/viewer_bunaiksen.md": ["部内戦結果", "練習試合", "勝敗表", "個人成績", "保護者"],
    "viewer/viewer_team_scoreboard.md": ["団体戦スコアボード", "大型表示", "電光掲示板", "先鋒〜大将"],
    "viewer/viewer_kachinuki_scoreboard.md": ["勝ち抜き戦スコアボード", "勝ち残り", "連続勝ち抜き"],
    "faq/operator_faq.md": ["運営FAQ", "よくある質問", "トラブル", "タイマーずれ", "誤連打", "進級", "ドック"],
    "faq/viewer_faq.md": ["観客FAQ", "よくある質問", "動かない", "止まった", "サンシャイン", "更新"],
}

def extract_metadata_from_file(rel_path, sort_order):
    full_path = os.path.join(MANUALS_DIR, rel_path)
    if not os.path.exists(full_path):
        return None

    with open(full_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Frontmatter除去
    body = content
    if content.startswith("---"):
        parts = content.split("---", 2)
        if len(parts) >= 3:
            body = parts[2]

    # タイトル抽出 (# タイトル)
    title_match = re.search(r"^#\s+(.+)$", body, re.MULTILINE)
    title = "無題"
    if title_match:
        raw_title = title_match.group(1).strip()
        # パンくずや英語併記を整理
        title = raw_title

    # 見出し抽出 (## 見出し)
    headings = []
    for h_match in re.finditer(r"^##\s+(.+)$", body, re.MULTILINE):
        h_text = h_match.group(1).strip()
        # 見出し内のMarkdownリンクやアンカーをクリーンアップ
        h_text = re.sub(r"\{#[^\}]+\}", "", h_text).strip()
        h_text = re.sub(r"\[([^\]]+)\]\([^\)]+\)", r"\1", h_text).strip()
        if h_text and h_text not in headings:
            headings.append(h_text)

    # タグ
    tags = list(CUSTOM_TAGS.get(rel_path, []))

    # 更新日時（現時刻ISO）
    last_updated = datetime.now().isoformat()

    full_asset_path = f"packages/documentation_runtime/manuals/{rel_path}"

    return {
        "path": full_asset_path,
        "title": title,
        "headings": headings[:8],  # 上位8件
        "sort_order": sort_order,
        "tags": tags,
        "last_updated": last_updated,
    }

def main():
    entries = []

    for cat_dir, sort_order in CATEGORIES:
        target_dir = os.path.join(MANUALS_DIR, cat_dir)
        if not os.path.exists(target_dir):
            continue

        # ファイル一覧
        files = sorted(os.listdir(target_dir))
        for filename in files:
            if not filename.endswith(".md"):
                continue
            rel_path = f"{cat_dir}/{filename}"
            meta = extract_metadata_from_file(rel_path, sort_order)
            if meta:
                entries.append(meta)

    # 書き込み
    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)

    print(f"Generated {len(entries)} manual index entries to {OUTPUT_JSON}")

if __name__ == "__main__":
    main()
