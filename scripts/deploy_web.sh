#!/bin/bash

# ==========================================
# 🚀 Kendo OS: Web Deployment Automation Script (v2.0)
# 🛡️ 哲学: ビルド時に一時的なID置換を行い、終了後にbuild_runnerで完全に再生成する
# ==========================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}   🛡️  Kendo OS Web Deploy Protocol v2.0   ${NC}"
echo -e "${BLUE}==========================================${NC}"

# 1. 強制IDハック (Webビルドを通すためだけの「嘘」)
echo -e "${YELLOW}[1/4] Webビルド用の一時的なID置換を実行中...${NC}"
# 🛡️ 補正：build_runnerによる復元不具合を物理断絶するため、確実に生ファイルをバックアップします
mkdir -p .backup_g_dart
cp lib/shared/infrastructure/persistence/models/*.g.dart .backup_g_dart/

cat << 'EOF' > temp_id_hack.dart
import 'dart:io';
void main() {
  final files = [
    'lib/shared/infrastructure/persistence/models/match_entity.g.dart', 
    'lib/shared/infrastructure/persistence/models/local_stroke_model.g.dart',
    'lib/shared/infrastructure/persistence/models/match_comment_entity.g.dart',
    'lib/shared/infrastructure/persistence/models/match_command_entity.g.dart',
    'lib/shared/infrastructure/persistence/models/match_projection_entity.g.dart'
  ];
  int counter = 100;
  final regex = RegExp(r'id:\s*-?\d{10,20}'); // 全ての巨大IDを対象にする
  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    String content = file.readAsStringSync();
    content = content.replaceAllMapped(regex, (match) => 'id: ${counter++}');
    file.writeAsStringSync(content);
  }
}
EOF
dart run temp_id_hack.dart
rm temp_id_hack.dart
echo -e "${GREEN}✅ 一時置換完了${NC}"

# 2. Webビルド
echo -e "${YELLOW}[2/4] Flutter Web ビルド中...${NC}"
flutter build web --release
BUILD_RESULT=$?

if [ $BUILD_RESULT -ne 0 ]; then
  echo -e "${RED}❌ ビルド失敗。ID復元プロセスに移行します。${NC}"
else
  # 3. Firebase デプロイ
  echo -e "${YELLOW}[3/4] Firebase Hosting へデプロイ中...${NC}"
  firebase deploy --only hosting
fi

# 4. ID復元 (物理バックアップからの確実な復元)
echo -e "${YELLOW}[4/4] 設計図を本物の状態へ復元中 (Backup Restore)...${NC}"
# 🛡️ 補正：build_runnerへの依存を全廃し、0秒で完全な元の状態（巨大ID）へロールバックします
cp .backup_g_dart/*.g.dart lib/shared/infrastructure/persistence/models/
rm -rf .backup_g_dart
echo -e "${GREEN}✅ 物理復元完了${NC}"

if [ $BUILD_RESULT -ne 0 ]; then
  echo -e "${RED}❌ デプロイは中断されましたが、設計図は正常に復元されました。${NC}"
  exit 1
fi

echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN} 🎉 Webデプロイ成功 ＆ 設計図の完全復元が完了しました！${NC}"
echo -e "${GREEN}    これで安全に git push origin stage2-beta を実行できます。${NC}"
echo -e "${GREEN}==========================================${NC}"