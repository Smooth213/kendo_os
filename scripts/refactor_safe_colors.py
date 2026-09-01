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

        # Check if themeColors or _themeColors is ALREADY used in this file
        has_underscore_theme = bool(re.search(r'\b_themeColors\b', content))
        has_theme_colors = bool(re.search(r'\bthemeColors\b', content))

        if has_underscore_theme:
            content = re.sub(r'Colors\.red\.shade[78]00\b', '_themeColors.errorColor', content)
            content = re.sub(r'Colors\.green\.shade[78]00\b', '_themeColors.successColor', content)
            content = re.sub(r'Colors\.orange\.shade[78]00\b', '_themeColors.warningColor', content)
            content = re.sub(r'Colors\.blue\.shade[78]00\b', '_themeColors.infoColor', content)

        if has_theme_colors:
            content = re.sub(r'Colors\.red\.shade[78]00\b', 'themeColors.errorColor', content)
            content = re.sub(r'Colors\.green\.shade[78]00\b', 'themeColors.successColor', content)
            content = re.sub(r'Colors\.orange\.shade[78]00\b', 'themeColors.warningColor', content)
            content = re.sub(r'Colors\.blue\.shade[78]00\b', 'themeColors.infoColor', content)

        # Standalone Kendo Red replacement
        content = re.sub(r'\bColors\.red\.shade900\b', 'AppKendoColors.hansokuRed', content)

        if content != original:
            if "import 'package:kendo_os/shared/theme/app_kendo_colors.dart';" not in content and 'AppKendoColors' in content:
                content = "import 'package:kendo_os/shared/theme/app_kendo_colors.dart';\n" + content
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            modified_count += 1

    print(f"Refactored {modified_count} files for strictly safe color tokens successfully!")

if __name__ == '__main__':
    refactor()
