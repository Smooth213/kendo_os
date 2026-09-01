#!/usr/bin/env python3
import os
import re

def refactor_phase3_safe():
    lib_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../lib'))
    files = []
    for root, dirs, filenames in os.walk(lib_dir):
        for f in filenames:
            if f.endswith('.dart') and f != 'app_tokens.dart' and '/pdf/' not in f.replace('\\', '/'):
                files.append(os.path.join(root, f))

    val_map = {
        '2': 'AppSpacing.xxs',
        '2.0': 'AppSpacing.xxs',
        '3': 'AppSpacing.xs',
        '3.0': 'AppSpacing.xs',
        '4': 'AppSpacing.xs',
        '4.0': 'AppSpacing.xs',
        '6': 'AppSpacing.subValue',
        '6.0': 'AppSpacing.subValue',
        '8': 'AppSpacing.sm',
        '8.0': 'AppSpacing.sm',
        '9': 'AppSpacing.nano',
        '9.0': 'AppSpacing.nano',
        '10': 'AppSpacing.compact',
        '10.0': 'AppSpacing.compact',
        '12': 'AppSpacing.md',
        '12.0': 'AppSpacing.md',
        '14': 'AppSpacing.modernValue',
        '14.0': 'AppSpacing.modernValue',
        '15': 'AppSpacing.lg',
        '15.0': 'AppSpacing.lg',
        '16': 'AppSpacing.lg',
        '16.0': 'AppSpacing.lg',
        '18': 'AppSpacing.mediumLg',
        '18.0': 'AppSpacing.mediumLg',
        '20': 'AppSpacing.roundValue',
        '20.0': 'AppSpacing.roundValue',
        '24': 'AppSpacing.xl',
        '24.0': 'AppSpacing.xl',
        '32': 'AppSpacing.xxl',
        '32.0': 'AppSpacing.xxl',
        '40': 'AppSpacing.giant',
        '40.0': 'AppSpacing.giant',
        '48': 'AppSpacing.giant',
        '48.0': 'AppSpacing.giant',
        '80': 'AppSpacing.giant * 2',
        '80.0': 'AppSpacing.giant * 2',
        '100': 'AppSpacing.giant * 2.5',
        '100.0': 'AppSpacing.giant * 2.5',
    }

    for f in files:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()

        new_content = content

        def repl_match(m):
            method = m.group(1) # all, symmetric, only, fromLTRB
            args = m.group(2)
            if 'AppSpacing.' in args or 'AppEdgeInsets.' in args:
                return m.group(0)

            def repl_val(vm):
                key = vm.group(1) or ""
                num = vm.group(2)
                if num in ('0', '0.0', '1', '1.0'):
                    return f"{key}{num}"
                sp = val_map.get(num, num)
                return f"{key}{sp}"

            new_args = re.sub(r'([a-zA-Z]+\s*:\s*)?(\d+(?:\.\d+)?)', repl_val, args)
            return f"EdgeInsets.{method}({new_args})"

        new_content = re.sub(r'EdgeInsets\.(all|symmetric|only|fromLTRB)\(([^)]+)\)', repl_match, new_content)

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
    refactor_phase3_safe()
