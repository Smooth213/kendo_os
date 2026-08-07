import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart'
    hide StrokeModel;
import 'package:kendo_os/features/match/domain/score/stroke_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/local_stroke_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/stroke_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_stroke_repository.dart';
import '../providers/role_provider.dart';
import '../providers/permission_provider.dart'; // ★ 追加: 閲覧専用権限を識別するためのインポート
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/infrastructure/repository/program_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

// ★ 追加: Viewer画面を開いたままでもOCR完了をリアルタイムで検知するための専用プロバイダ
final viewerProgramListProvider =
    StreamProvider.family<List<ProgramModel>, String>((ref, tournamentId) {
      return ref.watch(programRepositoryProvider).watchPrograms(tournamentId);
    });

class ProgramViewerScreen extends ConsumerStatefulWidget {
  final List<ProgramModel> programs;
  final int initialIndex;

  const ProgramViewerScreen({
    super.key,
    required this.programs,
    required this.initialIndex,
  });

  @override
  ConsumerState<ProgramViewerScreen> createState() =>
      _ProgramViewerScreenState();
}

class _ProgramViewerScreenState extends ConsumerState<ProgramViewerScreen> {
  // ★ 追加: 白背景における黄色ペンの視認性を向上させたダークイエローゴールド
  static const Color _yellowPenColor = Color(0xFFCA8A04);

  late PageController _pageController;
  late int _currentIndex;
  final Map<String, int> _pdfPageCounts = {};

  @visibleForTesting
  Map<String, int> get pdfPageCountsForTesting => _pdfPageCounts;

  // ★ 追加: ピンチズーム（拡大）時のジェスチャ競合防止用コントローラー
  final TransformationController _transformationController =
      TransformationController();
  bool _isZoomed = false;

  // ★ 追加: ペンツールと消しゴム機能の状態管理
  String _selectedTool = 'pen'; // 'pen', 'marker', 'eraser'
  List<StrokeModel> _cachedSharedStrokes = [];
  List<LocalStrokeModel> _cachedPrivateStrokes = [];

  // ★ PDF検索用のコントローラーと状態管理
  final PdfViewerController _pdfViewerController = PdfViewerController();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  final TextEditingController _searchTextController = TextEditingController();
  bool _isSearchMode = false;

  // ★ 画像OCR検索用の状態管理
  String _currentSearchText = "";

  bool _isDrawingMode = false;
  Color _selectedPenColor = Colors.pink; // ★ 4色を管理（デフォルトはピンク）
  bool get _isSharedPen =>
      _selectedPenColor == Colors.pink || _selectedPenColor == _yellowPenColor;
  List<Offset> _currentPoints = [];

  // ★ 画像サイズ取得用キャッシュ（描画ごとのチラつき・無限クルクルを防止）
  final Map<String, Future<Size>> _imageSizeCache = {};

  // ★ 追加: setStateの度にURLが変わりPDF・画像が再レンダリングされてクラッシュするのを防ぐ固定セッションID
  final int _sessionBuster = DateTime.now().millisecondsSinceEpoch;

