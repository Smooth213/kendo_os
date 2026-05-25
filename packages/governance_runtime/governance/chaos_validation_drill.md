# Governance Chaos Validation Drill (統治実戦検証ドリル)

ドキュメント体系が、実際のトラブルや複雑な変更要求に対して「統治能力」を発揮するかを検証するためのシナリオです。

## Scenario 1: New Rule Drill (新ルールの追加)
**【状況】** 突然「有効打突の後にガッツポーズをしたら一本を取り消す」というマナー重視の新規ルール追加が要求された。
**【検証項目】**
- `Rule Authoring Guide` に従い、副作用なしに実装可能か。
- `Conflict Resolution Policy` に照らし、既存の `ScoringRule` との競合を正しく定義できるか。

## Scenario 2: Replay Recovery Drill (歴史の修復)
**【状況】** 3日前の大会データで「実はスコア入力が逆だった」という報告があった。
**【検証項目】**
- `Emergency Recovery Procedure` に従い、直接のデータ修正ではなく「補償イベント」による修正フローを導き出せるか。
- `Replay Compatibility Policy` を守りつつ、当時の結果を正確に再現・修正できるか。

## Scenario 3: Authority Conflict Drill (権限の競合)
**【状況】** 記録係の端末と審判主任の端末が、同時に「試合終了」と「Undo」を操作した。
**【検証項目】**
- `Operational Runbook` および `Architecture Invariants` に基づき、どちらが Authoritative（権威）であるかを即座に判断できるか。