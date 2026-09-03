import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/screens/embedded_manual_tab_views.dart';
import 'package:kendo_os/shared/infrastructure/services/manual_download_service.dart';
import 'package:kendo_os/shared/infrastructure/services/manual_markdown_loader_service.dart';
import 'package:kendo_os/shared/infrastructure/services/manual_print_share_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_index_pane.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_markdown_view.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_search_app_bar_actions.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_search_app_bar_title.dart';
import 'package:kendo_os/shared/presentation/providers/manual_index_provider.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/presentation/screens/embedded_manual_tab_resolver.dart';

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
  String _currentFilePath = EmbeddedManualTabResolver.defaultMarkdownPath;
  String _markdownContent = '';
  String _searchQuery = '';
  bool _isLoading = true;

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
  final String _fullManualUrl = EmbeddedManualTabResolver.fullManualUrl;
  final String _fullManualFileName =
      EmbeddedManualTabResolver.fullManualFileName;
  bool _isPdfDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  File? _localPdfFile;
  bool _forceMarkdownFallback = false; // ダウンロード前でもMarkdownテキスト版を強制表示させるフラグ

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();

    // 初期遷移タブの判定
    _selectedTabIndex = EmbeddedManualTabResolver.resolveInitialTabIndex(
      initialTab: widget.initialTab,
      initialFilePath: widget.initialFilePath,
    );

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

  final ManualMarkdownLoaderService _markdownLoader =
      const ManualMarkdownLoaderService();

  Future<void> _loadMarkdown(String path) async {
    setState(() => _isLoading = true);

    try {
      final content = await _markdownLoader.loadMarkdownContent(
        path: path,
        searchQuery: _searchQuery,
        initialSearchQuery: widget.initialSearchQuery,
      );

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

  final ManualPrintShareService _printShareService =
      const ManualPrintShareService();

  Future<void> _handlePrintPdf({
    required bool isAsset,
    String? assetPath,
    File? file,
    required String fileName,
  }) async {
    try {
      await _printShareService.printPdf(
        isAsset: isAsset,
        assetPath: assetPath,
        file: file,
        fileName: fileName,
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, '印刷の起動に失敗しました: $e');
      }
    }
  }

  Future<void> _handleSharePdf({
    required bool isAsset,
    String? assetPath,
    File? file,
    required String fileName,
  }) async {
    try {
      await _printShareService.sharePdf(
        isAsset: isAsset,
        assetPath: assetPath,
        file: file,
        fileName: fileName,
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, '共有に失敗しました: $e');
      }
    }
  }

  // AppBar用のタイトル（検索モード時は入力フォームを表示）
  Widget _buildAppBarTitle() {
    final showSearch = EmbeddedManualTabResolver.shouldShowSearch(
      selectedTabIndex: _selectedTabIndex,
      isWeb: kIsWeb,
      isPdfDownloaded: _isPdfDownloaded,
      forceMarkdownFallback: _forceMarkdownFallback,
    );

    return ManualSearchAppBarTitle(
      isSearching: showSearch && _isSearchingPdf,
      searchController: _searchController,
      onSearchChanged: (text) {
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
    );
  }

  // 検索用 AppBar アクションボタン
  List<Widget> _buildAppBarActions() {
    final showSearch = EmbeddedManualTabResolver.shouldShowSearch(
      selectedTabIndex: _selectedTabIndex,
      isWeb: kIsWeb,
      isPdfDownloaded: _isPdfDownloaded,
      forceMarkdownFallback: _forceMarkdownFallback,
    );
    final isPdfMode = !(kIsWeb || _forceMarkdownFallback);

    return [
      ManualSearchAppBarActions(
        showSearch: showSearch,
        isSearching: _isSearchingPdf,
        isPdfMode: isPdfMode,
        searchQuery: isPdfMode ? _pdfSearchQuery : _searchQuery,
        onPreviousPressed: () => _searchResult?.previousInstance(),
        onNextPressed: () => _searchResult?.nextInstance(),
        onClearPressed: () {
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
        onStartSearchPressed: () {
          setState(() {
            _isSearchingPdf = true;
          });
        },
      ),
    ];
  }

  Widget buildIndexPane() {
    final indexAsync = ref.watch(manualIndexProvider);
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return indexAsync.when(
      data: (indexList) => ManualIndexPane(
        searchController: _searchController,
        searchQuery: _searchQuery,
        indexList: indexList,
        currentFilePath: _currentFilePath,
        isWideScreen: isWideScreen,
        onSearchChanged: (val) =>
            setState(() => _searchQuery = val.toLowerCase()),
        onSearchCleared: () {
          _searchController.clear();
          setState(() => _searchQuery = '');
        },
        onFileSelected: (path) {
          _loadMarkdown(path);
          if (MediaQuery.of(context).size.width <= 600) {
            Navigator.pop(context);
          }
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Index Error: $err')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    final markdownPane = Expanded(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ManualMarkdownView(
              markdownContent: _markdownContent,
              currentFilePath: _currentFilePath,
              isLoading: false,
              onLinkTapped: _loadMarkdown,
            ),
    );

    return Scaffold(
      drawer:
          (_selectedTabIndex == 2 && _forceMarkdownFallback && !isWideScreen)
          ? Drawer(child: buildIndexPane())
          : null,
      appBar: AppHeader(
        leading:
            (EmbeddedManualTabResolver.shouldShowSearch(
                  selectedTabIndex: _selectedTabIndex,
                  isWeb: kIsWeb,
                  isPdfDownloaded: _isPdfDownloaded,
                  forceMarkdownFallback: _forceMarkdownFallback,
                ) &&
                _isSearchingPdf)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
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
          EmbeddedManualTabViews.buildQuickGuideTab(
            context: context,
            assetPath: EmbeddedManualTabResolver.normalQuickGuideAsset,
            fileName: EmbeddedManualTabResolver.normalQuickGuideFileName,
            onPrint: _handlePrintPdf,
            onShare: _handleSharePdf,
          ),
          // Tab 1: 部内戦クイックガイド
          EmbeddedManualTabViews.buildQuickGuideTab(
            context: context,
            assetPath: EmbeddedManualTabResolver.bunaiksenQuickGuideAsset,
            fileName: EmbeddedManualTabResolver.bunaiksenQuickGuideFileName,
            onPrint: _handlePrintPdf,
            onShare: _handleSharePdf,
          ),
          // Tab 2: 総合取扱説明書
          EmbeddedManualTabViews.buildFullManualTab(
            buildIndexPane: buildIndexPane(),
            markdownPane: markdownPane,
            isPdfDownloaded: _isPdfDownloaded,
            isDownloading: _isDownloading,
            downloadProgress: _downloadProgress,
            forceMarkdownFallback: _forceMarkdownFallback,
            localPdfFile: _localPdfFile,
            pdfViewerController: _pdfViewerController,
            onStartDownload: _startDownload,
            onEnableMarkdownFallback: () =>
                setState(() => _forceMarkdownFallback = true),
            onDisableMarkdownFallback: () =>
                setState(() => _forceMarkdownFallback = false),
            onPrint: _handlePrintPdf,
            onShare: _handleSharePdf,
          ),
        ],
      ),
    );
  }
}
