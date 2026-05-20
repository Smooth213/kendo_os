# Stage 2 β Release Checklist

本ドキュメントは、Kendo Sync（剣道OS）の Stage2 βリリース前に確認すべき最終チェックリストです。

## 最終テスト要件

リリース前に必ず以下のコマンドを実行し、すべてのテストがパスすることを確認してください。

- [x] `flutter test`
- [x] `flutter test --coverage`
- [x] `flutter test test/integration/` (Chaos suite)

## 最終公開条件 (Release Gates)

以下の条件がすべて満たされている場合のみ、Stage 2 β の公開が可能となります。

| 条件 | 必須 | 状態 |
| :--- | :---: | :---: |
| replay deterministic | YES | ✅ |
| DateTime.now 0件 | YES | ✅ |
| corrupted state安全化 | YES | ✅ |
| timeline replay | YES | ✅ |
| AI CI enforcement | YES | ✅ |
| chaos pass | YES | ✅ |

上記のすべてのテストと条件がクリアされた時点で、Stage 2 β公開の手続きに進むことができます。