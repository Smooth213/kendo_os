#!/bin/bash

echo "🚀 Phase 3.3 (Admin機能) の移行を開始します..."

# 1. 移動先のディレクトリを作成
mkdir -p lib/admin/dashboard

# 2. ファイルを移動
TARGET_FILE="lib/presentation/internal/observability_dashboard_screen.dart"
DEST_FILE="lib/admin/dashboard/observability_dashboard_screen.dart"

if [ -f "$TARGET_FILE" ]; then
  mv "$TARGET_FILE" "$DEST_FILE"
  echo "✅ ファイルを移動しました: $DEST_FILE"
else
  echo "⚠️ $TARGET_FILE が見つかりません。すでに移動済みの可能性があります。"
fi

# 3. プロジェクト全体の import パスを一括修正
echo "🔍 プロジェクト内の import パスを修正しています..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS 用の sed コマンド
  find lib test apps -name "*.dart" -type f -exec sed -i '' 's|package:kendo_os/presentation/internal/observability_dashboard_screen.dart|package:kendo_os/admin/dashboard/observability_dashboard_screen.dart|g' {} +
else
  # Linux 用の sed コマンド
  find lib test apps -name "*.dart" -type f -exec sed -i 's|package:kendo_os/presentation/internal/observability_dashboard_screen.dart|package:kendo_os/admin/dashboard/observability_dashboard_screen.dart|g' {} +
fi

echo "🎉 Phase 3.3 の移行が完了しました！"
