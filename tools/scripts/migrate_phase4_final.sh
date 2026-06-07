#!/bin/bash

echo "🚀 Phase 4 最終補完（残存ファイルの移行）を開始します..."

# 1. 移行先のディレクトリを作成
mkdir -p lib/features/pdf
mkdir -p lib/features/match/domain/services
mkdir -p lib/features/match/domain/score
mkdir -p lib/features/match/application/mappers
mkdir -p lib/features/match/presentation/providers
mkdir -p lib/features/tournament/domain/services
mkdir -p lib/features/tournament/presentation/providers
mkdir -p lib/features/tournament/presentation/screens
mkdir -p lib/shared/providers

# 2. 残存ファイルの移動
echo "📦 ファイルを新アーキテクチャへ移動中..."

mv lib/application/services/pdf_service.dart lib/features/pdf/ 2>/dev/null
mv lib/domain/services/kendo_rule_engine.dart lib/features/match/domain/services/ 2>/dev/null

# ScoreEventは関連する生成ファイル（.freezed.dart, .g.dartなど）もまとめて移動
mv lib/domain/score/score_event* lib/features/match/domain/score/ 2>/dev/null

mv lib/application/mappers/match_projection_mapper.dart lib/features/match/application/mappers/ 2>/dev/null
mv lib/presentation/operate/providers/match_rule_provider.dart lib/features/match/presentation/providers/ 2>/dev/null
mv lib/presentation/operate/providers/match_view_model_provider.dart lib/features/match/presentation/providers/ 2>/dev/null
mv lib/presentation/operate/screens/bunaiksen_official_record_screen.dart lib/features/tournament/presentation/screens/ 2>/dev/null
mv lib/domain/services/bunaiksen_helper.dart lib/features/tournament/domain/services/ 2>/dev/null
mv lib/presentation/operate/providers/bunaiksen_provider.dart lib/features/tournament/presentation/providers/ 2>/dev/null
mv lib/presentation/operate/providers/settings_provider.dart lib/shared/providers/ 2>/dev/null

echo "✅ ファイルの移動が完了しました。"

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

# パスの置換（厳密なマッチング）
replace_import "package:kendo_os/application/services/pdf_service.dart" "package:kendo_os/features/pdf/pdf_service.dart"
replace_import "package:kendo_os/domain/services/kendo_rule_engine.dart" "package:kendo_os/features/match/domain/services/kendo_rule_engine.dart"
replace_import "package:kendo_os/domain/score/score_event.dart" "package:kendo_os/features/match/domain/score/score_event.dart"
replace_import "package:kendo_os/application/mappers/match_projection_mapper.dart" "package:kendo_os/features/match/application/mappers/match_projection_mapper.dart"
replace_import "package:kendo_os/presentation/operate/providers/match_rule_provider.dart" "package:kendo_os/features/match/presentation/providers/match_rule_provider.dart"
replace_import "package:kendo_os/presentation/operate/providers/match_view_model_provider.dart" "package:kendo_os/features/match/presentation/providers/match_view_model_provider.dart"
replace_import "package:kendo_os/presentation/operate/screens/bunaiksen_official_record_screen.dart" "package:kendo_os/features/tournament/presentation/screens/bunaiksen_official_record_screen.dart"
replace_import "package:kendo_os/domain/services/bunaiksen_helper.dart" "package:kendo_os/features/tournament/domain/services/bunaiksen_helper.dart"
replace_import "package:kendo_os/presentation/operate/providers/bunaiksen_provider.dart" "package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart"
replace_import "package:kendo_os/presentation/operate/providers/settings_provider.dart" "package:kendo_os/shared/providers/settings_provider.dart"

# 4. 相対パスの破壊を防止するための絶対パス補正
echo "🔧 移動先ファイルの相対 import のズレを補正しています..."
fix_relative_imports() {
  local target_dir=$1
  if [ -d "$target_dir" ] || [ -f "$target_dir" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      find "$target_dir" -name "*.dart" -type f -exec sed -i '' "s|import '../../../../|import 'package:kendo_os/|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i '' "s|import '../../../|import 'package:kendo_os/|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i '' "s|import '../../|import 'package:kendo_os/|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i '' "s|import '../|import 'package:kendo_os/|g" {} + 2>/dev/null
    else
      find "$target_dir" -name "*.dart" -type f -exec sed -i "s|import '../../../../|import 'package:kendo_os/|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i "s|import '../../../|import 'package:kendo_os/|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i "s|import '../../|import 'package:kendo_os/|g" {} + 2>/dev/null
      find "$target_dir" -name "*.dart" -type f -exec sed -i "s|import '../|import 'package:kendo_os/|g" {} + 2>/dev/null
    fi
  fi
}

fix_relative_imports "lib/features/pdf"
fix_relative_imports "lib/features/match"
fix_relative_imports "lib/features/tournament"
fix_relative_imports "lib/shared/providers"

echo "🎉 Phase 4 の最終補完スクリプトが完了しました！"

echo "================================================="
echo "📋 現在の旧ディレクトリに残っているファイルの確認:"
echo "-------------------------------------------------"
find lib/application lib/domain lib/presentation lib/infrastructure -type f 2>/dev/null || echo "（ファイルは見つかりませんでした）"
echo "================================================="
echo "もし上記に何も表示されなければ、いよいよ Step 4.7（旧ディレクトリの削除）が可能です！"