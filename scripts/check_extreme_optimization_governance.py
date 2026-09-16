#!/usr/bin/env python3
import subprocess
import sys


def main():
    command = [
        'flutter',
        'test',
        'test/governance/plan4_extreme_optimization_governance_test.dart',
        '--reporter=expanded',
    ]
    result = subprocess.run(command, text=True)
    if result.returncode != 0:
        print('4大極限最適化・安定化ガバナンス: FAILED')
        sys.exit(result.returncode)
    print('4大極限最適化・安定化ガバナンス: PASS')


if __name__ == '__main__':
    main()
