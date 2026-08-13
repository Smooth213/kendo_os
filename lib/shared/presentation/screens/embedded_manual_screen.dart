import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart' deferred as md;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:documentation_runtime/manual_routes.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kendo_os/shared/infrastructure/services/manual_download_service.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';

// ============================================================================
// Phase 5 & 6: Embedded Documentation Viewer (Upgraded for Smart Print & Help Hub)
// アプリ内に同梱されたMarkdownマニュアルおよび高精細PDFマニュアルの閲覧・検索・印刷画面
// AIメタデータの除外処理およびレスポンシブ対応（スマホ/iPad）を含む
// ============================================================================

// ★ Step 6-1: 新しい全文検索インデックス (manual_search_index.json) を読み込む
final manualIndexProvider = FutureProvider<List<dynamic>>((ref) async {
  final jsonString = await rootBundle.loadString(
    'packages/documentation_runtime/manuals/manual_search_index.json',
  );
  final decoded = jsonDecode(jsonString);

  // 新しいList形式の場合
  if (decoded is List) {
    return decoded;
  }
  // 古いMap形式（以前のロードマップの遺物）が残っていた場合のフェイルセーフ（自動変換）
  else if (decoded is Map) {
    return decoded.entries
        .map(
          (e) => {
            'path': e.key,
            'title': e.value['title'] ?? '無題',
            'headings': [],
            'tags': e.value['keywords'] ?? [],
          },
        )
        .toList();
  }

  return [];
});

class EmbeddedManualScreen extends ConsumerStatefulWidget {
  final String? initialFilePath;
  final String? initialSearchQuery;
  final int? initialTab; // ★ 0: 通常クイック, 1: 部内戦クイック, 2: 総合マニュアル

  const EmbeddedManualScreen({
    super.key,
    this.initialFilePath,
    this.initialSearchQuery,
    this.initialTab,
  });

  @override
  ConsumerState<EmbeddedManualScreen> createState() =>
      _EmbeddedManualScreenState();
}

