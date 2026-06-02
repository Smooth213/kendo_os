# Rebuild Audit Log
- Target: MatchScreen, Scoreboard
- Status: Optimized
- Strategy:
  1. Scoreboard: 不変部分への const 適用。
  2. MatchScreen: LayoutBuilder分岐による固定レイアウト化でリビルドを抑制。
  3. Viewer: ListView.builder への統一。