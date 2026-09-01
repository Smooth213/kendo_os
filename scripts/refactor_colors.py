#!/usr/bin/env python3
import os
import re

def refactor_colors():
    lib_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../lib'))
    files = []
    for root, dirs, filenames in os.walk(lib_dir):
        for f in filenames:
            if f.endswith('.dart') and f not in ['app_kendo_colors.dart', 'theme_color_extensions.dart', 'firebase_options.dart']:
                files.append(os.path.join(root, f))

    color_replacements = [
        # Red / Error
        (r'Colors\.red\.shade[478]00\b', '_themeColors.errorColor'),
        (r'Colors\.redAccent\b', '_themeColors.errorColor'),

        # Green / Success
        (r'Colors\.green\.shade[478]00\b', '_themeColors.successColor'),

        # Orange / Warning
        (r'Colors\.orange\.shade[478]00\b', '_themeColors.warningColor'),

        # Blue / Info
        (r'Colors\.blue\.shade[478]00\b', '_themeColors.infoColor'),

        # Grey / SubText & Hint
        (r'Colors\.grey\.shade600\b', '_themeColors.hintColor'),
        (r'Colors\.grey\.shade700\b', '_themeColors.subTextColor'),
    ]

    modified_count = 0

    for path in files:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content

        for pat, repl in color_replacements:
            if re.search(pat, content):
                content = re.sub(pat, repl, content)

        if content != original:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            modified_count += 1

    print(f"Refactored {modified_count} files for color tokens successfully!")

if __name__ == '__main__':
    refactor_colors()
