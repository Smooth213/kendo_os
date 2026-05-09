// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Phase 7: Documentation Sync Validator
// Pull Request内でコードが変更された際、対応するドキュメントが更新されているかを監査します。
// 違反した場合はCIをFailさせ、未ドキュメント化の変更がマージされるのを物理的に阻止します。
// ============================================================================
void main(List<String> args) {
  print('🛡️ [Doc Sync Validator] Auditing PR for documentation synchronization...');

  if (args.isEmpty) {
    print('✅ No changed files provided. Skipping audit.');
    return;
  }

  // CIから渡された変更ファイルリストを取得
  final changedFiles = args.expand((e) => e.split(' ')).where((f) => f.trim().isNotEmpty).toList();

  bool hasScreenChange = false;
  bool hasRuleChange = false;
  bool hasManualUpdate = false;
  bool hasGovernanceUpdate = false;

  for (final file in changedFiles) {
    if (file.contains('lib/presentation/') && file.endsWith('_screen.dart')) hasScreenChange = true;
    if (file.contains('lib/domain/rules/')) hasRuleChange = true;
    
    if (file.startsWith('docs/manuals/')) hasManualUpdate = true;
    if (file.startsWith('docs/governance/')) hasGovernanceUpdate = true;
  }

  bool hasViolation = false;

  // Rule 1: 画面(Screen)が変更されたら、マニュアル(Manuals)の変更が必須
  if (hasScreenChange && !hasManualUpdate) {
    print('❌ [VIOLATION] 画面ファイル (*_screen.dart) が変更されていますが、docs/manuals/ 配下のマニュアルが更新されていません。');
    print('👉 Requirement: UI changes require documentation review/updates.');
    hasViolation = true;
  }

  // Rule 2: 競技ルール(Rules)が変更されたら、ガバナンスドキュメントの変更が必須
  if (hasRuleChange && !hasGovernanceUpdate) {
    print('❌ [VIOLATION] ドメインルール (lib/domain/rules/) が変更されていますが、docs/governance/ 配下が更新されていません。');
    print('👉 Requirement: Rule changes must be reflected in governance documentation.');
    hasViolation = true;
  }

  if (hasViolation) {
    print('🚨 [BLOCK] Documentation Synchronization Audit Failed. マージは許可されません。');
    exit(1); // CIをFailさせる
  }

  print('✅ [PASS] コードとドキュメントの同期が確認されました（Documentation is synchronized）。');
}