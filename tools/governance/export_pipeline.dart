// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Phase 5: PDF Export Pipeline
// 単一のMarkdownソースから、用途別（Viewer / Operator / QuickGuide）に
// mkdocs の設定ファイルを動的生成し、PDF出力を自動化するパイプライン。
// ============================================================================
void main() async {
  print('🖨️ [PDF Pipeline] Starting Markdown to PDF export...');

  final outDir = Directory('docs/manuals/pdf');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final configs = <Map<String, dynamic>>[
    {
      'name': 'kendo_os_viewer_manual',
      'title': 'Kendo Sync 観客・閲覧マニュアル',
      'nav': <String>[
        '  - ホーム: viewer/index.md',
        '  - 試合画面: viewer/viewer_match.md',
        '  - オンライン版QR: shared/qr_cover.md',
      ],
    },
    {
      'name': 'kendo_os_operator_manual',
      'title': 'Kendo Sync 運営・記録マニュアル (詳細版)',
      'nav': <String>[
        '  - ホーム: operator/index.md',
        '  - 試合記録: operator/match.md',
        '  - 障害対応: recovery/failure_catalog.md',
        '  - オンライン版QR: shared/qr_cover.md',
      ],
    },
    {
      'name': 'quick_guide_operator',
      'title': '現場用クイックガイド (机上配置用)',
      'nav': <String>[
        '  - 緊急対応と基本操作: quickstart/index.md',
        '  - オンライン版QR: shared/qr_cover.md',
      ],
    },
  ];

  final tempDir = Directory('tools/manual_pdf_export/temp');
  if (!tempDir.existsSync()) {
    tempDir.createSync(recursive: true);
  }

  for (final config in configs) {
    final name = config['name'] as String;
    final title = config['title'] as String;
    final navList = config['nav'] as List<String>;
    final navContent = navList.join('\n');

    final ymlLines = <String>[
      'site_name: $title',
      'docs_dir: ../../../docs/manuals',
      'theme:',
      '  name: material',
      '  language: ja',
      'plugins:',
      '  - with-pdf:',
      '      cover: true',
      '      cover_title: "$title"',
      '      toc_title: "目次"',
      '      toc_level: 3',
      '      render_js: true',
      '      output_path: "../../../docs/manuals/pdf/$name.pdf"',
      'nav:',
      navContent,
    ];

    final file = File('${tempDir.path}/mkdocs_$name.yml');
    file.writeAsStringSync('${ymlLines.join('\n')}\n');
    print('✅ Config generated: ${file.path}');
  }

  print('✅ [PASS] PDF Export Pipeline Completed.');
}
