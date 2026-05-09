// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Phase 9: Dead Rule Detector
// 定義されているがどこからも使われていない「死んだルール」を検知し、
// ガバナンスの腐敗を防ぐ静的解析スクリプトです。
// ============================================================================
void main() {
  print('🧹 [Phase 9] Running Dead Rule Detector...');
  bool hasDeadRule = false;

  final ruleDir = Directory('lib/domain/rules');
  if (!ruleDir.existsSync()) {
    print('✅ ルールディレクトリが存在しないためスキップします。');
    exit(0);
  }

  // ルールクラスのファイル一覧を取得
  final ruleFiles = ruleDir.listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('_test.dart'));

  // ファクトリやリゾルバなど、ルールを呼び出す側のファイルを読み込む（簡易チェック）
  final factoryFile = File('lib/domain/rules/rule_factory.dart');
  final resolverFile = File('lib/domain/services/kendo_rule_engine.dart');
  
  final factoryContent = factoryFile.existsSync() ? factoryFile.readAsStringSync() : '';
  final resolverContent = resolverFile.existsSync() ? resolverFile.readAsStringSync() : '';
  final allUsageContext = factoryContent + resolverContent;

  for (final file in ruleFiles) {
    final fileName = file.path.split('/').last.replaceAll('.dart', '');
    // rule_factory 等、基盤ファイル自身は除外
    if (fileName == 'rule_factory' || fileName == 'match_rule_interface' || fileName == 'rule_preset' || fileName.contains('config')) {
      continue;
    }

    // ファイル名からキャメルケースのクラス名などを推測して使用されているか簡易検索
    // （完全なAST解析の代わりの簡易ヒューリスティック）
    final classNameParts = fileName.split('_').map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '').toList();
    final assumedClassName = classNameParts.join('');

    if (!allUsageContext.contains(assumedClassName) && !allUsageContext.contains(fileName)) {
      print('⚠️ [Dead Rule Warning] ルール "$assumedClassName" (${file.path}) は RuleFactory や Engine に登録されていない可能性があります。');
      // ※ CIを強制終了（exit(1)）させるほどではないが、リファクタリングの警告として出す
      hasDeadRule = true;
    }
  }

  if (hasDeadRule) {
    print('💡 ガバナンス維持のため、未使用のルールは削除するかアーカイブしてください (see: governance_lifecycle_policy.md)。');
  } else {
    print('✅ No dead rules detected. ガバナンスは健全です。');
  }
  exit(0);
}