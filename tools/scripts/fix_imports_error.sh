#!/bin/bash

echo "🔧 インポートエラー（Error.txt）の最終補正を行います..."

# 置換関数
replace_in_files() {
  local old_str=$1
  local new_str=$2
  if [[ "$OSTYPE" == "darwin"* ]]; then
    find lib test packages apps -name "*.dart" -type f -exec sed -i '' "s|${old_str}|${new_str}|g" {} + 2>/dev/null
  else
    find lib test packages apps -name "*.dart" -type f -exec sed -i "s|${old_str}|${new_str}|g" {} + 2>/dev/null
  fi
}

# 1. KendoRuleEngine 関連の補正
replace_in_files "import 'kendo_rule_engine.dart';" "import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';"
replace_in_files "package:kendo_os/domain/services/kendo_rule_engine.dart" "package:kendo_os/features/match/domain/services/kendo_rule_engine.dart"

# 2. ScoreEvent 関連の補正
replace_in_files "package:kendo_os/domain/score/score_event.dart" "package:kendo_os/features/match/domain/score/score_event.dart"

# 3. standings_calculator 関連
replace_in_files "import 'standings_calculator.dart';" "import 'package:kendo_os/domain/services/standings_calculator.dart';"

# 4. PDF モデルの参照ズレ補正
replace_in_files "package:kendo_os/models/pdf_point_data.dart" "package:kendo_os/features/pdf/models/pdf_point_data.dart"
replace_in_files "package:kendo_os/models/pdf_view_model.dart" "package:kendo_os/features/pdf/models/pdf_view_model.dart"

# 5. 各種 Provider の絶対パス補正
replace_in_files "package:kendo_os/providers/bunaiksen_provider.dart" "package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart"
replace_in_files "package:kendo_os/providers/match_rule_provider.dart" "package:kendo_os/features/match/presentation/providers/match_rule_provider.dart"
replace_in_files "package:kendo_os/providers/settings_provider.dart" "package:kendo_os/shared/providers/settings_provider.dart"
replace_in_files "package:kendo_os/providers/match_view_model_provider.dart" "package:kendo_os/features/match/presentation/providers/match_view_model_provider.dart"

# 6. 各種 Provider の相対パス（壊れたもの）を絶対パスへ強制上書き
replace_in_files "import '../../providers/match_rule_provider.dart';" "import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';"
replace_in_files "import '../../providers/settings_provider.dart';" "import 'package:kendo_os/shared/providers/settings_provider.dart';"
replace_in_files "import '../providers/bunaiksen_provider.dart';" "import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';"
replace_in_files "import '../providers/settings_provider.dart';" "import 'package:kendo_os/shared/providers/settings_provider.dart';"
replace_in_files "import '../providers/match_view_model_provider.dart';" "import 'package:kendo_os/features/match/presentation/providers/match_view_model_provider.dart';"
replace_in_files "import '../providers/match_rule_provider.dart';" "import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';"
replace_in_files "import 'bunaiksen_provider.dart';" "import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';"
replace_in_files "import 'match_rule_provider.dart';" "import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';"
replace_in_files "import 'settings_provider.dart';" "import 'package:kendo_os/shared/providers/settings_provider.dart';"

echo "✅ エラーの補正が完了しました！"
