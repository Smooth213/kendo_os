#!/usr/bin/env python3
import os
import re

def refactor_phase2_perfect():
    lib_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../lib'))
    files = []
    for root, dirs, filenames in os.walk(lib_dir):
        for f in filenames:
            if f.endswith('.dart') and f != 'app_tokens.dart':
                files.append(os.path.join(root, f))

    val_to_app_radius = {
        2: 'AppRadius.micro',
        3: 'AppRadius.tiny',
        4: 'AppRadius.tiny',
        6: 'AppRadius.sub',
        7: 'AppRadius.sub',
        8: 'AppRadius.small',
        10: 'AppRadius.compact',
        11: 'AppRadius.smooth',
        12: 'AppRadius.medium',
        14: 'AppRadius.modern',
        16: 'AppRadius.large',
        20: 'AppRadius.round',
        24: 'AppRadius.xlarge',
        28: 'AppRadius.huge',
        32: 'AppRadius.giant',
        999: 'AppRadius.full',
    }

    val_to_radius_val = {
        2: 'Radius.circular(AppRadius.microValue)',
        3: 'Radius.circular(AppRadius.tinyValue)',
        4: 'Radius.circular(AppRadius.tinyValue)',
        6: 'Radius.circular(AppRadius.subValue)',
        7: 'Radius.circular(AppRadius.subValue)',
        8: 'Radius.circular(AppRadius.smallValue)',
        10: 'Radius.circular(AppRadius.compactValue)',
        11: 'Radius.circular(AppRadius.smoothValue)',
        12: 'Radius.circular(AppRadius.mediumValue)',
        14: 'Radius.circular(AppRadius.modernValue)',
        16: 'Radius.circular(AppRadius.largeValue)',
        20: 'Radius.circular(AppRadius.roundValue)',
        24: 'Radius.circular(AppRadius.xlargeValue)',
        28: 'Radius.circular(AppRadius.hugeValue)',
        32: 'Radius.circular(AppRadius.giantValue)',
        999: 'Radius.circular(AppRadius.fullValue)',
    }

    for f in files:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()

        new_content = content
        if 'package:pdf/' not in content and 'import \'package:pdf/' not in content and 'pw.' not in content:
            def repl_br(match):
                num = int(match.group(1))
                return val_to_app_radius.get(num, f'BorderRadius.circular({num})')

            def repl_r(match):
                num = int(match.group(1))
                return val_to_radius_val.get(num, f'Radius.circular({num})')

            # \s* には改行も含む
            new_content = re.sub(r'BorderRadius\.circular\(\s*(\d+)\s*,?\s*\)', repl_br, new_content)
            new_content = re.sub(r'Radius\.circular\(\s*(\d+)\s*,?\s*\)', repl_r, new_content)

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

if __name__ == '__main__':
    refactor_phase2_perfect()