class _EmbeddedManualScreenState extends ConsumerState<EmbeddedManualScreen>
    with SingleTickerProviderStateMixin {
  String _currentFilePath =
      'packages/documentation_runtime/manuals/quickstart/index.md';
  String _markdownContent = '';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isLibraryLoaded = false;

  // ★ 修正1: 検索ボックスの文字をプログラムから操作(クリア)するためのコントローラーを追加
  final TextEditingController _searchController = TextEditingController();

  // ★ PDF関連のプロパティ
  late TabController _tabController;
  int _selectedTabIndex = 0;
  PdfViewerController? _pdfViewerController;
  PdfTextSearchResult? _searchResult;
  String _pdfSearchQuery = '';
  bool _isSearchingPdf = false;

  // ★ ダウンロード＆キャッシュ関連のプロパティ
  final ManualDownloadService _downloadService = ManualDownloadService();
  final String _fullManualUrl =
      'https://github.com/Smooth213/kendo_os/releases/download/manuals/Kendo_Sync.pdf';
  final String _fullManualFileName = 'Kendo_Sync.pdf';
  bool _isPdfDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  File? _localPdfFile;
  bool _forceMarkdownFallback = false; // ダウンロード前でもMarkdownテキスト版を強制表示させるフラグ

  @override
  void initState() {
    super.initState();
    _loadLibrary();
    _pdfViewerController = PdfViewerController();

    // 初期遷移タブの判定
    if (widget.initialTab != null) {
      _selectedTabIndex = widget.initialTab!;
    } else if (widget.initialFilePath != null) {
      if (widget.initialFilePath!.contains('bunaiksen')) {
        _selectedTabIndex = 1;
      } else if (widget.initialFilePath!.contains('quickstart')) {
        _selectedTabIndex = 0;
      } else {
        _selectedTabIndex = 2;
      }
    } else {
      _selectedTabIndex = 2; // デフォルトは総合マニュアル
    }

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _selectedTabIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
          // タブ切り替え時に検索状態をリセット
          _isSearchingPdf = false;
          _pdfSearchQuery = '';
          _searchResult?.clear();
          _searchController.clear();
        });
      }
    });

    if (widget.initialFilePath != null) {
      _currentFilePath = widget.initialFilePath!;
    }
    _loadMarkdown(_currentFilePath);
    _checkDownloadStatus();
  }

  Future<void> _loadLibrary() async {
    await md.loadLibrary();
    if (mounted) {
      setState(() {
        _isLibraryLoaded = true;
      });
    }
  }

  // PDFのダウンロードキャッシュ状態を確認
  Future<void> _checkDownloadStatus() async {
    final downloaded = await _downloadService.isFileDownloaded(
      _fullManualFileName,
    );
    File? file;
    if (downloaded) {
      file = await _downloadService.getLocalFile(_fullManualFileName);
    }
    if (mounted) {
      setState(() {
        _isPdfDownloaded = downloaded;
        _localPdfFile = file;
      });
    }
  }

  // PDFのダウンロードを開始する
  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });
    try {
      final file = await _downloadService.downloadManual(
        _fullManualFileName,
        _fullManualUrl,
        (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _isPdfDownloaded = true;
          _localPdfFile = file;
          _isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        AppSnackBar.showError(context, 'ダウンロードに失敗しました: $e');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _pdfViewerController?.dispose();
    super.dispose();
  }

  Future<void> _loadMarkdown(String path) async {
    setState(() => _isLoading = true);

    // ★ パスマップの補正 (docs/manuals/ を packages/documentation_runtime/manuals/ に置換)
    if (path.startsWith('docs/manuals/')) {
      path = path.replaceFirst(
        'docs/manuals/',
        'packages/documentation_runtime/manuals/',
      );
    }
    if (path.endsWith('viewer_faq.md')) {
      path = 'packages/documentation_runtime/manuals/faq/viewer_faq.md';
    }
    if (path.endsWith('operator_faq.md')) {
      path = 'packages/documentation_runtime/manuals/faq/operator_faq.md';
    }

    try {
      final rawContent = await rootBundle.loadString(path);
      // AI用メタデータを取り除く
      String content = rawContent.replaceFirst(
        RegExp(r'^---\s*\n.*?\n---\s*\n', dotAll: true),
        '',
      );

      // 検索語がある場合、Markdown内で目立たせる
      if (_searchQuery.isNotEmpty) {
        final escapedQuery = RegExp.escape(_searchQuery);
        content = content.replaceAllMapped(
          RegExp('($escapedQuery)', caseSensitive: false),
          (match) => '***${match.group(0)}***',
        );
      }

      if (widget.initialSearchQuery != null &&
          widget.initialSearchQuery!.isNotEmpty) {
        final query = widget.initialSearchQuery!;
        content = content.replaceAllMapped(
          RegExp(RegExp.escape(query), caseSensitive: false),
          (match) => '***${match.group(0)}***',
        );
      }

      setState(() {
        _markdownContent = content;
        _currentFilePath = path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _markdownContent =
            '# 📄 読み込みエラー\n\nファイルが見つかりません: `$path`\n\n'
            '詳細なエラー:\n$e';
        _isLoading = false;
      });
    }
  }

  // A4印刷・共有用コントロールバーの構築
  Widget _buildFloatingActionBar({
    required bool isAsset,
    String? assetPath,
    File? file,
    required String fileName,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: AppRadius.large,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? context.appColors.cardBackground.withValues(alpha: 0.5)
                : context.appColors.textColor.withValues(alpha: 0.7),
            borderRadius: AppRadius.large,
            border: Border.all(
              color: isDark
                  ? context.appColors.textColor.withValues(alpha: 0.1)
                  : const Color(0xFF000000).withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xDE000000),
                    foregroundColor: AppKendoColors.pureWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                  ),
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text(
                    'A4印刷',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.bodySmall,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () async {
                    try {
                      if (isAsset) {
                        final data = await rootBundle.load(assetPath!);
                        await Printing.layoutPdf(
                          onLayout: (_) => data.buffer.asUint8List(),
                          name: fileName,
                        );
                      } else {
                        final bytes = await file!.readAsBytes();
                        await Printing.layoutPdf(
                          onLayout: (_) => bytes,
                          name: fileName,
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        AppSnackBar.showError(context, '印刷の起動に失敗しました: $e');
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06C755),
                    foregroundColor: AppKendoColors.pureWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                  ),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text(
                    '共有/保存',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.bodySmall,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () async {
                    try {
                      Uint8List bytes;
                      if (isAsset) {
                        final data = await rootBundle.load(assetPath!);
                        bytes = data.buffer.asUint8List();
                      } else {
                        bytes = await file!.readAsBytes();
                      }

                      await SharePlus.instance.share(
                        ShareParams(
                          files: [
                            XFile.fromData(
                              bytes,
                              mimeType: 'application/pdf',
                              name: fileName,
                            ),
                          ],
                          text: '$fileName を共有します。',
                        ),
                      );
                    } catch (e) {
                      if (mounted) {
                        AppSnackBar.showError(context, '共有に失敗しました: $e');
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Web用の共有・ブラウザ起動コントロールバー
  Widget _buildFloatingActionBarForWeb() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: AppRadius.large,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? context.appColors.cardBackground.withValues(alpha: 0.5)
                : context.appColors.textColor.withValues(alpha: 0.7),
            borderRadius: AppRadius.large,
            border: Border.all(
              color: isDark
                  ? context.appColors.textColor.withValues(alpha: 0.1)
                  : const Color(0xFF000000).withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xDE000000),
                    foregroundColor: AppKendoColors.pureWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text(
                    'PDF版をブラウザで開く',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.bodySmall,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () async {
                    // Google Docs PDF Viewerを中継して開くことで、モバイルSafariでのダウンロードフリーズを防ぎインライン表示させる
                    final encodedUrl = Uri.encodeComponent(_fullManualUrl);
                    final viewerUrl =
                        'https://docs.google.com/viewer?url=$encodedUrl';
                    final uri = Uri.parse(viewerUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06C755),
                    foregroundColor: AppKendoColors.pureWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                  ),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text(
                    '共有する',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.bodySmall,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () async {
                    await SharePlus.instance.share(
                      ShareParams(
                        text: 'Kendo Sync 総合取扱説明書はこちら: $_fullManualUrl',
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // クイックガイドタブのレイアウト
  Widget _buildQuickGuideTab(String assetPath, String fileName) {
    return Stack(
      children: [
        SfPdfViewer.asset(
          assetPath,
          onDocumentLoadFailed: (details) {
            debugPrint('Asset load failed: ${details.description}');
          },
        ),
        Positioned(
          bottom: AppSpacing.xl,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          child: _buildFloatingActionBar(
            isAsset: true,
            assetPath: assetPath,
            fileName: fileName,
          ),
        ),
      ],
    );
  }

  // 総合マニュアルタブのレイアウト
  Widget _buildFullManualTab(Widget buildIndexPane, Widget markdownPane) {
    if (kIsWeb) {
      // Webの場合：ダウンロード案内画面はスキップし、インラインでMarkdown版をデフォルト表示
      // 下部に「PDF版をブラウザで開く」ボタンを設置
      return Stack(
        children: [
          Row(
            children: [
              if (MediaQuery.of(context).size.width > 600) buildIndexPane,
              markdownPane,
            ],
          ),
          Positioned(
            bottom: AppSpacing.xl,
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            child: _buildFloatingActionBarForWeb(),
          ),
        ],
      );
    }

    if (_forceMarkdownFallback) {
      // テキスト簡易版（Markdown）を表示
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.lg,
            ),
            color: AppKendoColors.teal.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📖 テキスト簡易版（オフライン対応）',
                  style: TextStyle(fontWeight: AppFontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('PDF版に戻る'),
                  onPressed: () {
                    setState(() {
                      _forceMarkdownFallback = false;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (MediaQuery.of(context).size.width > 600) buildIndexPane,
                markdownPane,
              ],
            ),
          ),
        ],
      );
    }

    if (_isDownloading) {
      // ダウンロード中
      return Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          width: 300,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: AppRadius.xlarge,
            boxShadow: [
              BoxShadow(
                color: AppKendoColors.pureBlack.withValues(alpha: 0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'マニュアルをロード中...',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.subhead,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              LinearProgressIndicator(value: _downloadProgress),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.body,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isPdfDownloaded) {
      // 未ダウンロード状態：案内UIを表示
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            constraints: const BoxConstraints(maxWidth: 450),
            decoration: BoxDecoration(
              color: isDark
                  ? context.appColors.textColor.withValues(alpha: 0.05)
                  : context.appColors.cardBackground.withValues(alpha: 0.02),
              borderRadius: AppRadius.xlarge,
              border: Border.all(
                color: isDark
                    ? context.appColors.textColor.withValues(alpha: 0.1)
                    : context.appColors.cardBackground.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  size: 80,
                  color: AppKendoColors.redAccent.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Kendo Sync 総合取扱説明書',
                  style: TextStyle(
                    fontSize: AppFontSize.titleLarge,
                    fontWeight: AppFontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  '印刷や文字検索、高倍率ズームが可能な公式PDF版マニュアルをダウンロードできます。一度保存すると、オフラインでも閲覧可能です。',
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    color: AppKendoColors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'ファイルサイズ: 約 2.6 MB',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: AppFontWeight.bold,
                    color: AppKendoColors.blueAccent,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppKendoColors.blueAccent,
                      foregroundColor: AppKendoColors.pureWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.large,
                      ),
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text(
                      'PDF版をダウンロード (無料)',
                      style: TextStyle(
                        fontSize: AppFontSize.subhead,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    onPressed: _startDownload,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton.icon(
                  icon: const Icon(Icons.chrome_reader_mode_outlined),
                  label: const Text('テキスト簡易版（オフライン対応）を読む'),
                  onPressed: () {
                    setState(() {
                      _forceMarkdownFallback = true;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ダウンロード済み：PDFViewerを表示
    return Stack(
      children: [
        SfPdfViewer.file(_localPdfFile!, controller: _pdfViewerController),
        Positioned(
          bottom: AppSpacing.xl,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          child: _buildFloatingActionBar(
            isAsset: false,
            file: _localPdfFile,
            fileName: _fullManualFileName,
          ),
        ),
      ],
    );
  }

  // AppBar用のタイトル（検索モード時は入力フォームを表示）
  Widget _buildAppBarTitle() {
    final showSearch =
        _selectedTabIndex == 2 &&
        (kIsWeb || (_isPdfDownloaded && !_forceMarkdownFallback));

    if (showSearch && _isSearchingPdf) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final borderColor = isDark
          ? AppKendoColors.tealAccent
          : context.appColors.primaryAccent;
      final searchIconColor = isDark
          ? AppKendoColors.tealAccent
          : context.appColors.primaryAccent;

      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.compact),
        decoration: BoxDecoration(
          color: isDark
              ? context.appColors.cardBackground.withValues(alpha: 0.26)
              : context.appColors.textColor,
          borderRadius: AppRadius.medium,
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color:
                  (isDark
                          ? context.appColors.cardBackground
                          : const Color(0x33000000))
                      .withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.search, color: searchIconColor, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppTextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF000000),
                  fontSize: AppFontSize.body,
                  fontWeight: AppFontWeight.medium,
                ),
                decoration: InputDecoration(
                  hintText: 'マニュアル内を検索...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppKendoColors.white60
                        : AppKendoColors.black45,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (text) {
                  if (kIsWeb || _forceMarkdownFallback) {
                    setState(() {
                      _searchQuery = text;
                    });
                    _loadMarkdown(_currentFilePath);
                  } else {
                    setState(() {
                      _pdfSearchQuery = text;
                    });
                    if (text.isEmpty) {
                      _searchResult?.clear();
                    } else {
                      _searchResult = _pdfViewerController?.searchText(text);
                    }
                  }
                },
              ),
            ),
          ],
        ),
      );
    }
    return const Text(
      'ヘルプ・マニュアル',
      style: TextStyle(fontSize: AppFontSize.subhead),
    );
  }

  // 検索用 AppBar アクションボタン
  List<Widget> _buildAppBarActions() {
    final List<Widget> actions = [];
    final showSearch =
        _selectedTabIndex == 2 &&
        (kIsWeb || (_isPdfDownloaded && !_forceMarkdownFallback));

    if (showSearch) {
      if (_isSearchingPdf) {
        final isPdfMode = !(kIsWeb || _forceMarkdownFallback);
        if (isPdfMode && _pdfSearchQuery.isNotEmpty) {
          actions.add(
            IconButton(
              icon: const Icon(Icons.navigate_before),
              tooltip: '前へ',
              onPressed: () {
                _searchResult?.previousInstance();
              },
            ),
          );
          actions.add(
            IconButton(
              icon: const Icon(Icons.navigate_next),
              tooltip: '次へ',
              onPressed: () {
                _searchResult?.nextInstance();
              },
            ),
          );
        }

        final hasQuery = isPdfMode
            ? _pdfSearchQuery.isNotEmpty
            : _searchQuery.isNotEmpty;
        if (hasQuery) {
          actions.add(
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'テキストをクリア',
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  if (isPdfMode) {
                    _pdfSearchQuery = '';
                    _searchResult?.clear();
                  } else {
                    _searchQuery = '';
                    _loadMarkdown(_currentFilePath);
                  }
                });
              },
            ),
          );
        }
      } else {
        // 非検索時は検索アイコンを表示
        actions.add(
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'マニュアル内を検索',
            onPressed: () {
              setState(() {
                _isSearchingPdf = true;
              });
            },
          ),
        );
      }
    }
    return actions;
  }

  Widget buildIndexPane() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final indexAsync = ref.watch(manualIndexProvider);

    return SafeArea(
      child: Container(
        width: MediaQuery.of(context).size.width > 600 ? 320 : null,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
          border: Border(
            right: BorderSide(
              color: isDark
                  ? context.appColors.textColor.withValues(alpha: 0.12)
                  : context.appColors.cardBackground.withValues(alpha: 0.12),
            ),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppTextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'タイトル、見出し、キーワード検索...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          tooltip: '検索をクリアして一覧に戻る',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
                      : const Color(0xFF000000).withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.small,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (val) =>
                    setState(() => _searchQuery = val.toLowerCase()),
              ),
            ),
            Expanded(
              child: indexAsync.when(
                data: (indexList) {
                  final results = indexList.where((item) {
                    if (_searchQuery.isEmpty) return true;
                    final title = item['title'].toString().toLowerCase();
                    final headings = (item['headings'] as List)
                        .join(' ')
                        .toLowerCase();
                    final tags = (item['tags'] as List).join(' ').toLowerCase();
                    return title.contains(_searchQuery) ||
                        headings.contains(_searchQuery) ||
                        tags.contains(_searchQuery);
                  }).toList();

                  return ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: isDark
                          ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
                          : const Color(0xFF000000).withValues(alpha: 0.12),
                    ),
                    itemBuilder: (ctx, i) {
                      final path = results[i]['path'];
                      final title = results[i]['title'];
                      final isSelected = path == _currentFilePath;
                      return ListTile(
                        dense: true,
                        title: Text(
                          title,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? AppFontWeight.bold
                                : AppFontWeight.regular,
                            color: isSelected
                                ? AppKendoColors.blueAccent
                                : null,
                          ),
                        ),
                        subtitle: _searchQuery.isNotEmpty
                            ? Text(
                                (results[i]['headings'] as List)
                                    .take(2)
                                    .join(' / '),
                                style: const TextStyle(
                                  fontSize: AppFontSize.badge,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        onTap: () {
                          _loadMarkdown(path);
                          if (MediaQuery.of(context).size.width <= 600) {
                            Navigator.pop(context);
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Index Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    final markdownPane = Expanded(
      child: (!_isLibraryLoaded || _isLoading)
          ? const Center(child: CircularProgressIndicator())
          : md.Markdown(
              data: _markdownContent,
              selectable: false,
              onTapLink: (text, href, title) {
                if (href == null || href.startsWith('http')) return;
                if (href.startsWith('#')) return;

                if (href.startsWith('manual://')) {
                  final id = href.replaceFirst('manual://', '');
                  final route = ManualRoute.fromId(id);
                  if (route != null) {
                    _loadMarkdown(route.path);
                    return;
                  }
                }

                final dirSegments = _currentFilePath.split('/');
                dirSegments.removeLast();

                final hrefSegments = href.split('/');
                for (final segment in hrefSegments) {
                  if (segment == '.') continue;
                  if (segment == '..') {
                    if (dirSegments.isNotEmpty) dirSegments.removeLast();
                  } else {
                    final fileOnly = segment.split('#').first;
                    if (fileOnly.isNotEmpty) {
                      dirSegments.add(fileOnly);
                    }
                  }
                }

                final targetPath = dirSegments.join('/');
                _loadMarkdown(targetPath);
              },
              styleSheet: md.MarkdownStyleSheet(
                h1: const TextStyle(
                  fontSize: AppFontSize.hero,
                  fontWeight: AppFontWeight.bold,
                  color: AppKendoColors.blueAccent,
                ),
                h2: const TextStyle(
                  fontSize: AppFontSize.titleLarge,
                  fontWeight: AppFontWeight.bold,
                  color: AppKendoColors.teal,
                  decoration: TextDecoration.underline,
                ),
                p: const TextStyle(fontSize: AppFontSize.subhead, height: 1.7),
                code: TextStyle(
                  backgroundColor: isDark
                      ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
                      : const Color(0xFF000000).withValues(alpha: 0.12),
                ),
                a: const TextStyle(
                  color: AppKendoColors.blueAccent,
                  decoration: TextDecoration.underline,
                ),
                em: TextStyle(
                  backgroundColor: AppKendoColors.yellow.withValues(alpha: 0.5),
                  color: context.appColors.textColor,
                  fontStyle: FontStyle.normal,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
            ),
    );

    return Scaffold(
      drawer:
          (_selectedTabIndex == 2 && _forceMarkdownFallback && !isWideScreen)
          ? Drawer(child: buildIndexPane())
          : null,
      appBar: AppHeader(
        leading:
            (_selectedTabIndex == 2 &&
                (kIsWeb || (_isPdfDownloaded && !_forceMarkdownFallback)) &&
                _isSearchingPdf)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearchingPdf = false;
                    _searchController.clear();
                    if (kIsWeb || _forceMarkdownFallback) {
                      _searchQuery = '';
                      _loadMarkdown(_currentFilePath);
                    } else {
                      _pdfSearchQuery = '';
                      _searchResult?.clear();
                    }
                  });
                },
                tooltip: '検索を終了',
              )
            : null,
        titleWidget: _buildAppBarTitle(),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '通常クイック'),
            Tab(text: '部内戦クイック'),
            Tab(text: '総合マニュアル'),
          ],
        ),
        actions: _buildAppBarActions(),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 0: 通常クイックガイド
          _buildQuickGuideTab(
            'assets/manuals/kendo_sync_quickguide.pdf',
            'kendo_sync_quickguide.pdf',
          ),
          // Tab 1: 部内戦クイックガイド
          _buildQuickGuideTab(
            'assets/manuals/kendo_sync_bunaiksen_quickguide.pdf',
            'kendo_sync_bunaiksen_quickguide.pdf',
          ),
          // Tab 2: 総合取扱説明書
          _buildFullManualTab(buildIndexPane(), markdownPane),
        ],
      ),
    );
  }
}
