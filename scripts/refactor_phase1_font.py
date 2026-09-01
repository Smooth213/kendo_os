#!/usr/bin/env python3
import os
import re

def refactor_phase1():
    lib_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../lib'))
    files = []
    for root, dirs, filenames in os.walk(lib_dir):
        for f in filenames:
            if f.endswith('.dart') and f != 'app_tokens.dart':
                files.append(os.path.join(root, f))

    font_size_map = {
        r'\bfontSize:\s*8(?:\.0)?\b': 'fontSize: AppFontSize.micro',
        r'\bfontSize:\s*9(?:\.0)?\b': 'fontSize: AppFontSize.nano',
        r'\bfontSize:\s*10(?:\.0)?\b': 'fontSize: AppFontSize.badge',
        r'\bfontSize:\s*11(?:\.0)?\b': 'fontSize: AppFontSize.caption',
        r'\bfontSize:\s*12(?:\.0)?\b': 'fontSize: AppFontSize.small',
        r'\bfontSize:\s*13(?:\.0)?\b': 'fontSize: AppFontSize.bodySmall',
        r'\bfontSize:\s*14(?:\.0)?\b': 'fontSize: AppFontSize.body',
        r'\bfontSize:\s*15(?:\.0)?\b': 'fontSize: AppFontSize.bodyMedium',
        r'\bfontSize:\s*16(?:\.0)?\b': 'fontSize: AppFontSize.subhead',
        r'\bfontSize:\s*17(?:\.0)?\b': 'fontSize: AppFontSize.title',
        r'\bfontSize:\s*18(?:\.0)?\b': 'fontSize: AppFontSize.headline',
        r'\bfontSize:\s*20(?:\.0)?\b': 'fontSize: AppFontSize.header',
        r'\bfontSize:\s*22(?:\.0)?\b': 'fontSize: AppFontSize.titleLarge',
        r'\bfontSize:\s*24(?:\.0)?\b': 'fontSize: AppFontSize.display',
        r'\bfontSize:\s*26(?:\.0)?\b': 'fontSize: AppFontSize.heroLarge',
        r'\bfontSize:\s*28(?:\.0)?\b': 'fontSize: AppFontSize.hero',
        r'\bfontSize:\s*32(?:\.0)?\b': 'fontSize: AppFontSize.jumbo',
        r'\bfontSize:\s*34(?:\.0)?\b': 'fontSize: AppFontSize.heroXl',
        r'\bfontSize:\s*36(?:\.0)?\b': 'fontSize: AppFontSize.heroXxl',
        r'\bfontSize:\s*40(?:\.0)?\b': 'fontSize: AppFontSize.scoreboardMedium',
        r'\bfontSize:\s*46(?:\.0)?\b': 'fontSize: AppFontSize.scoreboardLarge',
        r'\bfontSize:\s*48(?:\.0)?\b': 'fontSize: AppFontSize.scoreboardTimer',
        r'\bfontSize:\s*56(?:\.0)?\b': 'fontSize: AppFontSize.scoreboardJumbo',
    }

    font_weight_map = {
        r'\bFontWeight\.w300\b': 'AppFontWeight.light',
        r'\bFontWeight\.w400\b': 'AppFontWeight.regular',
        r'\bFontWeight\.w500\b': 'AppFontWeight.medium',
        r'\bFontWeight\.w600\b': 'AppFontWeight.semiBold',
        r'\bFontWeight\.w700\b': 'AppFontWeight.bold',
        r'\bFontWeight\.w900\b': 'AppFontWeight.black',
    }

    updated_count = 0
    for f in files:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()

        new_content = content
        if 'package:pdf/' not in content and 'import \'package:pdf/' not in content and 'pw.' not in content:
            for pattern, replacement in font_size_map.items():
                new_content = re.sub(pattern, replacement, new_content)
            for pattern, replacement in font_weight_map.items():
                new_content = re.sub(pattern, replacement, new_content)

        if new_content != content:
            if 'app_tokens.dart' not in new_content:
                import_stmt = "import 'package:kendo_os/shared/theme/app_tokens.dart';\n"
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

    print(f"✅ Phase 1 完了: {updated_count} ファイルをリファクタリングしました。")

if __name__ == '__main__':
    refactor_phase1()
