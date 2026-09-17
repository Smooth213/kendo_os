#!/usr/bin/env python3
import subprocess
import sys


def main():
    command = [
        'flutter',
        'test',
        'test/governance/plan7_perfection_governance_test.dart',
        '--reporter=expanded',
    ]
    result = subprocess.run(command, text=True)
    if result.returncode != 0:
        print('Plan 7 極限最適化・低負荷・絶対安定性 完走ガバナンス: FAILED')
        sys.exit(result.returncode)
    print('Plan 7 極限最適化・低負荷・絶対安定性 完走ガバナンス: PASS')


if __name__ == '__main__':
    main()
