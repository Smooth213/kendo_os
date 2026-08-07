#!/usr/bin/env python3
import os
import re

def refactor():
    lib_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../lib'))
    files = []
    for root, dirs, filenames in os.walk(lib_dir):
        for f in filenames:
            if f.endswith('.dart') and f != 'app_tokens.dart':
                files.append(os.path.join(root, f))

    font_size_replacements = [
        (r'fontSize:\s*8(?:\.0)?\b', 'fontSize: AppFontSize.micro'),
        (r'fontSize:\s*10(?:\.0)?\b', 'fontSize: AppFontSize.badge'),
        (r'fontSize:\s*11(?:\.0)?\b', 'fontSize: AppFontSize.caption'),
        (r'fontSize:\s*12(?:\.0)?\b', 'fontSize: AppFontSize.small'),
        (r'fontSize:\s*13(?:\.0)?\b', 'fontSize: AppFontSize.bodySmall'),
        (r'fontSize:\s*14(?:\.0)?\b', 'fontSize: AppFontSize.body'),
        (r'fontSize:\s*15(?:\.0)?\b', 'fontSize: AppFontSize.bodyMedium'),
        (r'fontSize:\s*16(?:\.0)?\b', 'fontSize: AppFontSize.subhead'),
        (r'fontSize:\s*17(?:\.0)?\b', 'fontSize: AppFontSize.title'),
        (r'fontSize:\s*18(?:\.0)?\b', 'fontSize: AppFontSize.headline'),
        (r'fontSize:\s*20(?:\.0)?\b', 'fontSize: AppFontSize.header'),
        (r'fontSize:\s*24(?:\.0)?\b', 'fontSize: AppFontSize.display'),
        (r'fontSize:\s*28(?:\.0)?\b', 'fontSize: AppFontSize.hero'),
        (r'fontSize:\s*32(?:\.0)?\b', 'fontSize: AppFontSize.jumbo'),
        (r'fontSize:\s*48(?:\.0)?\b', 'fontSize: AppFontSize.scoreboardTimer'),
        (r'fontSize:\s*56(?:\.0)?\b', 'fontSize: AppFontSize.scoreboardJumbo'),
    ]

    edge_insets_replacements = [
        (r'EdgeInsets\.all\(\s*4(?:\.0)?\s*\)', 'EdgeInsets.all(AppSpacing.xs)'),
        (r'EdgeInsets\.all\(\s*8(?:\.0)?\s*\)', 'EdgeInsets.all(AppSpacing.sm)'),
        (r'EdgeInsets\.all\(\s*12(?:\.0)?\s*\)', 'EdgeInsets.all(AppSpacing.md)'),
        (r'EdgeInsets\.all\(\s*16(?:\.0)?\s*\)', 'EdgeInsets.all(AppSpacing.lg)'),
        (r'EdgeInsets\.all\(\s*24(?:\.0)?\s*\)', 'EdgeInsets.all(AppSpacing.xl)'),
        (r'EdgeInsets\.all\(\s*32(?:\.0)?\s*\)', 'EdgeInsets.all(AppSpacing.xxl)'),

        (r'horizontal:\s*4(?:\.0)?\b', 'horizontal: AppSpacing.xs'),
        (r'horizontal:\s*8(?:\.0)?\b', 'horizontal: AppSpacing.sm'),
        (r'horizontal:\s*12(?:\.0)?\b', 'horizontal: AppSpacing.md'),
        (r'horizontal:\s*16(?:\.0)?\b', 'horizontal: AppSpacing.lg'),
        (r'horizontal:\s*24(?:\.0)?\b', 'horizontal: AppSpacing.xl'),
        (r'horizontal:\s*32(?:\.0)?\b', 'horizontal: AppSpacing.xxl'),

        (r'vertical:\s*4(?:\.0)?\b', 'vertical: AppSpacing.xs'),
        (r'vertical:\s*8(?:\.0)?\b', 'vertical: AppSpacing.sm'),
        (r'vertical:\s*12(?:\.0)?\b', 'vertical: AppSpacing.md'),
        (r'vertical:\s*16(?:\.0)?\b', 'vertical: AppSpacing.lg'),
        (r'vertical:\s*24(?:\.0)?\b', 'vertical: AppSpacing.xl'),
        (r'vertical:\s*32(?:\.0)?\b', 'vertical: AppSpacing.xxl'),

        (r'top:\s*4(?:\.0)?\b', 'top: AppSpacing.xs'),
        (r'top:\s*8(?:\.0)?\b', 'top: AppSpacing.sm'),
        (r'top:\s*12(?:\.0)?\b', 'top: AppSpacing.md'),
        (r'top:\s*16(?:\.0)?\b', 'top: AppSpacing.lg'),
        (r'top:\s*24(?:\.0)?\b', 'top: AppSpacing.xl'),

        (r'bottom:\s*4(?:\.0)?\b', 'bottom: AppSpacing.xs'),
        (r'bottom:\s*8(?:\.0)?\b', 'bottom: AppSpacing.sm'),
        (r'bottom:\s*12(?:\.0)?\b', 'bottom: AppSpacing.md'),
        (r'bottom:\s*16(?:\.0)?\b', 'bottom: AppSpacing.lg'),
        (r'bottom:\s*24(?:\.0)?\b', 'bottom: AppSpacing.xl'),

        (r'left:\s*4(?:\.0)?\b', 'left: AppSpacing.xs'),
        (r'left:\s*8(?:\.0)?\b', 'left: AppSpacing.sm'),
        (r'left:\s*12(?:\.0)?\b', 'left: AppSpacing.md'),
        (r'left:\s*16(?:\.0)?\b', 'left: AppSpacing.lg'),
        (r'left:\s*24(?:\.0)?\b', 'left: AppSpacing.xl'),

        (r'right:\s*4(?:\.0)?\b', 'right: AppSpacing.xs'),
        (r'right:\s*8(?:\.0)?\b', 'right: AppSpacing.sm'),
        (r'right:\s*12(?:\.0)?\b', 'right: AppSpacing.md'),
        (r'right:\s*16(?:\.0)?\b', 'right: AppSpacing.lg'),
        (r'right:\s*24(?:\.0)?\b', 'right: AppSpacing.xl'),
    ]

    border_radius_replacements = [
        (r'BorderRadius\.circular\(\s*2(?:\.0)?\s*\)', 'AppRadius.micro'),
        (r'BorderRadius\.circular\(\s*4(?:\.0)?\s*\)', 'AppRadius.tiny'),
        (r'BorderRadius\.circular\(\s*6(?:\.0)?\s*\)', 'AppRadius.sub'),
        (r'BorderRadius\.circular\(\s*8(?:\.0)?\s*\)', 'AppRadius.small'),
        (r'BorderRadius\.circular\(\s*12(?:\.0)?\s*\)', 'AppRadius.medium'),
        (r'BorderRadius\.circular\(\s*16(?:\.0)?\s*\)', 'AppRadius.large'),
        (r'BorderRadius\.circular\(\s*20(?:\.0)?\s*\)', 'AppRadius.round'),
        (r'BorderRadius\.circular\(\s*24(?:\.0)?\s*\)', 'AppRadius.xlarge'),
    ]

    all_replacements = font_size_replacements + edge_insets_replacements + border_radius_replacements

    modified_count = 0

    for path in files:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content
        needs_import = False

        for pat, repl in all_replacements:
            if re.search(pat, content):
                needs_import = True
                content = re.sub(pat, repl, content)

        if needs_import and "import 'package:kendo_os/shared/theme/app_tokens.dart';" not in content:
            content = "import 'package:kendo_os/shared/theme/app_tokens.dart';\n" + content

        if content != original:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            modified_count += 1

    print(f"Refactored {modified_count} files successfully!")

if __name__ == '__main__':
    refactor()
