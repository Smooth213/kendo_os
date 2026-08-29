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
    raw_kendo_shades = 0
    raw_direct_show_dialog = 0
    raw_textfields = 0
    raw_font_weights = 0
    raw_isdark_branches = 0
    raw_contrast_issues = 0
    raw_bottom_sheets = 0
    raw_chips = 0
    raw_alert_dialogs = 0
    raw_dark_black_texts = 0
    raw_gold_text_issues = 0
    raw_separator_text_issues = 0

    raw_switches = 0
    raw_arrow_back_icons = 0
    raw_share_icons = 0

    for f in files:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
            filename = os.path.basename(f)
            rel_path = os.path.relpath(f, lib_dir).replace('\\', '/')

            if filename != 'app_tokens.dart':
                raw_border_radius += len(re.findall(r'BorderRadius\.circular\(\s*\d+|Radius\.circular\(\s*\d+', content))
                if '/pdf/' not in rel_path:
                    raw_font_size += len(re.findall(r'fontSize:\s*(?!AppFontSize\.)\d+', content))

                # Check for numerical EdgeInsets not using AppSpacing
                for match in re.finditer(r'EdgeInsets\.(all|symmetric|only|fromLTRB)\(([^)]*)\)', content, flags=re.DOTALL):
                    args = match.group(2)
                    clean_text = re.sub(r'//.*$', '', args, flags=re.MULTILINE)
                    clean_text = re.sub(r'/\*.*?\*/', '', clean_text, flags=re.DOTALL)
                    if not ('AppSpacing.' in clean_text or 'AppEdgeInsets.' in clean_text or clean_text.strip() == 'zero') and re.search(r'\d+', clean_text):
                        clean_args = re.sub(r'(horizontal|vertical|left|top|right|bottom)\s*:\s*[01](?:\.[05])?', '', clean_text).strip(' ,\n\r\t')
                        if clean_args and re.search(r'[2-9]|\d{2,}', clean_args):
                            raw_edge_insets += 1

            if filename not in ['app_kendo_colors.dart', 'theme_color_extensions.dart'] and not filename.endswith('.freezed.dart') and not filename.endswith('.g.dart') and '/pdf/' not in rel_path:
                raw_colors += len(re.findall(r'(?<!\.)\bColors\.(white|black|grey|red|blue|amber|orange|purple|deepPurple|indigo|teal|green|yellow|brown|pink|cyan|lime)', content))

            if filename != 'app_header.dart':
                raw_appbars += len(re.findall(r'\bAppBar\s*\(', content))

            if filename == 'app_snack_bar.dart':
                raw_snackbars_colors += len(re.findall(r'Colors\.red\.shade|Colors\.green\.shade', content))

            # 7. AppKendoColors shade access (bypassing theme colors)
            if filename not in ['app_kendo_colors.dart', 'theme_color_extensions.dart'] and '/pdf/' not in rel_path:
                raw_kendo_shades += len(re.findall(r'AppKendoColors\.(grey|red|blue|green|orange|purple|indigo|teal|amber|yellow|pink|cyan|brown|deepPurple|blueGrey|deepOrange)\.shade\d+', content))

            # 8. Direct showDialog (bypassing showAppDialog)
            if filename != 'app_dialog.dart':
                raw_direct_show_dialog += len(re.findall(r'\bshowDialog\b', content))

            # 9. Direct TextField (bypassing AppTextField)
            if not rel_path.startswith('shared/widgets/') and not rel_path.startswith('shared/presentation/'):
                raw_textfields += len(re.findall(r'\bTextField\s*\(', content))

            # 10. Raw FontWeight (bypassing AppFontWeight)
            if filename != 'app_tokens.dart' and '/pdf/' not in rel_path:
                raw_font_weights += len(re.findall(r'(?<!App)FontWeight\.(bold|normal|w\d{3})', content))

            # 11. Manual isDark color branches for theme colors (bypassing AppThemeColors)
            if filename != 'theme_color_extensions.dart':
                raw_isdark_branches += len(re.findall(r'color\s*:\s*isDark\s*\?\s*AppKendoColors\.[^;\n]*:', content))

            # 12. Contrast & inverted background color issues (using textColor as background color)
            if '/pdf/' not in rel_path:
                raw_contrast_issues += len(re.findall(r'(backgroundColor|fillColor|surfaceTintColor|cardColor|color)\s*:\s*[^;\n]*isDark\s*\?[^;\n]+:\s*(context\.appColors\.)?textColor(\.(withValues|withOpacity)\([^)]*\))?', content))

            # 13. Direct showModalBottomSheet (bypassing showAppBottomSheet)
            if filename != 'app_bottom_sheet.dart':
                raw_bottom_sheets += len(re.findall(r'\bshowModalBottomSheet\b', content))

            # 14. Direct Chip widgets (bypassing AppChoiceChip/AppActionChip/AppFilterChip)
            if filename != 'app_chip.dart':
                raw_chips += len(re.findall(r'\b(ChoiceChip|ActionChip|FilterChip|RawChip|InputChip)\s*\(', content))

            # 15. Direct AlertDialog (bypassing AppDialog)
            if filename != 'app_dialog.dart':
                raw_alert_dialogs += len(re.findall(r'\bAlertDialog\s*\(', content))

            # 16. Dark mode black text invisibility (isDark with 0x8A000000 etc.)
            if filename != 'theme_color_extensions.dart' and '/pdf/' not in rel_path:
                raw_dark_black_texts += len(re.findall(r'isDark\s*\?\s*const Color\(0x[0-9A-Fa-f]{2}000000\)', content))

            # 17. Gold text low contrast issues
            if filename not in ['scoreboard.dart', 'viewer_match_screen.dart', 'theme_color_extensions.dart'] and '/pdf/' not in rel_path:
                raw_gold_text_issues += len(re.findall(r'TextStyle\s*\([^)]*color\s*:\s*AppKendoColors\.ipponGold\b', content))

            # 18. separatorColor text misuse
            if filename not in ['theme_color_extensions.dart', 'app_theme_colors.dart'] and '/pdf/' not in rel_path:
                raw_separator_text_issues += len(re.findall(r'TextStyle\s*\([^)]*color\s*:\s*[^,\)]*separatorColor[^,\)]*', content))

            # 19. Direct Switch widgets (bypassing AppSwitch)
            if filename != 'app_switch.dart':
                raw_switches += len(re.findall(r'\bSwitch(\.adaptive)?\s*\(', content))

            # 20. Legacy arrow_back icons (bypassing Icons.arrow_back_ios_new)
            raw_arrow_back_icons += len(re.findall(r'Icons\.arrow_back(?!\w|_ios_new)\b|Icons\.arrow_back_ios\b(?!_new)', content))

            # 21. Legacy share icons (bypassing Icons.ios_share)
            raw_share_icons += len(re.findall(r'Icons\.share\b(?!_rounded)', content))

    print("=" * 50)
    print(" 📊 【ガバナンス監査 2/4】🎨 デザインシステム トークン 監査レポート")
    print("=" * 50)
    print(f" 1. AppBar 未移行件数: {raw_appbars} 件")
    print(f" 2. SnackBar 硬直色件数: {raw_snackbars_colors} 件")
    print(f" 3. ボーダー半径 生数値件数 (BorderRadius): {raw_border_radius} 件")
    print(f" 4. パディング 生数値件数 (EdgeInsets): {raw_edge_insets} 件")
    print(f" 5. フォントサイズ 生数値件数 (fontSize): {raw_font_size} 件")
    print(f" 6. 硬直色 件数 (Colors.*): {raw_colors} 件")
    print(f" 7. AppKendoColors シェード直参照件数: {raw_kendo_shades} 件")
    print(f" 8. 生 showDialog 呼び出し件数: {raw_direct_show_dialog} 件")
    print(f" 9. 生 TextField 呼び出し件数: {raw_textfields} 件")
    print(f"10. 生 FontWeight 参照件数: {raw_font_weights} 件")
    print(f"11. 手動 isDark 色分岐件数: {raw_isdark_branches} 件")
    print(f"12. 背景色テキスト色反転・透過誤用件数: {raw_contrast_issues} 件")
    print(f"13. ボトムシート 未移行件数 (showModalBottomSheet): {raw_bottom_sheets} 件")
    print(f"14. 生 Chip シリーズ件数 (Choice/Action/Filter): {raw_chips} 件")
    print(f"15. 生 AlertDialog 件数: {raw_alert_dialogs} 件")
    print(f"16. ダークモード文字黒透過消失件数: {raw_dark_black_texts} 件")
    print(f"17. サマリー黄色文字 低コントラスト件数: {raw_gold_text_issues} 件")
    print(f"18. 枠線色 (separatorColor) 文字色誤用件数: {raw_separator_text_issues} 件")
    print(f"19. 生 Switch 呼び出し件数: {raw_switches} 件")
    print(f"20. レガシー 戻るアイコン (arrow_back) 件数: {raw_arrow_back_icons} 件")
    print(f"21. レガシー シェアアイコン (Icons.share) 件数: {raw_share_icons} 件")
    total_issues = (raw_appbars + raw_snackbars_colors + raw_border_radius + 
                    raw_edge_insets + raw_font_size + raw_colors + 
                    raw_kendo_shades + raw_direct_show_dialog + raw_textfields + 
                    raw_font_weights + raw_isdark_branches + raw_contrast_issues +
                    raw_bottom_sheets + raw_chips + raw_alert_dialogs +
                    raw_dark_black_texts + raw_gold_text_issues + raw_separator_text_issues +
                    raw_switches + raw_arrow_back_icons + raw_share_icons)
    print("--------------------------------------------------")
    print(f" 🔴 残存問題 総数: {total_issues} 件")
    print("==================================================")

    if "--strict" in sys.argv and total_issues > 0:
        print("❌ ERROR: 直書き違反が残存しています。ビルドを中止します。")
        sys.exit(1)

if __name__ == '__main__':
    check_tokens()
