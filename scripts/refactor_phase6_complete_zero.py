#!/usr/bin/env python3
import os
import re

def refactor_phase6_absolute_all_zero():
    lib_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../lib'))
    files = []
    for root, dirs, filenames in os.walk(lib_dir):
        for f in filenames:
            if (f.endswith('.dart') and 
                not f.endswith('.freezed.dart') and 
                not f.endswith('.g.dart') and 
                f not in ('app_kendo_colors.dart', 'theme_color_extensions.dart') and 
                '/pdf/' not in f.replace('\\', '/')):
                files.append(os.path.join(root, f))

    color_names = [
        'white', 'black', 'grey', 'red', 'blue', 'amber', 'orange', 'purple', 'deepPurple', 
        'indigo', 'teal', 'green', 'yellow', 'brown', 'pink', 'cyan', 'lime', 'blueGrey', 
        'deepOrange', 'orangeAccent', 'tealAccent', 'blueAccent', 'redAccent', 'pinkAccent', 
        'purpleAccent', 'cyanAccent', 'yellowAccent', 'greenAccent', 'white60', 'white38', 'black45'
    ]
    pattern = re.compile(r'(?<!\.)\bColors\.(' + '|'.join(color_names) + r')(?=[\.\s,;\)\]\}]|$)')

    updated_count = 0
    for f in files:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()

        new_content = pattern.sub(r'AppKendoColors.\1', content)

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

    print(f"✅ Phase 6 (Absolute All Zero) 完了: {updated_count} ファイルの残存色を AppKendoColors へ完全統合しました。")

if __name__ == '__main__':
    refactor_phase6_absolute_all_zero()
