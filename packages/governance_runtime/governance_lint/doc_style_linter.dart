// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';

// ============================================================================
// Phase 4: Appliance Quality Document Linter
// エンドユーザー向けマニュアルの文体が「家電メーカー品質」を満たしているか監査する。
// ※開発者向けの設計ドキュメントや、Markdownの表(Table)は監査から除外する。
// ============================================================================
void main() {
  print('📝 [Doc Style Linter] Starting Appliance Quality Audit...');
  
  final manualsDir = Directory('docs/manuals');
  final mdFiles = manualsDir.listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.md') && !f.path.contains('templates'));

  bool hasViolation = false;

  final ngWords = {
    'Projection': '表示データ',
    'Replay': '試合履歴の再構築',
    'Event sourcing': '試合記録方式',
    'Aggregate': '試合データ',
    'Event Queue': '同期待ち',
    'UI': '画面（または操作画面）'
  };

  // 監査対象外（開発者・管理者向け）のファイルリスト
  final excludeFromAudit = [
    'forbidden_words.md',
    'observability_dashboard.md',
    'style_guide.md',
    'audience_matrix.md',
    'screen_mapping.md',
    'screen_inventory.md',
    'navigation_tree.md',
    'personas.md',
    'image_mapping.md',
    'docs/manuals/index.md', // ルートのindexはメタファイル
  ];

  for (final file in mdFiles) {
    // 対象外ファイル、またはgovernanceディレクトリは完全にスキップ
    if (excludeFromAudit.any((ex) => file.path.endsWith(ex)) || file.path.contains('/governance/')) continue;
    
    final lines = file.readAsLinesSync();
    int lineNumber = 0;
    bool inCodeBlock = false;
    bool inMetadataBlock = false;

    for (final line in lines) {
      lineNumber++;
      
      // YAMLメタデータやコードブロック内部はスキップ
      if (line.trim() == '---') {
        inMetadataBlock = !inMetadataBlock;
        continue;
      }
      if (inMetadataBlock) continue;
      if (line.startsWith('```')) {
        inCodeBlock = !inCodeBlock;
        continue;
      }
      // コードブロック内、見出し、画像、または表(Table)の行はスキップ
      if (inCodeBlock || line.startsWith('#') || line.startsWith('![') || line.trim().startsWith('|')) {
        continue;
      }

      // 1. NGワードチェック
      ngWords.forEach((ng, ok) {
        // UIなどの短い単語がURL等に誤爆しないよう、単語境界を意識した正規表現でチェック
        final regExp = RegExp(r'\b' + RegExp.escape(ng) + r'\b', caseSensitive: false);
        if (regExp.hasMatch(line)) {
          print('❌ [NG Word Violation] ${file.path}:$lineNumber\n   Found "$ng". Please use "$ok".');
          hasViolation = true;
        }
      });

      // 2. 1文40文字以内チェック
      final plainText = line.replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '').replaceAll(RegExp(r'[*`_]'), '').trim();
      final sentences = plainText.split('。');
      for (final sentence in sentences) {
        if (sentence.trim().length > 40) {
          print('⚠️ [Length Warning] ${file.path}:$lineNumber\n   Sentence exceeds 40 chars: "${sentence.trim().substring(0, min(20, sentence.trim().length))}..."');
        }
      }
    }
  }

  if (hasViolation) {
    print('🚨 [BLOCK] Appliance Quality Audit Failed. Fix NG words.');
    exit(1);
  } else {
    print('✅ [PASS] All end-user manuals met Appliance Quality Standards.');
  }
}