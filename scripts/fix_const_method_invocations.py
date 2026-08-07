#!/usr/bin/env python3
import os
import re

def fix_const_method_invocations():
    lib_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../lib'))
    files = []
    for root, dirs, filenames in os.walk(lib_dir):
        for f in filenames:
            if f.endswith('.dart'):
                files.append(os.path.join(root, f))

    for f in files:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()

        new_content = content
        # withValues や withAlpha が含まれる const コンストラクタ呼び出しから const を除去
        new_content = re.sub(r'const\s+([A-Z][a-zA-Z0-9_]*\(\s*[^)]*withValues[^)]*\))', r'\1', new_content)
        new_content = re.sub(r'const\s+([A-Z][a-zA-Z0-9_]*\(\s*[^)]*withAlpha[^)]*\))', r'\1', new_content)
        # const [ ... withValues ... ] 配列リテラルから const を除去
        new_content = re.sub(r'const\s*(\[\s*[^\]]*withValues[^\]]*\])', r'\1', new_content)

        if new_content != content:
            with open(f, 'w', encoding='utf-8') as file:
                file.write(new_content)

if __name__ == '__main__':
    fix_const_method_invocations()
