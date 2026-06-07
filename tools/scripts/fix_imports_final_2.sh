#!/bin/bash

echo "🔧 最終エラーの補正を開始します..."

# 1. settings_provider.dart などの物理ファイルの移動
# 以前のスクリプトで import パスは shared/presentation/providers に書き換わったが、
# 実ファイルが shared/providers に残ってしまっている問題を修正
if [ -d "lib/shared/providers" ]; then
  mkdir -p lib/shared/presentation/providers
  mv lib/shared/providers/* lib/shared/presentation/providers/ 2>/dev/null
  rm -rf lib/shared/providers
  echo "✅ shared/providers のファイルを shared/presentation/providers へ移動しました"
fi

# 2. TimelineEvent の import パス補正
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s|import '../entities/timeline_item.dart';|import 'package:kendo_os/shared/domain/entities/timeline_item.dart';|g" lib/features/match/domain/events/timeline_event.dart 2>/dev/null
else
  sed -i "s|import '../entities/timeline_item.dart';|import 'package:kendo_os/shared/domain/entities/timeline_item.dart';|g" lib/features/match/domain/events/timeline_event.dart 2>/dev/null
fi

echo "✅ エラー補正が完了しました！"