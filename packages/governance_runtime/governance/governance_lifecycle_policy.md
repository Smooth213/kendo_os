# Governance Lifecycle Policy (ガバナンス・ライフサイクル規約)

ドキュメントやルールが時間とともに形骸化・腐敗することを防ぐための、永続運用のポリシーです。

## 1. Dead Rule & Unused Policy の排除 (Step 9-4, 9-5)
- **Dead Rule の定義:** `lib/domain/rules/` に存在するが、`RuleFactory` や `RuleResolver` に登録されておらず、どの設定（Config）からも呼び出されないルール。
- **ポリシー:** Dead Rule や参照されなくなった古い ADR は、発見次第直ちに削除、または `why_not_archive.md` に理由を添えてアーカイブしなければなりません。

## 2. Governance Versioning (Step 9-6)
- すべてのガバナンスドキュメント（ADR、Constitution）は、ファイル名やヘッダーでバージョンまたは「Accepted Date」を明記します。
- 破壊的変更（Replay意味論の変更）を伴う更新を行う場合は、既存のドキュメントを直接上書きせず、新しい版の ADR を作成し、旧版を「Superseded（置き換え済み）」ステータスに変更します。

## 3. Long-term Archive Policy (Step 9-7)
- 廃止されたドメイン知識や不採用となった設計案は、コードベースから完全に削除する前に `docs/governance/why_not_archive.md` へ歴史的コンテキストとして記録します。これにより、未来のAIや開発者が「同じ過ち（車輪の再発明）」を繰り返すことを防ぎます。