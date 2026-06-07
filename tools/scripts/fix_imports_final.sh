--- /dev/null
#!/bin/bash

echo "🔧 大移動に伴う import パスの総仕上げ補正を行います..."

# OSごとのsedコマンドの差分吸収
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_CMD="sed -i ''"
else
  SED_CMD="sed -i"
fi

replace_in_files() {
  local old_str=$1
  local new_str=$2
  find lib test packages apps security -name "*.dart" -type f -exec $SED_CMD "s|${old_str}|${new_str}|g" {} + 2>/dev/null
}

# 1. 個別ファイルの絶対パス補正
replace_in_files "package:kendo_os/providers/match_command_provider.dart" "package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart"
replace_in_files "package:kendo_os/providers/timeline_provider.dart" "package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart"
replace_in_files "package:kendo_os/providers/permission_provider.dart" "package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart"
replace_in_files "package:kendo_os/providers/match_list_provider.dart" "package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart"
replace_in_files "package:kendo_os/screens/home_screen.dart" "package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart"
replace_in_files "package:kendo_os/operate/providers/match_list_provider.dart" "package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart"
replace_in_files "package:kendo_os/operate/providers/role_provider.dart" "package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart"
replace_in_files "import 'shared/providers/" "import 'package:kendo_os/shared/presentation/providers/"

# 2. Entity関連
replace_in_files "package:kendo_os/domain/entities/" "package:kendo_os/shared/domain/entities/"
replace_in_files "import '../../domain/entities/" "import 'package:kendo_os/shared/domain/entities/"
replace_in_files "import '../entities/" "import 'package:kendo_os/shared/domain/entities/"

# 3. Infrastructure関連
replace_in_files "package:kendo_os/infrastructure/" "package:kendo_os/shared/infrastructure/"

# 4. Shared Providers 関連
replace_in_files "package:kendo_os/shared/providers/" "package:kendo_os/shared/presentation/providers/"
replace_in_files "import '../shared/providers/" "import 'package:kendo_os/shared/presentation/providers/"
replace_in_files "import '../../presentation/shared/providers/" "import 'package:kendo_os/shared/presentation/providers/"

# 5. Operate 関連 (Screens, Providers, Components)
replace_in_files "package:kendo_os/operate/providers/" "package:kendo_os/features/tournament/presentation/operate/providers/"
replace_in_files "package:kendo_os/operate/screens/" "package:kendo_os/features/tournament/presentation/operate/screens/"

# 6. Domain Services
replace_in_files "package:kendo_os/domain/services/" "package:kendo_os/features/match/domain/services/"

echo "✅ 補正スクリプトが完了しました！"
