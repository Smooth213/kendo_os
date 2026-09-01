#!/usr/bin/env python3
import os
import re

def refactor_phase4():
    lib_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../lib'))
    files = []
    for root, dirs, filenames in os.walk(lib_dir):
        for f in filenames:
            if f.endswith('.dart') and f not in ('app_kendo_colors.dart', 'theme_color_extensions.dart'):
                files.append(os.path.join(root, f))

    # 赤・白・反則赤・金色の競技固定色集約ルール
    kendo_color_replacements = [
        (r'\bColors\.red\.shade[0-9]+\b', 'AppKendoColors.hansokuRed'),
        (r'\bColors\.amber\.shade[0-9]+\b', 'AppKendoColors.ipponGold'),
        (r'\bColors\.amber\b', 'AppKendoColors.ipponGold'),
        (r'\bColor\(0xFFFFD700\)\b', 'AppKendoColors.ipponGold'),
        (r'\bColor\(0xFFD32F2F\)\b', 'AppKendoColors.hansokuRed'),
        (r'\bColor\(0xFF8B0000\)\b', 'AppKendoColors.akaDark'),
    ]

    updated_count = 0
    for f in files:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()

        new_content = content
        if 'package:pdf/' not in content and 'import \'package:pdf/' not in content and 'pw.' not in content:
            for pattern, replacement in kendo_color_replacements:
                new_content = re.sub(pattern, replacement, new_content)

        if new_content != content:
            if 'app_kendo_colors.dart' not in new_content:
                import_stmt = "import 'package:kendo_os/shared/theme/app_kendo_colors.dart';\n"
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

    print(f"✅ Phase 4 完了: {updated_count} ファイルの競技固有色を AppKendoColors へ集約しました。")

if __name__ == '__main__':
    refactor_phase4()
