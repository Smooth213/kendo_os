#!/usr/bin/env python3
import os
import re

def refactor_phase5_part_d():
    target_dirs = [
        os.path.abspath(os.path.join(os.path.dirname(__file__), '../lib/features/auth')),
        os.path.abspath(os.path.join(os.path.dirname(__file__), '../lib/admin')),
        os.path.abspath(os.path.join(os.path.dirname(__file__), '../lib/shared/presentation')),
    ]
    files = []
    for d in target_dirs:
        for root, dirs, filenames in os.walk(d):
            for f in filenames:
                if f.endswith('.dart'):
                    files.append(os.path.join(root, f))

    theme_color_patterns = [
        (r'isDark\s*\?\s*Colors\.white\s*:\s*Colors\.black87', 'context.appColors.textColor'),
        (r'isDark\s*\?\s*Colors\.white\s*:\s*Colors\.black', 'context.appColors.textColor'),
        (r'isDark\s*\?\s*Colors\.white\s*:\s*const Color\(0xFF1A237E\)', 'context.appColors.textColor'),
        (r'isDark\s*\?\s*Colors\.white70\s*:\s*Colors\.black54', 'context.appColors.subTextColor'),
        (r'isDark\s*\?\s*Colors\.grey\.shade400\s*:\s*Colors\.grey\.shade800', 'context.appColors.subTextColor'),
        (r'isDark\s*\?\s*Colors\.grey\.shade400\s*:\s*Colors\.grey\.shade600', 'context.appColors.subTextColor'),
        (r'isDark\s*\?\s*const Color\(0xFF38383A\)\s*:\s*Colors\.grey\.shade200', 'context.appColors.separatorColor'),
        (r'isDark\s*\?\s*Colors\.grey\.shade800\s*:\s*Colors\.grey\.shade300', 'context.appColors.separatorColor'),
        (r'isDark\s*\?\s*const Color\(0xFF1C1C1E\)\s*:\s*Colors\.white', 'context.appColors.cardBackground'),
        (r'isDark\s*\?\s*Colors\.grey\.shade900\s*:\s*Colors\.grey\.shade100', 'context.appColors.inputBackground'),
        (r'isDark\s*\?\s*const Color\(0xFF2C2C2E\)\s*:\s*Colors\.grey\.shade100', 'context.appColors.inputBackground'),
    ]

    def replace_in_build(match_content):
        new_c = match_content
        for pattern, replacement in theme_color_patterns:
            new_c = re.sub(pattern, replacement, new_c)
        return new_c

    updated_count = 0
    for f in files:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()

        new_content = content
        blocks = re.split(r'(Widget\s+[a-zA-Z0-9_]+\s*\([^)]*BuildContext\s+context[^)]*\)\s*\{)', new_content)

        if len(blocks) > 1:
            for i in range(1, len(blocks), 2):
                header = blocks[i]
                body = blocks[i+1]
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

    print(f"✅ Phase 5 (Part D) 完了: {updated_count} ファイルの認証・管理画面テーマカラーを AppThemeColors へ集約しました。")

if __name__ == '__main__':
    refactor_phase5_part_d()
