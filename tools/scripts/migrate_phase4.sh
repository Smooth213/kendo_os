#!/bin/bash

echo "🚀 Phase 4 (機能別モジュール) の移行を開始します..."

# 1. 移行先のディレクトリを作成
mkdir -p lib/features/match/domain
mkdir -p lib/features/pdf
mkdir -p lib/features/viewer
mkdir -p lib/features/tournament/presentation/screens

# 2. ファイルの移動
echo "📦 ファイルを新アーキテクチャへ移動中..."

# Match Feature (ドメイン層)
if [ -d "lib/domain/match" ] && [ "$(ls -A lib/domain/match 2>/dev/null)" ]; then
  mv lib/domain/match/* lib/features/match/domain/
  rm -rf lib/domain/match
  echo "✅ Match Feature のドメインモデルを移動しました"
fi

# PDF Feature
if [ -d "lib/application/services/pdf" ] && [ "$(ls -A lib/application/services/pdf 2>/dev/null)" ]; then
  mv lib/application/services/pdf/* lib/features/pdf/
  rm -rf lib/application/services/pdf
  echo "✅ PDF Feature を移動しました"
fi

# Viewer Feature
if [ -d "lib/presentation/viewer" ] && [ "$(ls -A lib/presentation/viewer 2>/dev/null)" ]; then
  mv lib/presentation/viewer/* lib/features/viewer/
  rm -rf lib/presentation/viewer
  echo "✅ Viewer Feature を移動しました"
fi

# Tournament Feature (Screens)
if [ -f "lib/presentation/operate/screens/kachinuki_scoreboard_screen.dart" ]; then
  mv lib/presentation/operate/screens/kachinuki_scoreboard_screen.dart lib/features/tournament/presentation/screens/
  echo "✅ KachinukiScoreboardScreen を移動しました"
fi
if [ -f "lib/presentation/operate/screens/standings_screen.dart" ]; then
  mv lib/presentation/operate/screens/standings_screen.dart lib/features/tournament/presentation/screens/
  echo "✅ StandingsScreen を移動しました"
fi

# 3. プロジェクト全体の import パスを絶対パスで一括置換
echo "🔍 プロジェクト全体の import パスを修正しています..."
replace_import() {
  local old_path=$1
  local new_path=$2
  if [[ "$OSTYPE" == "darwin"* ]]; then
    find lib test apps -name "*.dart" -type f -exec sed -i '' "s|${old_path}|${new_path}|g" {} + 2>/dev/null
  else
    find lib test apps -name "*.dart" -type f -exec sed -i "s|${old_path}|${new_path}|g" {} + 2>/dev/null
  fi
}

replace_import "package:kendo_os/domain/match/" "package:kendo_os/features/match/domain/"
replace_import "package:kendo_os/application/services/pdf/" "package:kendo_os/features/pdf/"
replace_import "package:kendo_os/presentation/viewer/" "package:kendo_os/features/viewer/"
replace_import "package:kendo_os/presentation/operate/screens/kachinuki_scoreboard_screen.dart" "package:kendo_os/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart"
replace_import "package:kendo_os/presentation/operate/screens/standings_screen.dart" "package:kendo_os/features/tournament/presentation/screens/standings_screen.dart"

# 4. 移動したファイル内部の「相対インポート」が階層変更によって壊れるのを防ぐため、絶対パスへ変換
echo "🔧 移動先ファイルの相対 import のズレを補正しています..."
fix_relative_imports() {
  local target_dir=$1
  if [ -d "$target_dir" ] || [ -f "$target_dir" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # 階層を遡る相対パスをすべて package:kendo_os/ の絶対パスに置換
      find "$target_dir" -name "*.dart" -type f -exec sed -i '' "s|import '../../../../|import 'package:kendo_os/|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i '' "s|import '../../../|import 'package:kendo_os/|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i '' "s|import '../../|import 'package:kendo_os/|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i '' "s|import '../rules|import 'package:kendo_os/domain/rules|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i '' "s|import '../entities|import 'package:kendo_os/domain/entities|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i '' "s|import '../score|import 'package:kendo_os/domain/score|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i '' "s|import '../providers/|import 'package:kendo_os/presentation/operate/providers/|g" {} + 2>/dev/null
    else
      find "$target_dir" -name "*.dart" -type f -exec sed -i "s|import '../../../../|import 'package:kendo_os/|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i "s|import '../../../|import 'package:kendo_os/|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i "s|import '../../|import 'package:kendo_os/|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i "s|import '../rules|import 'package:kendo_os/domain/rules|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i "s|import '../entities|import 'package:kendo_os/domain/entities|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i "s|import '../score|import 'package:kendo_os/domain/score|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i "s|import '../providers/|import 'package:kendo_os/presentation/operate/providers/|g" {} + 2>/dev/null
    fi
  fi
}

fix_relative_imports "lib/features/match/domain"
fix_relative_imports "lib/features/pdf"
fix_relative_imports "lib/features/tournament/presentation/screens"

echo "🎉 Phase 4 の移行スクリプトが完了しました！"