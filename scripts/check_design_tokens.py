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
    raw_direct_snackbars = 0
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
    raw_sized_boxes = 0

    violations_by_file = {}

    for f in files:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
            filename = os.path.basename(f)
            rel_path = os.path.relpath(f, lib_dir).replace('\\', '/')

            if filename != 'app_tokens.dart':
                border_count = len(re.findall(r'BorderRadius\.circular\(\s*\d+|Radius\.circular\(\s*\d+', content))
                raw_border_radius += border_count
                if border_count:
                    violations_by_file.setdefault(rel_path, []).append(f"生 BorderRadius ({border_count}件)")

                if '/pdf/' not in rel_path:
                    font_count = len(re.findall(r'fontSize:\s*(?!AppFontSize\.)\d+', content))
                    raw_font_size += font_count
                    if font_count:
                        violations_by_file.setdefault(rel_path, []).append(f"生 fontSize ({font_count}件)")

                # Check for numerical EdgeInsets not using AppSpacing
                edge_count = 0
                for match in re.finditer(r'EdgeInsets\.(all|symmetric|only|fromLTRB)\(([^)]*)\)', content, flags=re.DOTALL):
                    args = match.group(2)
                    clean_text = re.sub(r'//.*$', '', args, flags=re.MULTILINE)
                    clean_text = re.sub(r'/\*.*?\*/', '', clean_text, flags=re.DOTALL)
                    if not ('AppSpacing.' in clean_text or 'AppEdgeInsets.' in clean_text or clean_text.strip() == 'zero') and re.search(r'\d+', clean_text):
                        clean_args = re.sub(r'(horizontal|vertical|left|top|right|bottom)\s*:\s*[01](?:\.[05])?', '', clean_text).strip(' ,\n\r\t')
                        if clean_args and re.search(r'[2-9]|\d{2,}', clean_args):
                            edge_count += 1
                raw_edge_insets += edge_count
                if edge_count:
                    violations_by_file.setdefault(rel_path, []).append(f"生 EdgeInsets ({edge_count}件)")

            if filename not in ['app_kendo_colors.dart', 'theme_color_extensions.dart'] and not filename.endswith('.freezed.dart') and not filename.endswith('.g.dart') and '/pdf/' not in rel_path:
                color_count = len(re.findall(r'(?<!\.)\bColors\.(white|black|grey|red|blue|amber|orange|purple|deepPurple|indigo|teal|green|yellow|brown|pink|cyan|lime)', content))
                raw_colors += color_count
                if color_count:
                    violations_by_file.setdefault(rel_path, []).append(f"硬直色 Colors.* ({color_count}件)")

            if filename != 'app_header.dart':
                appbar_count = len(re.findall(r'\bAppBar\s*\(', content))
                raw_appbars += appbar_count
                if appbar_count:
                    violations_by_file.setdefault(rel_path, []).append(f"生 AppBar ({appbar_count}件)")

            # SnackBar: showSnackBar direct calls (bypassing AppSnackBar)
            if filename != 'app_snack_bar.dart':
                snack_count = len(re.findall(r'\bshowSnackBar\s*\(', content))
                raw_direct_snackbars += snack_count
                if snack_count:
                    violations_by_file.setdefault(rel_path, []).append(f"生 showSnackBar ({snack_count}件)")
            else:
                snack_color_count = len(re.findall(r'Colors\.red\.shade|Colors\.green\.shade', content))
                raw_snackbars_colors += snack_color_count
                if snack_color_count:
                    violations_by_file.setdefault(rel_path, []).append(f"SnackBar硬直色 ({snack_color_count}件)")

            # AppSpacing: SizedBox raw numbers (bypassing AppSpacing)
            if filename != 'app_tokens.dart' and '/pdf/' not in rel_path:
                sized_count = len(re.findall(r'SizedBox\s*\(\s*(height|width)\s*:\s*(4|8|12|16|24|32)(\.0)?\s*\)', content))
                raw_sized_boxes += sized_count
                if sized_count:
                    violations_by_file.setdefault(rel_path, []).append(f"生数値 SizedBox ({sized_count}件)")

            # 7. AppKendoColors shade access (bypassing theme colors)
            if filename not in ['app_kendo_colors.dart', 'theme_color_extensions.dart'] and '/pdf/' not in rel_path:
                kendo_count = len(re.findall(r'AppKendoColors\.(grey|red|blue|green|orange|purple|indigo|teal|amber|yellow|pink|cyan|brown|deepPurple|blueGrey|deepOrange)\.shade\d+', content))
                raw_kendo_shades += kendo_count
                if kendo_count:
                    violations_by_file.setdefault(rel_path, []).append(f"AppKendoColorsシェード直参照 ({kendo_count}件)")

            # 8. Direct showDialog (bypassing showAppDialog)
            if filename != 'app_dialog.dart':
                dialog_count = len(re.findall(r'\bshowDialog\b', content))
                raw_direct_show_dialog += dialog_count
                if dialog_count:
                    violations_by_file.setdefault(rel_path, []).append(f"生 showDialog ({dialog_count}件)")

            # 9. Direct TextField (bypassing AppTextField)
            if not rel_path.startswith('shared/widgets/') and not rel_path.startswith('shared/presentation/'):
                tf_count = len(re.findall(r'\bTextField\s*\(', content))
                raw_textfields += tf_count
                if tf_count:
                    violations_by_file.setdefault(rel_path, []).append(f"生 TextField ({tf_count}件)")

            # 10. Raw FontWeight (bypassing AppFontWeight)
            if filename != 'app_tokens.dart' and '/pdf/' not in rel_path:
                fw_count = len(re.findall(r'(?<!App)FontWeight\.(bold|normal|w\d{3})', content))
                raw_font_weights += fw_count
                if fw_count:
                    violations_by_file.setdefault(rel_path, []).append(f"生 FontWeight ({fw_count}件)")

            # 11. Manual isDark color branches for theme colors (bypassing AppThemeColors)
            if filename != 'theme_color_extensions.dart':
                isdark_count = len(re.findall(r'color\s*:\s*isDark\s*\?\s*AppKendoColors\.[^;\n]*:', content))
                raw_isdark_branches += isdark_count
                if isdark_count:
                    violations_by_file.setdefault(rel_path, []).append(f"手動 isDark 分岐 ({isdark_count}件)")

            # 12. Contrast & inverted background color issues (using textColor as background color)
            if '/pdf/' not in rel_path:
                contrast_count = len(re.findall(r'(backgroundColor|fillColor|surfaceTintColor|cardColor|color)\s*:\s*[^;\n]*isDark\s*\?[^;\n]+:\s*(context\.appColors\.)?textColor(\.(withValues|withOpacity)\([^)]*\))?', content))
                raw_contrast_issues += contrast_count
                if contrast_count:
                    violations_by_file.setdefault(rel_path, []).append(f"背景色テキスト色反転・透過誤用 ({contrast_count}件)")

            # 13. Direct showModalBottomSheet (bypassing showAppBottomSheet)
            if filename != 'app_bottom_sheet.dart':
                bs_count = len(re.findall(r'\bshowModalBottomSheet\b', content))
                raw_bottom_sheets += bs_count
                if bs_count:
                    violations_by_file.setdefault(rel_path, []).append(f"生 showModalBottomSheet ({bs_count}件)")

            # 14. Direct Chip widgets (bypassing AppChoiceChip/AppActionChip/AppFilterChip)
            if filename != 'app_chip.dart':
                chip_count = len(re.findall(r'\b(ChoiceChip|ActionChip|FilterChip|RawChip|InputChip)\s*\(', content))
                raw_chips += chip_count
                if chip_count:
                    violations_by_file.setdefault(rel_path, []).append(f"生 Chip ({chip_count}件)")

            # 15. Direct AlertDialog (bypassing AppDialog)
            if filename != 'app_dialog.dart':
                ad_count = len(re.findall(r'\bAlertDialog\s*\(', content))
                raw_alert_dialogs += ad_count
                if ad_count:
                    violations_by_file.setdefault(rel_path, []).append(f"生 AlertDialog ({ad_count}件)")

            # 16. Dark mode black text invisibility (isDark with 0x8A000000 etc.)
            if filename != 'theme_color_extensions.dart' and '/pdf/' not in rel_path:
                dark_text_count = len(re.findall(r'isDark\s*\?\s*const Color\(0x[0-9A-Fa-f]{2}000000\)', content))
                raw_dark_black_texts += dark_text_count
                if dark_text_count:
                    violations_by_file.setdefault(rel_path, []).append(f"ダークモード文字黒透過消失 ({dark_text_count}件)")

            # 17. Gold text low contrast issues
            if filename not in ['scoreboard.dart', 'viewer_match_screen.dart', 'theme_color_extensions.dart'] and '/pdf/' not in rel_path:
                gold_count = len(re.findall(r'TextStyle\s*\([^)]*color\s*:\s*AppKendoColors\.ipponGold\b', content))
                raw_gold_text_issues += gold_count
                if gold_count:
                    violations_by_file.setdefault(rel_path, []).append(f"サマリー黄色文字 低コントラスト ({gold_count}件)")

            # 18. separatorColor text misuse
            if filename not in ['theme_color_extensions.dart', 'app_theme_colors.dart'] and '/pdf/' not in rel_path:
                sep_count = len(re.findall(r'TextStyle\s*\([^)]*color\s*:\s*[^,\)]*separatorColor[^,\)]*', content))
                raw_separator_text_issues += sep_count
                if sep_count:
                    violations_by_file.setdefault(rel_path, []).append(f"枠線色 (separatorColor) 文字色誤用 ({sep_count}件)")

            # 19. Direct Switch widgets (bypassing AppSwitch)
            if filename != 'app_switch.dart':
                sw_count = len(re.findall(r'\bSwitch(\.adaptive)?\s*\(', content))
                raw_switches += sw_count
                if sw_count:
                    violations_by_file.setdefault(rel_path, []).append(f"生 Switch ({sw_count}件)")

            # 20. Legacy arrow_back icons (bypassing Icons.arrow_back_ios_new)
            arrow_count = len(re.findall(r'Icons\.arrow_back(?!\w|_ios_new)\b|Icons\.arrow_back_ios\b(?!_new)', content))
            raw_arrow_back_icons += arrow_count
            if arrow_count:
                violations_by_file.setdefault(rel_path, []).append(f"レガシー 戻るアイコン ({arrow_count}件)")

            # 21. Legacy share icons (bypassing Icons.ios_share)
            share_count = len(re.findall(r'Icons\.share\b(?!_rounded)', content))
            raw_share_icons += share_count
            if share_count:
                violations_by_file.setdefault(rel_path, []).append(f"レガシー シェアアイコン ({share_count}件)")

    print("=" * 60)
    print(" 📊 【ガバナンス監査 2/10】🎨 デザインシステム トークン 監査レポート")
    print("=" * 60)
    print(f" 1. AppBar 未移行件数: {raw_appbars} 件")
    print(f" 2. 生 showSnackBar 直書き件数: {raw_direct_snackbars} 件")
    print(f" 3. SnackBar 硬直色件数: {raw_snackbars_colors} 件")
    print(f" 4. ボーダー半径 生数値件数 (BorderRadius): {raw_border_radius} 件")
    print(f" 5. パディング 生数値件数 (EdgeInsets): {raw_edge_insets} 件")
    print(f" 6. 生数値 SizedBox 指定件数 (AppSpacing): {raw_sized_boxes} 件")
    print(f" 7. フォントサイズ 生数値件数 (fontSize): {raw_font_size} 件")
    print(f" 8. 硬直色 件数 (Colors.*): {raw_colors} 件")
    print(f" 9. AppKendoColors シェード直参照件数: {raw_kendo_shades} 件")
    print(f"10. 生 showDialog 呼び出し件数: {raw_direct_show_dialog} 件")
    print(f"11. 生 TextField 呼び出し件数: {raw_textfields} 件")
    print(f"12. 生 FontWeight 参照件数: {raw_font_weights} 件")
    print(f"13. 手動 isDark 色分岐件数: {raw_isdark_branches} 件")
    print(f"14. 背景色テキスト色反転・透過誤用件数: {raw_contrast_issues} 件")
    print(f"15. ボトムシート 未移行件数 (showModalBottomSheet): {raw_bottom_sheets} 件")
    print(f"16. 生 Chip シリーズ件数 (Choice/Action/Filter): {raw_chips} 件")
    print(f"17. 生 AlertDialog 件数: {raw_alert_dialogs} 件")
    print(f"18. ダークモード文字黒透過消失件数: {raw_dark_black_texts} 件")
    print(f"19. サマリー黄色文字 低コントラスト件数: {raw_gold_text_issues} 件")
    print(f"20. 枠線色 (separatorColor) 文字色誤用件数: {raw_separator_text_issues} 件")
    print(f"21. 生 Switch 呼び出し件数: {raw_switches} 件")
    print(f"22. レガシー 戻るアイコン (arrow_back) 件数: {raw_arrow_back_icons} 件")
    print(f"23. レガシー シェアアイコン (Icons.share) 件数: {raw_share_icons} 件")
    total_violations = (raw_appbars + raw_direct_snackbars + raw_snackbars_colors + 
                    raw_border_radius + raw_edge_insets + raw_sized_boxes + raw_font_size + raw_colors + 
                    raw_kendo_shades + raw_direct_show_dialog + raw_textfields + 
                    raw_font_weights + raw_isdark_branches + raw_contrast_issues +
                    raw_bottom_sheets + raw_chips + raw_alert_dialogs +
                    raw_dark_black_texts + raw_gold_text_issues + raw_separator_text_issues +
                    raw_switches + raw_arrow_back_icons + raw_share_icons)
    print("-" * 60)
    if total_violations == 0:
        print(" 🟢 監査結果: 合格 (23大デザインシステム規約に完全適合！)")
    else:
        print(f" 🔴 監査結果: 違反 ({total_violations} 件の残存問題が検出されました)")
        print("\n--- 🔍 違反ファイル詳細 ---")
        for v_path, v_issues in violations_by_file.items():
            print(f"  • {v_path}: {', '.join(v_issues)}")
        print("-" * 60)
    print("=" * 60)

    if "--strict" in sys.argv and total_violations > 0:
        print("❌ ERROR: 直書き違反が残存しています。ビルドを中止します。")
        sys.exit(1)

if __name__ == '__main__':
    check_tokens()
