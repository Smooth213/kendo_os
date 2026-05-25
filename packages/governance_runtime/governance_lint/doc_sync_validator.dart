// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Deep Doc Phase 9: Governance Documentation CI Runtime
// kendo_osの「知識基盤」がコードの変更と乖離（Drift）するのを防ぐ最終防衛線。
// CI/CDパイプライン上で実行され、以下のガバナンスルールを強制する。
// ============================================================================
void main(List<String> args) {
  print('🛡️ [Governance CI] Starting Deep Documentation Audit (Phase 9)...');

  final changedFiles = args.expand((e) => e.split(' ')).where((f) => f.trim().isNotEmpty).toList();
  bool hasViolation = false;

  final changedScreens = <String>[];
  bool hasRuleChange = false;
  bool hasManualUpdate = false;
  bool hasScreenshotUpdate = false;

  for (final file in changedFiles) {
    if (file.contains('lib/presentation/') && file.endsWith('_screen.dart')) {
      changedScreens.add(file);
    }
    if (file.contains('lib/domain/rules/')) hasRuleChange = true;
    if (file.startsWith('docs/manuals/') && file.endsWith('.md')) hasManualUpdate = true;
    // ★ Step 4-4: 監視対象を新しいアセットディレクトリに変更
    if (file.contains('assets/manual_images/')) hasScreenshotUpdate = true;
  }

  final manualsDir = Directory('docs/manuals');
  final allManuals = manualsDir.existsSync()
      ? manualsDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.md') && !f.path.contains('templates')).toList()
      : <File>[];

  // ----------------------------------------------------------------------
  // Step 9-1 & 9-2: UI / Screenshot Drift Detection
  // ----------------------------------------------------------------------
  for (final screenFile in changedScreens) {
    final screenName = screenFile.split('/').last.replaceAll('.dart', '');
    final manualExists = allManuals.any((f) => f.readAsStringSync().contains(screenName));
    if (!manualExists) {
      print('❌ [Step 9-1 Violation] Screen modified but no manual covers it: $screenName');
      hasViolation = true;
    }
    if (!hasScreenshotUpdate) {
      print('❌ [UI/Image Sync Violation] UI changed ($screenName), but screenshots in assets/manual_images/ were not updated.');
      print('👉 解決方法: 新しいスクリーンショットを撮影し、 assets/manual_images/ に正しい命名規約（例: ${screenName}_01.png）で配置してください。');
      hasViolation = true;
    }
  }

  // ----------------------------------------------------------------------
  // Step 9-4: Governance Coverage Check
  // ----------------------------------------------------------------------
  if (hasRuleChange && !hasManualUpdate) {
    print('❌ [Step 9-4 Violation] Domain Rules changed but Governance Notes in manuals were not updated.');
    hasViolation = true;
  }

  // ----------------------------------------------------------------------
  // Step 9-3: Broken Cross-reference & Metadata Check
  // ----------------------------------------------------------------------
  final imgRegex = RegExp(r'!\[.*?\]\((.*?)\)');
  // 画像ではない通常のMarkdownリンク [テキスト](リンク先.md) を抽出する正規表現
  final linkRegex = RegExp(r'(?<!\!)\[.*?\]\((.*?\.md)\)');

  for (final file in allManuals) {
    final content = file.readAsStringSync();

    // 1. 画像リンクのチェック
    for (final match in imgRegex.allMatches(content)) {
      final target = match.group(1);
      if (target != null && !target.startsWith('http')) {
        if (!_resolvePath(file, target)) {
          print('❌ [Violation] Broken Image Link in ${file.path} -> $target');
          hasViolation = true;
        }
      }
    }

    // 2. クロスリファレンス（別マニュアルへのリンク）のチェック
    for (final match in linkRegex.allMatches(content)) {
      final target = match.group(1);
      if (target != null && !target.startsWith('http')) {
        if (!_resolvePath(file, target)) {
          print('❌ [Step 9-3 Violation] Broken Cross-reference in ${file.path} -> $target');
          hasViolation = true;
        }
      }
    }

    // 3. Deep Documentation の品質要件 (AI Metadata必須)
    if (!content.contains('ai_metadata:')) {
      print('❌ [Governance Violation] Missing AI Metadata block in ${file.path}');
      hasViolation = true;
    }
  }

  if (hasViolation) {
    print('🚨 [BLOCK] Documentation Governance CI Failed. PR Merge is BLOCKED.');
    print('📖 詳細なポリシーについては以下を参照してください: docs/governance/manual_update_policy.md');
    print('👉 PRのチェックリスト（Documentation Governance Checklist）の項目がすべて完了しているか確認してください。');
    exit(1);
  }

  print('✅ [PASS] Documentation Runtime Governance is fully intact.');
}

bool _resolvePath(File currentFile, String relativePath) {
  try {
    final uri = currentFile.parent.uri.resolve(relativePath);
    return File.fromUri(uri).existsSync();
  } catch (e) {
    return false;
  }
}