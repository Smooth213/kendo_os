#!/usr/bin/env python3
import os
import re
import sys

def check_tokens():
    lib_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../lib'))
    files = []
    for root, dirs, filenames in os.walk(lib_dir):
        for f in filenames:
            if f.endswith('.dart'):
                files.append(os.path.join(root, f))

    raw_border_radius = 0
    raw_font_size = 0
    raw_colors = 0
    raw_appbars = 0
    raw_edge_insets = 0
    raw_snackbars_colors = 0

    for f in files:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
            filename = os.path.basename(f)

            if filename != 'app_tokens.dart':
                raw_border_radius += len(re.findall(r'BorderRadius\.circular\(\s*\d+|Radius\.circular\(\s*\d+', content))
                if '/pdf/' not in f.replace('\\', '/'):
                    raw_font_size += len(re.findall(r'fontSize:\s*(?!AppFontSize\.)\d+', content))

                # Check for numerical EdgeInsets not using AppSpacing
                for match in re.finditer(r'EdgeInsets\.(all|symmetric|only|fromLTRB)\(([^)]*)\)', content, flags=re.DOTALL):
                    args = match.group(2)
                    # コメントを削除して評価
                    clean_text = re.sub(r'//.*$', '', args, flags=re.MULTILINE)
                    clean_text = re.sub(r'/\*.*?\*/', '', clean_text, flags=re.DOTALL)
                    if not ('AppSpacing.' in clean_text or 'AppEdgeInsets.' in clean_text or clean_text.strip() == 'zero') and re.search(r'\d+', clean_text):
                        # 0, 0.0, 1, 1.0, 1.5 のみの調整パディングは除外
                        clean_args = re.sub(r'(horizontal|vertical|left|top|right|bottom)\s*:\s*[01](?:\.[05])?', '', clean_text).strip(' ,\n\r\t')
                        if clean_args and re.search(r'[2-9]|\d{2,}', clean_args):
                            raw_edge_insets += 1

            if filename not in ['app_kendo_colors.dart', 'theme_color_extensions.dart']:
                raw_colors += len(re.findall(r'Colors\.(white|black|grey|red|blue|amber|orange|purple|deepPurple|indigo|teal|green|yellow|brown|pink|cyan|lime)', content))

            if filename != 'app_header.dart':
                raw_appbars += len(re.findall(r'\bAppBar\s*\(', content))

            if filename == 'app_snack_bar.dart':
                raw_snackbars_colors += len(re.findall(r'Colors\.red\.shade|Colors\.green\.shade', content))

    print("==================================================")
    print(" 📊 kendo OS デザインシステム 監査レポート")
    print("==================================================")
    print(f" 1. AppBar 未移行件数: {raw_appbars} 件")
    print(f" 2. SnackBar 硬直色件数: {raw_snackbars_colors} 件")
    print(f" 3. ボーダー半径 生数値件数 (BorderRadius): {raw_border_radius} 件")
    print(f" 4. パディング 生数値件数 (EdgeInsets): {raw_edge_insets} 件")
    print(f" 5. フォントサイズ 生数値件数 (fontSize): {raw_font_size} 件")
    print(f" 6. 硬直色 件数 (Colors.*): {raw_colors} 件")
    total_issues = raw_appbars + raw_snackbars_colors + raw_border_radius + raw_edge_insets + raw_font_size + raw_colors
    print("--------------------------------------------------")
    print(f" 🔴 残存問題 総数: {total_issues} 件")
    print("==================================================")

    if "--strict" in sys.argv and total_issues > 0:
        print("❌ ERROR: 直書き違反が残存しています。ビルドを中止します。")
        sys.exit(1)

if __name__ == '__main__':
    check_tokens()
