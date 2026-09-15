#!/usr/bin/env python3
import subprocess
import sys


def main():
    command = [
        'flutter',
        'test',
        'test/governance/event_history_partition_governance_test.dart',
        '--reporter=expanded',
    ]
    result = subprocess.run(command, text=True)
    if result.returncode != 0:
        print('イベント履歴分割ガバナンス: FAILED')
        sys.exit(result.returncode)
    print('イベント履歴分割ガバナンス: PASS')


if __name__ == '__main__':
    main()
