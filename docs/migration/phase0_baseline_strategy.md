# Phase 0: Baseline Strategy

## 目的
ガバナンスのコアファイル（憲法など）のハッシュ値を固定し、意図しない変更を検知できるようにする。また、リプレイテストの基準となるゴールデンファイルを凍結し、歴史の破壊を防止する。

## 実施内容
1. **Baseline Governance Hashの生成:** 
   - `dart scripts/generate_baseline_hash.dart` を実行し、ガバナンスファイルのハッシュを算出。
2. **Hashの固定:**
   - `governance/baseline_hashes.json` にハッシュを保存。
3. **Golden Replay の固定:**
   - `test/golden_replays/standard_scenarios.dart`
   - `test/golden/historic_events_archive.dart`
   - これらのファイルを凍結し、AIや人間による勝手な更新を禁止する。

## 完了条件
上記の全てのファイルが生成・凍結され、回帰テストが通る状態になること。