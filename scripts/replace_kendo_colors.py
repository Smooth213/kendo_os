#!/usr/bin/env python3
import os
import re

def refactor():
    lib_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../lib'))
    files = []
    for root, dirs, filenames in os.walk(lib_dir):
        for f in filenames:
            if f.endswith('.dart') and f not in ['app_kendo_colors.dart', 'theme_color_extensions.dart', 'firebase_options.dart']:
                files.append(os.path.join(root, f))

    modified_count = 0

    for path in files:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content

        if 'Colors.red.shade900' in content:
            content = content.replace('Colors.red.shade900', 'AppKendoColors.hansokuRed')

        if content != original:
            if "import 'package:kendo_os/shared/theme/app_kendo_colors.dart';" not in content:
                content = "import 'package:kendo_os/shared/theme/app_kendo_colors.dart';\n" + content
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            modified_count += 1

    print(f"Replaced Colors.red.shade900 with AppKendoColors.hansokuRed in {modified_count} files!")

if __name__ == '__main__':
    refactor()
