## 🛡 Governance Enforcement PR

### 1. 変更の概要
（何を変更したのか、なぜ変更が必要なのかを記載してください）

### 2. Risk Classification (リスク分類)
*該当するものを1つ選択してください*
- [ ] **Critical** (イベント構造・コアルールエンジンの変更)
- [ ] **Medium** (新規ルール追加・ドメインロジックの追加)
- [ ] **Low** (UIのみの変更・単純なリファクタリング)

### 3. Impact Analysis (影響分析)
- **Replay Impact:** （既存の過去データのリプレイ結果に影響を与えないことをどう証明しましたか？）
- **Rule Impact:** （既存のルールやルールの評価順序に悪影響を与えませんか？）
- **Event Impact:** （発行されるイベントの形や意味にサイレントな変更はありませんか？）

### 4. Governance Checklist
- [ ] `DateTime.now()` や Random()、IOアクセスをドメイン層に混入させていない。
- [ ] `static mutable` などの隠れた状態を持たせていない。
- [ ] `flutter test test/integration/replay_regression_test.dart` がローカルで成功している。