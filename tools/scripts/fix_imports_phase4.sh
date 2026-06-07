#!/bin/bash

echo "🔧 残存する import エラー（URI doesn't exist）を補正します..."

# 実行環境による sed コマンドの差異を吸収する関数
replace_in_file() {
  local target_file=$1
  local old_path=$2
  local new_path=$3
  if [ -f "$target_file" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s|${old_path}|${new_path}|g" "$target_file"
    else
      sed -i "s|${old_path}|${new_path}|g" "$target_file"
    fi
  fi
}
replace_in_dir() {
  local target_dir=$1
  local old_path=$2
  local new_path=$3
  if [ -d "$target_dir" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      find "$target_dir" -name "*.dart" -type f -exec sed -i '' "s|${old_path}|${new_path}|g" {} +
    else
      find "$target_dir" -name "*.dart" -type f -exec sed -i "s|${old_path}|${new_path}|g" {} +
    fi
  fi
}

# エラーログに基づく具体的なパスの補正
replace_in_file "lib/application/services/pdf_service.dart" "import 'pdf/" "import 'package:kendo_os/features/pdf/"
replace_in_dir "lib/features/viewer" "import '../../operate/screens/kachinuki_scoreboard_screen.dart';" "import 'package:kendo_os/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart';"
replace_in_dir "lib/features/viewer" "import '../../operate/" "import 'package:kendo_os/presentation/operate/"
replace_in_dir "lib/features/viewer" "import '../../shared/" "import 'package:kendo_os/presentation/shared/"
replace_in_file "lib/presentation/operate/screens/bunaiksen_official_record_screen.dart" "import 'kachinuki_scoreboard_screen.dart';" "import 'package:kendo_os/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart';"
replace_in_dir "packages/replay_engine" "package:kendo_os/domain/match/" "package:kendo_os/features/match/domain/"

echo "✅ import エラーの補正が完了しました！"