#!/bin/bash

echo "🚀 最終総ざらい引越しを開始します..."

# ---------------------------------------------
# 1. 新しいディレクトリの作成
# ---------------------------------------------
mkdir -p lib/features/match/application/usecases
mkdir -p lib/features/match/application/mappers
mkdir -p lib/shared/application/projections
mkdir -p lib/shared/application/services
mkdir -p lib/shared/domain/repositories
mkdir -p lib/features/match/domain/score
mkdir -p lib/features/match/domain/rules
mkdir -p lib/features/match/domain/command
mkdir -p lib/features/match/domain/events
mkdir -p lib/features/match/domain/services
mkdir -p lib/shared/domain/entities
mkdir -p lib/features/auth/presentation
mkdir -p lib/admin/presentation/screens
mkdir -p lib/admin/providers
mkdir -p lib/shared/presentation
mkdir -p lib/features/tournament/presentation/operate
mkdir -p lib/features/viewer/presentation
mkdir -p lib/shared/routing
mkdir -p lib/shared/infrastructure

# ---------------------------------------------
# 2. 残存ファイルの大移動
# ---------------------------------------------
mv lib/application/usecases/* lib/features/match/application/usecases/ 2>/dev/null
mv lib/application/mappers/* lib/features/match/application/mappers/ 2>/dev/null
mv lib/application/projections/* lib/shared/application/projections/ 2>/dev/null
mv lib/application/services/* lib/shared/application/services/ 2>/dev/null

mv lib/domain/repositories/* lib/shared/domain/repositories/ 2>/dev/null
mv lib/domain/score/* lib/features/match/domain/score/ 2>/dev/null
mv lib/domain/rules/* lib/features/match/domain/rules/ 2>/dev/null
mv lib/domain/command/* lib/features/match/domain/command/ 2>/dev/null
mv lib/domain/events/* lib/features/match/domain/events/ 2>/dev/null
mv lib/domain/services/* lib/features/match/domain/services/ 2>/dev/null
mv lib/domain/entities/* lib/shared/domain/entities/ 2>/dev/null

mv lib/presentation/auth/* lib/features/auth/presentation/ 2>/dev/null
mv lib/presentation/internal/* lib/admin/presentation/screens/ 2>/dev/null
mv lib/presentation/providers/internal/* lib/admin/providers/ 2>/dev/null
mv lib/presentation/shared/* lib/shared/presentation/ 2>/dev/null
mv lib/presentation/operate/* lib/features/tournament/presentation/operate/ 2>/dev/null
mv lib/presentation/public/viewer/* lib/features/viewer/presentation/ 2>/dev/null
mv lib/presentation/public/operator/* lib/features/tournament/presentation/operate/ 2>/dev/null
mv lib/presentation/routing/* lib/shared/routing/ 2>/dev/null
mv lib/presentation/*.dart lib/shared/routing/ 2>/dev/null

mv lib/infrastructure/* lib/shared/infrastructure/ 2>/dev/null

echo "✅ 全ファイルの移動が完了しました。"

# ---------------------------------------------
# 3. プロジェクト全体の import パス一括置換
# ---------------------------------------------
echo "🔍 importパスを新構造に合わせて一括置換しています..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_CMD="sed -i ''"
else
  SED_CMD="sed -i"
fi

# 代表的なパスのプレフィックスを一括置換
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/application/usecases/|package:kendo_os/features/match/application/usecases/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/application/mappers/|package:kendo_os/features/match/application/mappers/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/application/projections/|package:kendo_os/shared/application/projections/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/application/services/|package:kendo_os/shared/application/services/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/domain/repositories/|package:kendo_os/shared/domain/repositories/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/domain/score/|package:kendo_os/features/match/domain/score/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/domain/rules/|package:kendo_os/features/match/domain/rules/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/domain/command/|package:kendo_os/features/match/domain/command/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/domain/events/|package:kendo_os/features/match/domain/events/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/domain/services/|package:kendo_os/features/match/domain/services/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/domain/entities/|package:kendo_os/shared/domain/entities/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/presentation/auth/|package:kendo_os/features/auth/presentation/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/presentation/internal/|package:kendo_os/admin/presentation/screens/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/presentation/providers/internal/|package:kendo_os/admin/providers/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/presentation/shared/|package:kendo_os/shared/presentation/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/presentation/operate/|package:kendo_os/features/tournament/presentation/operate/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/presentation/public/viewer/|package:kendo_os/features/viewer/presentation/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/presentation/public/operator/|package:kendo_os/features/tournament/presentation/operate/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/presentation/routing/|package:kendo_os/shared/routing/|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/presentation/match_router.dart|package:kendo_os/shared/routing/match_router.dart|g" {} + 2>/dev/null
find lib test apps packages -name "*.dart" -type f -exec $SED_CMD "s|package:kendo_os/infrastructure/|package:kendo_os/shared/infrastructure/|g" {} + 2>/dev/null

# ---------------------------------------------
# 4. 相対パス補正（階層のズレによる破損防止）
# ---------------------------------------------
echo "🔧 相対パスのズレを絶対パスに補正しています..."
fix_relative() {
  local d=$1
  if [ -d "$d" ]; then
    find "$d" -name "*.dart" -type f -exec $SED_CMD "s|import '../../../../../|import 'package:kendo_os/|g" {} + 2>/dev/null
    find "$d" -name "*.dart" -type f -exec $SED_CMD "s|import '../../../../|import 'package:kendo_os/|g" {} + 2>/dev/null
    find "$d" -name "*.dart" -type f -exec $SED_CMD "s|import '../../../|import 'package:kendo_os/|g" {} + 2>/dev/null
    find "$d" -name "*.dart" -type f -exec $SED_CMD "s|import '../../|import 'package:kendo_os/|g" {} + 2>/dev/null
  fi
}
fix_relative "lib/features"
fix_relative "lib/shared"
fix_relative "lib/admin"

# ---------------------------------------------
# 5. 旧アーキテクチャの完全削除 (Step 4.7)
# ---------------------------------------------
echo "🗑️ 空になった旧ディレクトリを削除します..."
rm -rf lib/application 2>/dev/null
rm -rf lib/domain 2>/dev/null
rm -rf lib/presentation 2>/dev/null
rm -rf lib/infrastructure 2>/dev/null

echo "🎉 総ざらい引越しが完了しました！ Phase 4 の全Stepが完了しました！"