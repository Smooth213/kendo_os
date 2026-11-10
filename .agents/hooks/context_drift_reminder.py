#!/usr/bin/env python3
"""Antigravity PreInvocation hook to prevent context drift in long sessions."""

import json
import sys


def main() -> None:
    try:
        raw = sys.stdin.read()
        payload = json.loads(raw) if raw.strip() else {}
    except Exception:
        print(json.dumps({}))
        return

    invocation_num = payload.get("invocationNum")
    if (
        isinstance(invocation_num, int)
        and not isinstance(invocation_num, bool)
        and invocation_num >= 8
        and invocation_num % 8 == 0
    ):
        reminder = (
            f"【KendoOS 規約リマインド (Invocation {invocation_num})】"
            "1. 承認範囲外の編集・調査中の先行修正禁止 / "
            "2. Git変更操作(commit/push等)・デプロイ禁止 / "
            "3. 審判判断代行・タイマー自動終了禁止、Event History不変 / "
            "4. テスト・ガバナンスの弱体化(ignore/skip等)禁止 / "
            "5. 完了前にOuter Loop(全体flutter analyze + run_all_governance.py)を実行し、全ログ確認の上、未確認事項を隠さず報告すること。"
        )
        output = {
            "injectSteps": [
                {
                    "systemMessage": {
                        "systemMessage": reminder,
                    }
                }
            ],
            "terminationBehavior": "",
        }
        print(json.dumps(output, ensure_ascii=False))
        return

    print(json.dumps({}))


if __name__ == "__main__":
    main()
