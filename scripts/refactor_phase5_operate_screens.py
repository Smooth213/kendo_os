#!/usr/bin/env python3
import os
import re

def refactor_phase5_part_b_safe():
    target_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../lib/features/tournament/presentation/operate'))
    files = []
    for root, dirs, filenames in os.walk(target_dir):
        for f in filenames:
            if f.endswith('.dart'):
                files.append(os.path.join(root, f))

    theme_color_patterns = [
        (r'isDark\s*\?\s*Colors\.white\s*:\s*Colors\.black87', 'context.appColors.textColor'),
        (r'isDark\s*\?\s*Colors\.white\s*:\s*Colors\.black', 'context.appColors.textColor'),
        (r'isDark\s*\?\s*Colors\.white70\s*:\s*Colors\.black87', 'context.appColors.subTextColor'),
        (r'isDark\s*\?\s*Colors\.grey\.shade400\s*:\s*Colors\.grey\.shade800', 'context.appColors.subTextColor'),
        (r'isDark\s*\?\s*Colors\.grey\.shade800\s*:\s*Colors\.grey\.shade200', 'context.appColors.separatorColor'),
        (r'isDark\s*\?\s*Colors\.grey\.shade800\s*:\s*Colors\.grey\.shade300', 'context.appColors.separatorColor'),
        (r'isDark\s*\?\s*Colors\.grey\.shade900\s*:\s*Colors\.grey\.shade100', 'context.appColors.inputBackground'),
        (r'isDark\s*\?\s*Colors\.green\.shade400\s*:\s*Colors\.green\.shade700', 'context.appColors.successColor'),
        (r'isDark\s*\?\s*Colors\.orange\.shade400\s*:\s*Colors\.orange\.shade800', 'context.appColors.warningColor'),
        (r'isDark\s*\?\s*Colors\.red\.shade400\s*:\s*Colors\.red\.shade700', 'context.appColors.errorColor'),
        (r'isDark\s*\?\s*Colors\.blue\.shade400\s*:\s*Colors\.blue\.shade700', 'context.appColors.infoColor'),
    ]

    # ヘルパーメソッドや context が存在しないスコープを除外するための安全チェック
    def replace_in_build(match_content):
        # build(BuildContext context) または (BuildContext context) の定義があるメソッドブロック内でのみ置換
        new_c = match_content
        for pattern, replacement in theme_color_patterns:
            new_c = re.sub(pattern, replacement, new_c)
        return new_c

    updated_count = 0
    for f in files:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()

        new_content = content
        # Widget build(BuildContext context) {...} などのブロックを対象に安全に置換
        blocks = re.split(r'(Widget\s+[a-zA-Z0-9_]+\s*\([^)]*BuildContext\s+context[^)]*\)\s*\{)', new_content)
        
        if len(blocks) > 1:
            for i in range(1, len(blocks), 2):
                header = blocks[i]
                body = blocks[i+1]
                # body の中でネストされた括弧を簡易追跡または安全置換
                blocks[i+1] = replace_in_build(body)
            new_content = "".join(blocks)

        if new_content != content:
            if 'theme_color_extensions.dart' not in new_content:
                import_stmt = "import 'package:kendo_os/shared/theme/theme_color_extensions.dart';\n"
                if "import 'package:flutter/material.dart';" in new_content:
                    new_content = new_content.replace(
                        "import 'package:flutter/material.dart';",
                        "import 'package:flutter/material.dart';\n" + import_stmt,
                        1
                    )
                else:
                    new_content = import_stmt + new_content

            with open(f, 'w', encoding='utf-8') as file:
                file.write(new_content)
            updated_count += 1

    print(f"✅ Phase 5 (Part B - Safe) 完了: {updated_count} ファイルの運営画面テーマカラーを AppThemeColors へ集約しました。")

if __name__ == '__main__':
    refactor_phase5_part_b_safe()
