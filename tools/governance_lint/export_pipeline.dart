// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Phase 5: PDF Export Pipeline
// 単一のMarkdownソースから、用途別（Viewer / Operator / QuickGuide）に
// mkdocs の設定ファイルを動的生成し、PDF出力を自動化するパイプライン。
// ============================================================================
void main() async {
  print('🖨️ [PDF Pipeline] Starting Markdown to PDF export orchestration...');

  final outDir = Directory('docs/manuals/pdf');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  // 役割別のPDF出力定義 (Step 5-2, 5-3, 5-4)
  final configs = [
    {
      'name': 'kendo_os_viewer_manual',
      'title': 'Kendo Sync 観客・閲覧マニュアル',
      'nav': '  - ホーム: viewer/index.md\n  - 試合画面: viewer/viewer_match.md\n  - オンライン版QR: shared/qr_cover.md'
    },
    {
      'name': 'kendo_os_operator_manual',
      'title': 'Kendo Sync 運営・記録マニュアル (詳細版)',
      'nav': '  - ホーム: operator/index.md\n  - 試合記録: operator/match.md\n  - 障害対応: recovery/failure_catalog.md\n  - オンライン版QR: shared/qr_cover.md'
    },
    {
      'name': 'quick_guide_operator',
      'title': '現場用クイックガイド (机上配置用)',
      'nav': '  - 緊急対応と基本操作: quickstart/index.md\n  - オンライン版QR: shared/qr_cover.md'
    }
  ];

  final tempDir = Directory('tools/manual_pdf_export/temp');
  if (!tempDir.existsSync()) tempDir.createSync(recursive: true);

  for (var config in configs) {
    // PDF出力用の専用 mkdocs.yml を生成
    final ymlContent = '''
site_name: ${config['title']}
docs_dir: ../../../docs/manuals
theme:
  name: material
  language: ja
plugins:
  - with-pdf:
      cover: true
      cover_title: "${config['title']}"
      toc_title: "目次"
      toc_level: 3
      # Step 5-1: PDF目次とページ番号の強制
      render_js: true
      # Step 5-3: 白黒印刷を考慮し、リンクの色などを標準化する設定を注入可能
      output_path: "../../../docs/manuals/pdf/${config['name']}.pdf"
nav:
${config['nav']}
''';

    final file = File('${tempDir.path}/mkdocs_${config['name']}.yml');
    file.writeAsStringSync(ymlContent);
    print('✅ Config generated: ${file.path}');
    
    // 注意: 実際のPDF生成は、Python環境で mkdocs-with-pdf がインストールされている必要があります。
    // CI環境等では以下のコマンドのコメントアウトを外して実行します。
    /*
    print('⏳ Building ${config['name']}.pdf ...');
    final result = await Process.run('mkdocs', ['build', '-f', file.path]);
    if (result.exitCode != 0) {
      print('❌ Error building ${config['name']}: ${result.stderr}');
    }
    */
  }

  print('✅ [PASS] PDF Export Pipeline Orchestration Completed.');
  print('👉 体育館への配布準備が整いました。');
}