  // ★ 追加: Web特有のCORSエラーキャッシュを回避するURLジェネレーター
  String _getSafeUrl(String url) {
    if (!kIsWeb || url.isEmpty || !url.startsWith('http')) return url;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}_cb=$_sessionBuster';
  }

  final Map<String, Future<Uint8List>> _sdkPdfBytesCache = {};

  @visibleForTesting
  Map<String, Future<Uint8List>> get sdkPdfBytesCacheForTesting =>
      _sdkPdfBytesCache;

  @visibleForTesting
  Future<Uint8List> getCachedPdfBytesViaSdk(String url) {
    if (!_sdkPdfBytesCache.containsKey(url)) {
      // 匿名認証済みのセッションを用いて最大32MB（大会パンフレットを完全網羅）のバイナリを一発で安全に落とし込みます
      _sdkPdfBytesCache[url] = FirebaseStorage.instance
          .refFromURL(url)
          .getData(32 * 1024 * 1024)
          .then((value) {
            if (value != null) {
              debugPrint(
                '📂 [PDF Debug] Bytes fetched via SDK. Size = ${value.length} bytes.',
              );
              if (value.length >= 4) {
                final signature = String.fromCharCodes(value.take(4));
                debugPrint('📂 [PDF Debug] First 4 bytes (Char): "$signature"');
                debugPrint(
                  '📂 [PDF Debug] First 4 bytes (Hex): ${value.take(4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
                );
                if (signature == '%PDF') {
                  debugPrint(
                    '📂 [PDF Debug] Signature check: Valid PDF structure confirmed.',
                  );
                } else {
                  debugPrint(
                    '🚨 [PDF Debug] Signature check: INVALID PDF signature. The data might be corrupted or an HTML/XML error page.',
                  );
                  final preview = String.fromCharCodes(
                    value.take(200).where((c) => c >= 32 && c <= 126),
                  );
                  debugPrint(
                    '🚨 [PDF Debug] Preview of loaded payload: "$preview"',
                  );
                }
              } else {
                debugPrint('🚨 [PDF Debug] Data is too small to be a PDF.');
              }
            } else {
              debugPrint('🚨 [PDF Debug] Fetched data is null.');
            }
            return value!;
          });
    }
    return _sdkPdfBytesCache[url]!;
  }

  // ★ 追加：環境に応じてリポジトリを安全に切り替える調停メソッド
  dynamic _getActiveRepository(WidgetRef ref) {
    return ref.read(strokeRepositoryProvider); // Web/ネイティブ共通でFirestoreを使用
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // ★ ズーム状態の変更検知リスナーを登録
    _transformationController.addListener(_handleTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_handleTransformationChanged);
    _transformationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleTransformationChanged() {
    final double scale = _transformationController.value.getMaxScaleOnAxis();
    // わずかな計算上の誤差を考慮し、1.01 を超えた場合にズームと見なします
    final bool zoomed = scale > 1.01;
    if (zoomed != _isZoomed) {
      setState(() {
        _isZoomed = zoomed;
      });
    }
  }

  /// 消しゴム機能：指定されたタッチ位置から近接する手書き線を検出し、Firestore / Isar から個別に削除します
  Future<void> _eraseStrokeAt(Offset touchPoint) async {
    const double threshold = 25.0; // 消しゴムの反応半径

    // 1. 共有ペンの消去判定
    final currentRole = ref.read(activeRoleProvider);
    final canUseSharedPen =
        currentRole == Role.admin ||
        currentRole == Role.scorer ||
        currentRole == Role.editor;

    if (canUseSharedPen) {
      for (final stroke in _cachedSharedStrokes) {
        if (_isNearStroke(touchPoint, stroke.points, threshold)) {
          await _getActiveRepository(ref).deleteStroke(stroke.id);
          return;
        }
      }
    }

    // 2. 個人ペンの消去判定
    for (final stroke in _cachedPrivateStrokes) {
      if (_isNearLocalStroke(
        touchPoint,
        stroke.pointsX,
        stroke.pointsY,
        threshold,
      )) {
        await ref
            .read(localStrokeRepositoryProvider)
            .deleteStroke(stroke.id, firestoreId: stroke.firestoreId);
        return;
      }
    }
  }

  bool _isNearStroke(
    Offset touchPoint,
    List<Offset> strokePoints,
    double threshold,
  ) {
    for (final pt in strokePoints) {
      if ((touchPoint - pt).distance <= threshold) {
        return true;
      }
    }
    return false;
  }

  bool _isNearLocalStroke(
    Offset touchPoint,
    List<double> xs,
    List<double> ys,
    double threshold,
  ) {
    final len = xs.length;
    for (int i = 0; i < len; i++) {
      if ((touchPoint - Offset(xs[i], ys[i])).distance <= threshold) {
        return true;
      }
    }
    return false;
  }

  Future<Size> _fetchImageSize(String url) async {
    // ★ 追加: ダミーURLや無効なURLの場合は、ネットワークリクエストを行わずに即座にサイズを返し、エラーを防止する
    if (url.isEmpty || url.contains('placehold.co')) {
      return const Size(400, 600);
    }

    final Completer<Size> completer = Completer();
    final safeUrl = _getSafeUrl(url);
    final Image image = Image.network(safeUrl);

    final listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!completer.isCompleted) {
          completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble()),
          );
        }
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.complete(const Size(800, 1000)); // エラー時のフォールバック
        }
      },
    );

    image.image.resolve(const ImageConfiguration()).addListener(listener);

    // ★ 修正: Web特有のCORSストールを回避するため、タイムアウトを設けて無限クルクルを強制的に遮断する
    return completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        if (!completer.isCompleted) {
          // ストールしたリスナーを安全に解除
          image.image
              .resolve(const ImageConfiguration())
              .removeListener(listener);
        }
        // タイムアウト時は適当な仮想サイズを返して強制的に画像を表示させる
        return const Size(800, 1000);
      },
    );
  }

  // ★ 追加: FutureBuilderが毎フレーム再フェッチするのを防ぐキャッシュメソッド
  Future<Size> _getCachedImageSize(String url) {
    if (!_imageSizeCache.containsKey(url)) {
      _imageSizeCache[url] = _fetchImageSize(url);
    }
    return _imageSizeCache[url]!;
  }

  @override
  Widget build(BuildContext context) {
    // ★ Phase 3: 閲覧専用ガードの取得
    final permissions = ref.watch(permissionProvider);

    // ★ role_providerから「現在の有効な役割」を取得し、共有ペンが使えるか判定
    final currentRole = ref.watch(activeRoleProvider);
    final canUseSharedPen =
        currentRole == Role.admin ||
        currentRole == Role.scorer ||
        currentRole == Role.editor;

    // 権限がないのに共有ペンが選ばれている場合のフォールバック（強制的に青にする）
    final activePenColor = (!canUseSharedPen && _isSharedPen)
        ? Colors.blue
        : _selectedPenColor;
    final activeIsShared =
        activePenColor == Colors.pink || activePenColor == _yellowPenColor;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ★ 修正: 画面を開いた時の過去データ(widget.programs)ではなく、最新のデータをリアルタイム監視する
    final tournamentId = widget.programs.isNotEmpty
        ? widget.programs.first.tournamentId
        : '';
    final AsyncValue<List<ProgramModel>?> realtimeProgramsAsync =
        tournamentId.isNotEmpty
        ? ref.watch(viewerProgramListProvider(tournamentId))
        : const AsyncData<List<ProgramModel>?>(null);

    // ネットワーク読込前は渡された初期データを表示し、読込後はリアルタイムデータを表示
    // ★ 修正: Firebaseのインデックス不足等でエラーが発生した場合も考慮し、安全にフォールバックする
    final displayPrograms = realtimeProgramsAsync.when(
      data: (realtimeList) => realtimeList ?? widget.programs,
      // ローディング中とエラー発生時は、最初に渡された静的なプログラムリストを表示し続ける
      loading: () => widget.programs,
      error: (error, stackTrace) {
        // 本来はここでエラーログを送信する
        debugPrint('🚨 Program Viewer failed to get realtime updates: $error');
        return widget.programs;
      },
    );

    // ★ 致命的クラッシュの防止:
    // リアルタイム更新や初期読み込み時にプログラムリストが空になった場合に、
    // 存在しないインデックスにアクセスしてクラッシュするのを防ぐ安全ガード。
    if (displayPrograms.isEmpty) {
      return LiquidBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const AppHeader(title: 'プログラム'),
          body: const Center(child: Text('表示できるプログラムがありません。')),
        ),
      );
    }

    // ★ 致命的クラッシュの防止:
    // リストが空でないことを保証した上で、現在のインデックスがリストの範囲外になっていないか
    // 確認し、安全な範囲に収まるように補正（クランプ）します。
    final safeIndex = _currentIndex.clamp(0, displayPrograms.length - 1);

    // ★ 修正: 常に安全なインデックスを使って現在のプログラムを取得する
    final currentProgram = displayPrograms[safeIndex];

    // ★ 材料データ化（URL未生成）のプログラムであるか安全に判定
    final isMaterialOnly =
        currentProgram.fileUrl.isEmpty ||
        !currentProgram.fileUrl.startsWith('http');
    final isFilePdf =
        !isMaterialOnly &&
        (currentProgram.fileType == 'pdf' ||
            currentProgram.fileUrl.toLowerCase().contains('.pdf'));

    final programId = currentProgram.id.isNotEmpty
        ? currentProgram.id
        : currentProgram.fileUrl;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppHeader(
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          elevation: _isDrawingMode ? 0 : 1,
          titleWidget: _isSearchMode
              ? TextField(
                  controller: _searchTextController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: '選手名・団体名を検索...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) async {
                    if (value.isEmpty) {
                      setState(() {
                        _currentSearchText = "";
                        if (isFilePdf) _searchResult.clear();
                      });
                      return;
                    }

                    setState(() {
                      _currentSearchText = value;
                    });

                    if (isFilePdf) {
                      // PDFの文字検索を実行
                      _searchResult = _pdfViewerController.searchText(value);

                      // ★ 検索が完了したことを検知して画面を更新し、ハイライトを表示したままにする
                      _searchResult.addListener(() {
                        if (mounted) setState(() {});
                      });
                    } else {
                      // 画像OCR検索の処理
                      if (!(currentProgram.isOcrProcessed ?? false)) {
                        AppSnackBar.show(context, '現在クラウドで解析中です。しばらくお待ちください。');
                      } else if (currentProgram.ocrWords == null ||
                          currentProgram.ocrWords!.isEmpty) {
                        AppSnackBar.show(context, 'この画像から文字が検出されませんでした。');
                      }
                    }
                    setState(() {});
                  },
                )
              : Text(
                  '${currentProgram.title} (${safeIndex + 1}/${displayPrograms.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
          actions: [
            // ★ 検索モード時のナビゲーションと「閉じる」ボタン（画像・PDF共通）
            if (_isSearchMode) ...[
              if (isFilePdf) ...[
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed: () => _searchResult.previousInstance(),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: () => _searchResult.nextInstance(),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: '検索を終了',
                onPressed: () => setState(() {
                  _isSearchMode = false;
                  _currentSearchText = "";
                  _searchTextController.clear();
                  if (isFilePdf) _searchResult.clear();
                }),
              ),
            ],

            // ★ 通常時のボタン群
            if (!_isSearchMode) ...[
              if (!isFilePdf)
                Tooltip(
                  message: (currentProgram.isOcrProcessed ?? false)
                      ? '文字検索の準備完了'
                      : '画像解析の準備中',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      Icons.bolt,
                      color: (currentProgram.isOcrProcessed ?? false)
                          ? Colors.amber
                          : Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                ),
              // 検索ボタン
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => setState(() => _isSearchMode = true),
              ),
            ],

            // ★ 書き込むボタン（検索モードでも常に見えるように外に出しました！）
            // ★ 修正: 閲覧専用権限（保護者）の時は、ボタンを物理的に非表示にして「書けない・見るだけ」を徹底保証
            if (!permissions.isReadOnly)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                // ★ はみ出しエラー修正: 検索モード中や画面幅が狭い場合(600px未満)は、ラベルなしのアイコンボタンに変形してAppBarのパンクを完全防御します
                child: MediaQuery.of(context).size.width < 600 || _isSearchMode
                    ? IconButton(
                        onPressed: () => setState(() {
                          _isDrawingMode = !_isDrawingMode;
                        }),
                        icon: Icon(_isDrawingMode ? Icons.check : Icons.edit),
                        color: _isDrawingMode
                            ? activePenColor
                            : (isDark ? Colors.white : Colors.black87),
                        tooltip: _isDrawingMode ? '完了' : '書き込む',
                      )
                    : ElevatedButton.icon(
                        onPressed: () => setState(() {
                          _isDrawingMode = !_isDrawingMode;
                        }),
                        icon: Icon(
                          _isDrawingMode ? Icons.check : Icons.edit,
                          size: 18,
                        ),
                        label: Text(_isDrawingMode ? '完了' : '書き込む'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isDrawingMode
                              ? activePenColor
                              : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200),
                          foregroundColor: _isDrawingMode
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                          elevation: 0,
                        ),
                      ),
              ),
          ],
        ),
        // ★ body全体をColumnで包み、上にツールバー、下に画像を配置する
        body: Column(
          children: [
            // --- 新設：2段目の専用ツールバー（書き込みモード時のみ出現） ---
            if (_isDrawingMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 🎨 1. 【描画グループ】(ペン選択 + ペン + マーカー)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            // ペン選択ボタン
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (_selectedTool == 'eraser') {
                                    setState(() => _selectedTool = 'pen');
                                  }
                                  _showPenPicker(context, ref, canUseSharedPen);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: activePenColor.withAlpha(26),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: activePenColor.withAlpha(128),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _selectedTool == 'marker'
                                            ? Icons.border_color
                                            : Icons.edit,
                                        size: 18,
                                        color: activePenColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _selectedTool == 'marker'
                                              ? '${_getPenName(activePenColor)} (マーカー)'
                                              : activeIsShared
                                              ? '${_getPenName(activePenColor)} (共有)'
                                              : '${_getPenName(activePenColor)} (個人)',
                                          style: TextStyle(
                                            color: activePenColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: activePenColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // ペンツール
                            _buildToolButton(
                              tool: 'pen',
                              icon: Icons.edit,
                              tooltip: 'ペン',
                              isDark: isDark,
                              activeColor: activePenColor,
                            ),
                            // 蛍光マーカー
                            _buildToolButton(
                              tool: 'marker',
                              icon: Icons.border_color,
                              tooltip: '蛍光マーカー',
                              isDark: isDark,
                              activeColor: activePenColor,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2つのグループの間の区切り
                    const SizedBox(width: 12),

                    // 🧹 2. 【消去・履歴グループ】(消しゴム + 1つ戻る + 全消し)
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3A3A3C)
                            : Colors.blueGrey.shade50.withAlpha(220),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.transparent
                              : Colors.blueGrey.shade100,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 消しゴムツール
                          _buildToolButton(
                            tool: 'eraser',
                            icon: Icons.cleaning_services,
                            tooltip: '消しゴム',
                            isDark: isDark,
                            activeColor: Colors.blueGrey.shade600,
                          ),

                          // 小さな縦仕切り線
                          Container(
                            height: 20,
                            width: 1,
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.blueGrey.shade200,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                          ),

                          // 1つ戻る (Undo)
                          IconButton(
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            padding: const EdgeInsets.all(6),
                            iconSize: 20,
                            icon: Icon(
                              Icons.undo,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.blueGrey.shade600,
                            ),
                            tooltip: '1つ戻す',
                            onPressed: () {
                              if (activeIsShared) {
                                _getActiveRepository(
                                  ref,
                                ).undoLastStroke(programId);
                              } else {
                                ref
                                    .read(localStrokeRepositoryProvider)
                                    .undoLastStroke(programId);
                              }
                            },
                          ),

                          // 全消去 (Delete Sweep)
                          IconButton(
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            padding: const EdgeInsets.all(6),
                            iconSize: 20,
                            icon: Icon(
                              Icons.delete_sweep,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.blueGrey.shade700,
                            ),
                            tooltip: 'すべて消す',
                            onPressed: () async {
                              // ★ いきなり消さず、まずダイアログを表示して「はい/いいえ」を聞く
                              final shouldDelete = await showAppDialog<bool>(
                                context: context,
                                builder: (context) => AppDialog(
                                  title: '全消去の確認',
                                  content: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: activeIsShared
                                              ? 'このプログラムに引かれた【共有ペン】をすべて消去しますか？\n'
                                              : 'このプログラムに引かれた【個人ペン】をすべて消去しますか？\n',
                                        ),
                                        if (activeIsShared)
                                          const TextSpan(
                                            text:
                                                '※他の人の画面からも消えてしまいます。間違いないですか？\n',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        const TextSpan(
                                          text: '※一度削除したデータは元に戻すことができません。',
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(
                                        context,
                                        false,
                                      ), // キャンセル
                                      child: const Text(
                                        'キャンセル',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true), // 実行
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                      ),
                                      child: const Text('すべて消去する'),
                                    ),
                                  ],
                                ),
                              );

                              // ★ ダイアログで「消去する(true)」が選ばれた時だけ、本当に削除する
                              if (shouldDelete == true) {
                                if (activeIsShared) {
                                  _getActiveRepository(
                                    ref,
                                  ).clearStrokes(programId);
                                } else {
                                  ref
                                      .read(localStrokeRepositoryProvider)
                                      .clearStrokes(programId);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // --- 共通ビューア部分（PDF/画像の両方で手書き可能） ---
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: _isDrawingMode || _isZoomed
                    ? const NeverScrollableScrollPhysics()
                    : const ClampingScrollPhysics(),
                itemCount: displayPrograms.length,
                onPageChanged: (index) => setState(() {
                  _currentIndex = index;
                  _isDrawingMode = false;
                }),
                itemBuilder: (context, index) {
                  final program = displayPrograms[index];

                  // ★ 超重要：材料データ化によるファイルURL欠損時のクラッシュ防止ガード
                  final isItemMaterialOnly =
                      program.fileUrl.isEmpty ||
                      !program.fileUrl.startsWith('http');
                  if (isItemMaterialOnly) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.all(32),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C1C1E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              program.fileType == 'pdf'
                                  ? Icons.picture_as_pdf_outlined
                                  : Icons.image_not_supported_outlined,
                              size: 64,
                              color: Colors.indigo.shade400,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              program.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '【材料データ同期済み】\nオフラインファースト最適化の規約に基づき、通信帯域を圧迫する実ファイル（バイナリ）の自動ロードは行われません。プログラムの構成情報は安全に保護されています。',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black54,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final isFilePdf =
                      program.fileType == 'pdf' ||
                      program.fileUrl.toLowerCase().contains('.pdf');
                  final programId = program.id.isNotEmpty
                      ? program.id
                      : program.fileUrl;

                  // ★ 引数にペンの太さ(penWidth)を追加
                  Widget buildOverlayLayers({required double penWidth}) {
                    return Stack(
                      children: [
                        // --- 中層：描画レイヤー（共有 ＋ 個人） ---
                        Positioned.fill(
                          child: StreamBuilder<List<StrokeModel>>(
                            stream: ref
                                .watch(strokeRepositoryProvider)
                                .watchStrokes(programId),
                            builder: (context, sharedSnapshot) {
                              final sharedStrokes = sharedSnapshot.data ?? [];
                              _cachedSharedStrokes =
                                  sharedStrokes; // ★ 消しゴム用にキャッシュ
                              return StreamBuilder<List<LocalStrokeModel>>(
                                stream: ref
                                    .watch(localStrokeRepositoryProvider)
                                    .watchStrokes(programId),
                                builder: (context, privateSnapshot) {
                                  final privateStrokes =
                                      privateSnapshot.data ?? [];
                                  _cachedPrivateStrokes =
                                      privateStrokes; // ★ 消しゴム用にキャッシュ

                                  final isMarker = _selectedTool == 'marker';
                                  final paintColor = isMarker
                                      ? activePenColor.withAlpha(90)
                                      : activePenColor;
                                  final paintWidth = isMarker
                                      ? penWidth * 3.0
                                      : penWidth;

                                  return CustomPaint(
                                    painter: StrokePainter(
                                      sharedStrokes: sharedStrokes,
                                      privateStrokes: privateStrokes,
                                      currentPoints: _currentPoints,
                                      currentLineColor: paintColor,
                                      activePenWidth: paintWidth,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        // --- 上層：入力レイヤー（書き込みモード時のみ） ---
                        if (_isDrawingMode)
                          Positioned.fill(
                            child: Listener(
                              // ★ GestureDetectorからListenerに変更し、判定の「遊び（遅延）」をゼロに！
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: (event) {
                                if (_selectedTool == 'eraser') {
                                  _eraseStrokeAt(event.localPosition);
                                } else {
                                  setState(
                                    () =>
                                        _currentPoints = [event.localPosition],
                                  );
                                }
                              },
                              onPointerMove: (event) {
                                if (_selectedTool == 'eraser') {
                                  _eraseStrokeAt(event.localPosition);
                                } else {
                                  setState(
                                    () =>
                                        _currentPoints.add(event.localPosition),
                                  );
                                }
                              },
                              onPointerUp: (event) async {
                                if (_selectedTool == 'eraser') {
                                  return;
                                }
                                if (_currentPoints.isNotEmpty) {
                                  final pointsToSave = List<Offset>.from(
                                    _currentPoints,
                                  );
                                  setState(() => _currentPoints.clear());

                                  final isMarker = _selectedTool == 'marker';
                                  final savedColor = isMarker
                                      ? activePenColor.withAlpha(90)
                                      : activePenColor;
                                  final savedWidth = isMarker
                                      ? penWidth * 3.0
                                      : penWidth;

                                  if (activeIsShared && canUseSharedPen) {
                                    final newStroke = StrokeModel(
                                      id: DateTime.now().millisecondsSinceEpoch
                                          .toString(),
                                      programId: programId,
                                      points: pointsToSave,
                                      color: savedColor,
                                      strokeWidth: savedWidth,
                                      isShared: activeIsShared,
                                      pageIndex: _currentIndex,
                                    );
                                    await _getActiveRepository(
                                      ref,
                                    ).addStroke(newStroke);
                                  } else {
                                    final newLocalStroke = LocalStrokeModel()
                                      ..programId = programId
                                      ..pointsX = pointsToSave
                                          .map((p) => p.dx)
                                          .toList()
                                      ..pointsY = pointsToSave
                                          .map((p) => p.dy)
                                          .toList()
                                      ..colorValue = savedColor.toARGB32()
                                      ..strokeWidth = savedWidth
                                      ..createdAt = DateTime.now();
                                    await ref
                                        .read(localStrokeRepositoryProvider)
                                        .addStroke(newLocalStroke);
                                  }
                                }
                              },
                              child: const SizedBox.expand(),
                            ),
                          ),
                      ],
                    );
                  }

                  return InteractiveViewer(
                    transformationController: _transformationController,
                    panEnabled: !_isDrawingMode,
                    scaleEnabled: !_isDrawingMode,
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: Center(
                      child: isFilePdf
                          ? FittedBox(
                              // ★ PDFも画像と同じく「FittedBox」で包み、仮想サイズ(1000x1415)で固定します
                              fit: BoxFit.contain,
                              child: SizedBox(
                                // ★ 物理調停パッチ: 高さを 1415 * ページ数 に拡張することで、
                                // 複数ページPDFをスクロール可能（縦並びの1つのキャンバス）として綺麗にレンダリングします。
                                width: 1000,
                                height:
                                    1415 *
                                    (_pdfPageCounts[program.fileUrl] ?? 1)
                                        .toDouble(),
                                child: Stack(
                                  children: [
                                    // --- 下層：PDF本体 ---
                                    Positioned.fill(
                                      // ★ 物理調停パッチ: Web環境下（kIsWeb）では、認証済みSDK経由 of FutureBuilderを用いて一括フェッチし、
                                      // SfPdfViewer.memoryに安全に流し込むことで、ブラウザ特有のあらゆるCORS/403壁を完全突破します。
                                      child: kIsWeb
                                          ? FutureBuilder<Uint8List>(
                                              future: getCachedPdfBytesViaSdk(
                                                program.fileUrl,
                                              ),
                                              builder: (context, bytesSnapshot) {
                                                if (bytesSnapshot.hasError) {
                                                  return Center(
                                                    child: Text(
                                                      'PDFロード失敗: ${bytesSnapshot.error}',
                                                      style: const TextStyle(
                                                        color: Colors.redAccent,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                if (!bytesSnapshot.hasData) {
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.amber,
                                                        ),
                                                  );
                                                }
                                                return SfPdfViewer.memory(
                                                  bytesSnapshot.data!,
                                                  key: ValueKey(
                                                    program.fileUrl,
                                                  ),
                                                  controller:
                                                      _pdfViewerController,
                                                  canShowScrollHead: false,
                                                  enableDoubleTapZooming: false,
                                                  enableTextSelection: false,
                                                  onDocumentLoaded: (details) {
                                                    final String pdfUrl =
                                                        program.fileUrl;
                                                    final int loadedPageCount =
                                                        details
                                                            .document
                                                            .pages
                                                            .count;
                                                    if (mounted &&
                                                        _pdfPageCounts[pdfUrl] !=
                                                            loadedPageCount) {
                                                      WidgetsBinding.instance
                                                          .addPostFrameCallback((
                                                            _,
                                                          ) {
                                                            if (mounted) {
                                                              setState(() {
                                                                _pdfPageCounts[pdfUrl] =
                                                                    loadedPageCount;
                                                              });
                                                            }
                                                          });
                                                    }
                                                  },
                                                  onDocumentLoadFailed: (details) {
                                                    debugPrint(
                                                      '🚨 PDF Load Failed (Memory): ${details.error} - ${details.description}',
                                                    );
                                                  },
                                                );
                                              },
                                            )
                                          : SfPdfViewer.network(
                                              program.fileUrl,
                                              key: ValueKey(program.fileUrl),
                                              controller: _pdfViewerController,
                                              canShowScrollHead: false,
                                              enableDoubleTapZooming: false,
                                              enableTextSelection: false,
                                              onDocumentLoaded: (details) {
                                                final String pdfUrl =
                                                    program.fileUrl;
                                                final int loadedPageCount =
                                                    details
                                                        .document
                                                        .pages
                                                        .count;
                                                if (mounted &&
                                                    _pdfPageCounts[pdfUrl] !=
                                                        loadedPageCount) {
                                                  WidgetsBinding.instance
                                                      .addPostFrameCallback((
                                                        _,
                                                      ) {
                                                        if (mounted) {
                                                          setState(() {
                                                            _pdfPageCounts[pdfUrl] =
                                                                loadedPageCount;
                                                          });
                                                        }
                                                      });
                                                }
                                              },
                                              onDocumentLoadFailed: (details) {
                                                debugPrint(
                                                  '🚨 PDF Load Failed: ${details.error} - ${details.description}',
                                                );
                                              },
                                            ),
                                    ),

                                    // --- 上層：描画レイヤー（PDF用も8.0〜10.0程度の太さに固定） ---
                                    buildOverlayLayers(penWidth: 10.0),
                                  ],
                                ),
                              ),
                            )
                          : FutureBuilder<Size>(
                              // ★ 修正: FutureBuilder にキャッシュしたFutureを渡し、毎フレームごとの無限クルクルを防止
                              future: _getCachedImageSize(program.fileUrl),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                final imgSize = snapshot.data!;

                                // ★ 致命的なレンダリングクラッシュの回避策：
                                // WebGLのテクスチャ上限を超える巨大な画像(4K写真など)を、
                                // 安全なサイズ(最大2048px)に縮小して仮想キャンバスを作成します。
                                const double maxDimension = 2048.0;
                                final bool isTooLarge =
                                    imgSize.width > maxDimension ||
                                    imgSize.height > maxDimension;
                                final double scale = isTooLarge
                                    ? (maxDimension /
                                          (imgSize.width > imgSize.height
                                              ? imgSize.width
                                              : imgSize.height))
                                    : 1.0;
                                final Size displaySize = Size(
                                  imgSize.width * scale,
                                  imgSize.height * scale,
                                );

                                // ★ 縮小後の仮想キャンバスサイズに合わせてペンの太さを自動計算
                                final double imagePenWidth =
                                    (displaySize.width * 0.005).clamp(
                                      8.0,
                                      50.0,
                                    );

                                // ★ 究極の解決策：画像そのものと同じサイズの透明な枠を作り、丸ごと縮小させる
                                return FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: displaySize.width,
                                    height: displaySize.height,
                                    child: Stack(
                                      children: [
                                        // ★ 修正: WebGLの巨大テクスチャ上限突破エラーを防ぐためRepaintBoundaryを解除
                                        Positioned.fill(
                                          child: Image.network(
                                            _getSafeUrl(program.fileUrl),
                                            fit: BoxFit.fill,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey.shade200,
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        size: 64,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        ),

                                        // --- OCRハイライトレイヤー ---
                                        Builder(
                                          builder: (context) {
                                            final ocrWords = program.ocrWords;
                                            if (_isSearchMode &&
                                                _currentSearchText.isNotEmpty &&
                                                ocrWords != null) {
                                              return Positioned.fill(
                                                child: CustomPaint(
                                                  painter: OcrHighlightPainter(
                                                    ocrWords: ocrWords,
                                                    searchText:
                                                        _currentSearchText,
                                                    originalImageSize:
                                                        imgSize, // ★ 追加：座標計算のため元の画像サイズを渡す
                                                  ),
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),

                                        // 手書きレイヤー
                                        buildOverlayLayers(
                                          penWidth: imagePenWidth,
                                        ), // ★ 自動計算した太さを渡す
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required String tool,
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required Color activeColor,
  }) {
    final isSelected = _selectedTool == tool;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() => _selectedTool = tool),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.grey.shade800 : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected
                ? activeColor
                : (isDark ? Colors.white38 : Colors.black38),
          ),
        ),
      ),
    );
  }

  // ペンの名前を返す補助関数
  String _getPenName(Color color) {
    if (color == Colors.pink) return 'ピンク';
    if (color == _yellowPenColor || color == Colors.yellow) return 'イエロー';
    if (color == Colors.blue) return 'ブルー';
    if (color == Colors.black87) return 'ブラック';
    return 'ペン';
  }

  // ペン選択用のボトムシートを表示
  void _showPenPicker(
    BuildContext context,
    WidgetRef ref,
    bool canUseSharedPen,
  ) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true, // ★ 追加: ボトムシートの高さ制限を解除
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              top: 20.0,
              left: 20.0,
              right: 20.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
            ),
            child: SingleChildScrollView(
              // ★ 追加: はみ出しを防ぐためスクロール可能に
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ペンの選択',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (canUseSharedPen) ...[
                    const Text(
                      '📢 共有ペン (全員の画面に反映されます)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildLargePenOption(context, Colors.pink, 'ピンク (共有)'),
                        const SizedBox(width: 10),
                        _buildLargePenOption(
                          context,
                          _yellowPenColor,
                          'イエロー (共有)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                  ],
                  const Text(
                    '📝 個人ペン (自分だけのメモです)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildLargePenOption(context, Colors.blue, 'ブルー (個人)'),
                      const SizedBox(width: 10),
                      _buildLargePenOption(
                        context,
                        Colors.black87,
                        'ブラック (個人)',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ボトムシート内の大きな選択ボタン
  Widget _buildLargePenOption(BuildContext context, Color color, String label) {
    final isSelected = _selectedPenColor == color;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedPenColor = color);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(26) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.edit, color: color, size: 28),
              const SizedBox(height: 8),
              // ★ はみ出しエラー修正: ペン名が長くても絶対に改行・はみ出しが起きないようにFittedBoxでガード
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ★ 赤線と青線を両方描画する強化版ペインター
class StrokePainter extends CustomPainter {
  final List<StrokeModel> sharedStrokes;
  final List<LocalStrokeModel> privateStrokes;
  final List<Offset>? currentPoints;
  final Color currentLineColor;
  final double activePenWidth; // ★ 追加

  StrokePainter({
    required this.sharedStrokes,
    required this.privateStrokes,
    this.currentPoints,
    required this.currentLineColor,
    required this.activePenWidth, // ★ 追加
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 共有の線(赤)を描画
    for (final stroke in sharedStrokes) {
      // ★ 過去に描いた「細すぎる線(4.0等)」も、今の太さに補正して見やすくする救済措置！
      final width = stroke.strokeWidth < 6.0
          ? activePenWidth
          : stroke.strokeWidth;
      final paint = getPaint(stroke.color, width);
      _drawPoints(canvas, stroke.points, paint);
    }

    // 2. 個人の線(青)を描画 (X/YのリストからOffsetを復元)
    for (final stroke in privateStrokes) {
      final width = stroke.strokeWidth < 6.0
          ? activePenWidth
          : stroke.strokeWidth;
      final paint = getPaint(Color(stroke.colorValue), width);
      if (stroke.pointsX.length < 2) continue;

      final path = Path();
      path.moveTo(stroke.pointsX.first, stroke.pointsY.first);
      for (int i = 1; i < stroke.pointsX.length; i++) {
        path.lineTo(stroke.pointsX[i], stroke.pointsY[i]);
      }
      canvas.drawPath(path, paint);
    }

    // 3. 今まさに引いている線を描画
    final current = currentPoints;
    if (current != null && current.isNotEmpty) {
      final paint = getPaint(currentLineColor, activePenWidth); // ★ 新しい太さを使用
      _drawPoints(canvas, current, paint);
    }
  }

  Paint getPaint(Color color, double width) {
    // 🛡️ 救済パッチ：過去にColors.yellow(0xFFFFEB3B)で書かれたアノテーションデータを読み込んだ場合、
    // 自動的に視認性の高いゴールドイエロー(0xFFCA8A04)に色補正してレンダリングする
    Color finalColor = color;
    if (color.r == Colors.yellow.r &&
        color.g == Colors.yellow.g &&
        color.b == Colors.yellow.b) {
      finalColor = const Color(
        0xFFCA8A04,
      ).withAlpha((color.a * 255.0).round().clamp(0, 255));
    }

    final paint = Paint()
      ..color = finalColor
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // 不透明度が0.8未満（半透明）の場合はラインマーカーと見なし、乗算（blendMode）を適用する
    if (finalColor.a < 0.8) {
      paint.blendMode = BlendMode.multiply;
    }
    return paint;
  }

  void _drawPoints(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    // ★ 修正：画面にポンッと触れた瞬間（点が1つ）の時に、「極小の線（点）」を描画する！
    if (points.length == 1) {
      path.lineTo(points.first.dx + 0.1, points.first.dy + 0.1);
      canvas.drawPath(path, paint);
      return;
    }

    if (points.length < 3) {
      path.lineTo(points.last.dx, points.last.dy);
    } else {
      for (int i = 1; i < points.length - 1; i++) {
        final xc = (points[i].dx + points[i + 1].dx) / 2;
        final yc = (points[i].dy + points[i + 1].dy) / 2;
        path.quadraticBezierTo(points[i].dx, points[i].dy, xc, yc);
      }
      path.lineTo(points.last.dx, points.last.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) {
    // ★ 最適化: リスト長のショートサーキット判定で変化を最速検知
    // ストローク追加・削除時は長さが変わるため参照比較より前に判定する
    if (oldDelegate.sharedStrokes.length != sharedStrokes.length) return true;
    if (oldDelegate.privateStrokes.length != privateStrokes.length) return true;
    if (oldDelegate.currentLineColor != currentLineColor) return true;
    if (oldDelegate.activePenWidth != activePenWidth) return true;
    // 描画中の点列は参照比較で十分（毎フレーム新しいリストが渡される）
    if (oldDelegate.currentPoints != currentPoints) return true;
    // 内容変化はリスト参照変化で十分（保存完了時はリスト参照が入れ替わる）
    return oldDelegate.sharedStrokes != sharedStrokes ||
        oldDelegate.privateStrokes != privateStrokes;
  }
}

// ★ 画像OCR用のハイライト描画ペインター（計算不要の絶対座標版）
class OcrHighlightPainter extends CustomPainter {
  final List<dynamic> ocrWords;
  final String searchText;
  final Size originalImageSize; // ★ 追加

  OcrHighlightPainter({
    required this.ocrWords,
    required this.searchText,
    required this.originalImageSize, // ★ 追加
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (searchText.isEmpty) return;

    // ★ 追加：描画キャンバス(size)と元画像(originalImageSize)のサイズから縮尺を計算
    if (originalImageSize.width == 0) return;
    final double scale = size.width / originalImageSize.width;

    final paint = Paint()
      ..color = Colors.pinkAccent.withAlpha(128)
      ..style = PaintingStyle.fill;

    for (var wordData in ocrWords) {
      if (wordData is Map<String, dynamic>) {
        final text = wordData['text'] as String?;
        // 検索ワードが含まれているか判定
        if (text != null &&
            text.toLowerCase().contains(searchText.toLowerCase())) {
          final vertices = wordData['vertices'] as List<dynamic>?;
          if (vertices != null && vertices.length == 4) {
            double minX = double.infinity, minY = double.infinity;
            double maxX = 0, maxY = 0;

            for (var vertex in vertices) {
              // ★ 修正：元の画像座標に縮尺(scale)を掛けて、現在のキャンバスサイズに合わせる
              final x = ((vertex['x'] as num?)?.toDouble() ?? 0.0) * scale;
              final y = ((vertex['y'] as num?)?.toDouble() ?? 0.0) * scale;
              if (x < minX) minX = x;
              if (y < minY) minY = y;
              if (x > maxX) maxX = x;
              if (y > maxY) maxY = y;
            }

            // 余白を少し持たせて角丸で綺麗に塗る（元の画像サイズ基準なので少し数値を大きくしています）
            final padding = size.width * 0.005; // 描画領域の幅の0.5%の余白
            final rect = Rect.fromLTRB(
              minX - padding,
              minY - padding,
              maxX + padding,
              maxY + padding,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, Radius.circular(padding)),
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant OcrHighlightPainter oldDelegate) {
    return oldDelegate.searchText != searchText ||
        oldDelegate.ocrWords != ocrWords ||
        oldDelegate.originalImageSize != originalImageSize;
  }
}
