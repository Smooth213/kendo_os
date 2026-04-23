import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/program_model.dart' hide StrokeModel;
import '../models/stroke_model.dart';
import '../models/local_stroke_model.dart';
import '../repositories/stroke_repository.dart';
import '../repositories/local_stroke_repository.dart';
import '../providers/role_provider.dart';

class ProgramViewerScreen extends ConsumerStatefulWidget {
  final List<ProgramModel> programs;
  final int initialIndex;

  const ProgramViewerScreen({super.key, required this.programs, required this.initialIndex});

  @override
  ConsumerState<ProgramViewerScreen> createState() => _ProgramViewerScreenState();
}

class _ProgramViewerScreenState extends ConsumerState<ProgramViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  // ★ PDF検索用のコントローラーと状態管理
  final PdfViewerController _pdfViewerController = PdfViewerController();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  final TextEditingController _searchTextController = TextEditingController();
  bool _isSearchMode = false;
  
  // ★ 画像OCR検索用の状態管理
  String _currentSearchText = "";

  bool _isDrawingMode = false;
  Color _selectedPenColor = Colors.redAccent; // ★ 4色を管理
  bool get _isSharedPen => _selectedPenColor == Colors.redAccent || _selectedPenColor == Colors.amber;
  List<Offset> _currentPoints = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<Size> _fetchImageSize(String url) async {
    final Completer<Size> completer = Completer();
    final Image image = Image.network(url);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          if (!completer.isCompleted) {
            completer.complete(Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            ));
          }
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          if (!completer.isCompleted) {
            completer.complete(const Size(800, 1000)); // エラー時のフォールバック
          }
        },
      ),
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    // ★ role_providerから「現在の有効な役割」を取得し、共有ペンが使えるか判定
    final currentRole = ref.watch(activeRoleProvider);
    final canUseSharedPen = currentRole == Role.admin || currentRole == Role.scorer || currentRole == Role.editor;

    // 権限がないのに共有ペンが選ばれている場合のフォールバック（強制的に青にする）
    final activePenColor = (!canUseSharedPen && _isSharedPen) ? Colors.blueAccent : _selectedPenColor;
    final activeIsShared = activePenColor == Colors.redAccent || activePenColor == Colors.amber;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentProgram = widget.programs[_currentIndex];
    final isFilePdf = currentProgram.fileType == 'pdf' || currentProgram.fileUrl.toLowerCase().contains('.pdf');
    
    final programId = currentProgram.id.isNotEmpty ? currentProgram.id : currentProgram.fileUrl;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        elevation: _isDrawingMode ? 0 : 1,
        // ★ 検索モード時はタイトルをTextFieldに切り替える
        title: _isSearchMode
            ? TextField(
                controller: _searchTextController,
                autofocus: true,
                decoration: const InputDecoration(hintText: '選手名・団体名を検索...', border: InputBorder.none),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('現在クラウドで解析中です。しばらくお待ちください。'))
                      );
                    } else if (currentProgram.ocrWords == null || currentProgram.ocrWords!.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('この画像から文字が検出されませんでした。'))
                      );
                    }
                  }
                  setState(() {});
                },
              )
            : Text(
                '${currentProgram.title} (${_currentIndex + 1}/${widget.programs.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
        actions: [
          // ★ 検索モード時のナビゲーションと「閉じる」ボタン（画像・PDF共通）
          if (_isSearchMode) ...[
            if (isFilePdf) ...[
              IconButton(icon: const Icon(Icons.keyboard_arrow_up), onPressed: () => _searchResult.previousInstance()),
              IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: () => _searchResult.nextInstance()),
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
              StreamBuilder<bool>(
                stream: Stream.value(currentProgram.isOcrProcessed ?? false),
                builder: (context, snapshot) {
                  final isProcessed = snapshot.data ?? false;
                  return isProcessed 
                    ? const Icon(Icons.bolt, color: Colors.amber, size: 16)
                    : const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey));
                }
              ),
            // 検索ボタン
            IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => _isSearchMode = true)),
          ],

          // ★ 書き込むボタン（検索モードでも常に見えるように外に出しました！）
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => setState(() {
                _isDrawingMode = !_isDrawingMode;
                // 注意: ここにあった `_isSearchMode = false;` を削除したことで共存が可能になりました！
              }),
              icon: Icon(_isDrawingMode ? Icons.check : Icons.edit, size: 18),
              label: Text(_isDrawingMode ? '完了' : '書き込む'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDrawingMode ? activePenColor : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                foregroundColor: _isDrawingMode ? Colors.white : (isDark ? Colors.white : Colors.black87),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  // 1. 現在のペンを表示し、タップで選択シートを開くボタン
                  Expanded(
                    child: InkWell(
                      onTap: () => _showPenPicker(context, ref, canUseSharedPen),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: activePenColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: activePenColor.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: 18, color: activePenColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                activeIsShared ? '${_getPenName(activePenColor)} (共有)' : '${_getPenName(activePenColor)} (個人)',
                                style: TextStyle(
                                  color: activePenColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: activePenColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 2. 取り消しボタン
                  IconButton(
                    icon: const Icon(Icons.undo),
                    tooltip: '1つ戻す',
                    onPressed: () {
                      if (activeIsShared) {
                        ref.read(strokeRepositoryProvider).undoLastStroke(programId);
                      } else {
                        ref.read(localStrokeRepositoryProvider).undoLastStroke(programId);
                      }
                    },
                  ),
                  // 3. 全消去ボタン
                  // 3. 全消去ボタン（確認ダイアログ付き）
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.grey),
                    tooltip: 'すべて消す',
                    onPressed: () async {
                      // ★ いきなり消さず、まずダイアログを表示して「はい/いいえ」を聞く
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('全消去の確認', style: TextStyle(fontWeight: FontWeight.bold)),
                          content: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: activeIsShared 
                                  ? 'このプログラムに引かれた【共有ペン】をすべて消去しますか？\n' 
                                  : 'このプログラムに引かれた【個人ペン】をすべて消去しますか？\n'),
                                if (activeIsShared)
                                  const TextSpan(
                                    text: '※他の人の画面からも消えてしまいます。間違いないですか？\n',
                                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                  ),
                                const TextSpan(text: '※一度削除したデータは元に戻すことができません。'),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false), // キャンセル
                              child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true), // 実行
                              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                              child: const Text('すべて消去する'),
                            ),
                          ],
                        ),
                      );

                      // ★ ダイアログで「消去する(true)」が選ばれた時だけ、本当に削除する
                      if (shouldDelete == true) {
                        if (activeIsShared) {
                          ref.read(strokeRepositoryProvider).clearStrokes(programId);
                        } else {
                          ref.read(localStrokeRepositoryProvider).clearStrokes(programId);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),

          // --- 共通ビューア部分（PDF/画像の両方で手書き可能） ---
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: _isDrawingMode ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics(),
              itemCount: widget.programs.length,
              onPageChanged: (index) => setState(() {
                _currentIndex = index;
                _isDrawingMode = false;
              }),
              itemBuilder: (context, index) {
                final program = widget.programs[index];
                final isFilePdf = program.fileType == 'pdf' || program.fileUrl.toLowerCase().contains('.pdf');
                final programId = program.id.isNotEmpty ? program.id : program.fileUrl;

                // ★ 引数にペンの太さ(penWidth)を追加
                Widget buildOverlayLayers({required double penWidth}) {
                  return Stack(
                    children: [
                      // --- 中層：描画レイヤー（共有 ＋ 個人） ---
                      Positioned.fill(
                        child: StreamBuilder<List<StrokeModel>>(
                          stream: ref.watch(strokeRepositoryProvider).watchStrokes(programId),
                          builder: (context, sharedSnapshot) {
                            final sharedStrokes = sharedSnapshot.data ?? [];
                            return StreamBuilder<List<LocalStrokeModel>>(
                              stream: ref.watch(localStrokeRepositoryProvider).watchStrokes(programId),
                              builder: (context, privateSnapshot) {
                                final privateStrokes = privateSnapshot.data ?? [];
                                return CustomPaint(
                                  painter: StrokePainter(
                                    sharedStrokes: sharedStrokes,
                                    privateStrokes: privateStrokes,
                                    currentPoints: _currentPoints,
                                    currentLineColor: activePenColor,
                                    activePenWidth: penWidth, // ★ 渡された太さをペインターに送る
                                  ),
                                  size: Size.infinite,
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
                            onPointerDown: (event) => setState(() => _currentPoints = [event.localPosition]),
                            onPointerMove: (event) => setState(() => _currentPoints.add(event.localPosition)),
                            onPointerUp: (event) async {
                              if (_currentPoints.isNotEmpty) {
                                final pointsToSave = List<Offset>.from(_currentPoints);
                                setState(() => _currentPoints.clear());

                                if (activeIsShared && canUseSharedPen) {
                                  final newStroke = StrokeModel(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    programId: programId,
                                    points: pointsToSave,
                                    color: activePenColor,
                                    strokeWidth: penWidth,
                                  );
                                  await ref.read(strokeRepositoryProvider).addStroke(newStroke);
                                } else {
                                  final newLocalStroke = LocalStrokeModel()
                                    ..programId = programId
                                    ..pointsX = pointsToSave.map((p) => p.dx).toList()
                                    ..pointsY = pointsToSave.map((p) => p.dy).toList()
                                    ..colorValue = activePenColor.toARGB32()
                                    ..strokeWidth = penWidth
                                    ..createdAt = DateTime.now();
                                  await ref.read(localStrokeRepositoryProvider).addStroke(newLocalStroke);
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
                  panEnabled: !_isDrawingMode,
                  scaleEnabled: !_isDrawingMode,
                  minScale: 1.0,
                  maxScale: 5.0,
                  child: Center(
                    child: isFilePdf
                        ? FittedBox(
                            // ★ PDFも画像と同じく「FittedBox」で包み、仮想サイズ(1000x1414等)で固定します
                            fit: BoxFit.contain,
                            child: SizedBox(
                              // A4サイズに近い論理サイズを設定（1000px基準）
                              width: 1000,
                              height: 1414, 
                              child: Stack(
                                children: [
                                  // --- 下層：PDF本体 ---
                                  Positioned.fill(
                                    // ★ 最適化：PDFの再描画をブロックし、ペン入力時の負荷を激減させる
                                    child: RepaintBoundary(
                                      child: SfPdfViewer.network(
                                        program.fileUrl,
                                        key: ValueKey(program.fileUrl),
                                        controller: _pdfViewerController,
                                        canShowScrollHead: false,
                                        enableDoubleTapZooming: false,
                                        enableTextSelection: false,
                                      ),
                                    ),
                                  ),
                                  
                                  // --- 上層：描画レイヤー（PDF用も8.0〜10.0程度の太さに固定） ---
                                  buildOverlayLayers(penWidth: 10.0),
                                ],
                              ),
                            ),
                          )
                        : FutureBuilder<Size>(
                            future: _fetchImageSize(program.fileUrl),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                              final imgSize = snapshot.data!;
                              
                              // ★ 画像サイズに合わせてペンの太さを自動計算（幅の0.5%、最低でも8.0）
                              final double imagePenWidth = (imgSize.width * 0.005).clamp(8.0, 50.0);
                              
                              // ★ 究極の解決策：画像そのものと同じサイズの透明な枠を作り、丸ごと縮小させる
                              return FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: imgSize.width,
                                  height: imgSize.height,
                                  child: Stack(
                                    children: [
                                      // ★ 最適化：巨大な画像の再描画をブロックする
                                      RepaintBoundary(
                                        child: Image.network(program.fileUrl, fit: BoxFit.fill),
                                      ),
                                      
                                      // --- OCRハイライトレイヤー ---
                                      if (_isSearchMode && _currentSearchText.isNotEmpty && program.ocrWords != null)
                                        Positioned.fill(
                                          // ★ 最適化：検索ハイライトもペン入力時には再描画しない
                                          child: RepaintBoundary(
                                            child: CustomPaint(
                                              painter: OcrHighlightPainter(
                                                ocrWords: program.ocrWords!,
                                                searchText: _currentSearchText,
                                              ),
                                            ),
                                          ),
                                        ),
                                        
                                      // 手書きレイヤー
                                      buildOverlayLayers(penWidth: imagePenWidth), // ★ 自動計算した太さを渡す
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
    );
  }

  // ペンの名前を返す補助関数
  String _getPenName(Color color) {
    if (color == Colors.redAccent) return '赤ペン';
    if (color == Colors.amber) return '黄ペン';
    if (color == Colors.blueAccent) return '青ペン';
    if (color == Colors.black87) return '黒ペン';
    return 'ペン';
  }

  // ペン選択用のボトムシートを表示
  void _showPenPicker(BuildContext context, WidgetRef ref, bool canUseSharedPen) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ペンの選択', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                if (canUseSharedPen) ...[
                  const Text(
                    '📢 共有ペン (全員の画面に反映されます)', 
                    style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildLargePenOption(context, Colors.redAccent, '赤ペン (共有)'),
                      const SizedBox(width: 10),
                      _buildLargePenOption(context, Colors.amber, '黄ペン (共有)'),
                    ],
                  ),
                  const SizedBox(height: 25),
                ],
                const Text(
                  '📝 個人ペン (自分だけのメモです)', 
                  style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildLargePenOption(context, Colors.blueAccent, '青ペン (個人)'),
                    const SizedBox(width: 10),
                    _buildLargePenOption(context, Colors.black87, '黒ペン (個人)'),
                  ],
                ),
                const SizedBox(height: 10),
              ],
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
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 2),
          ),
          child: Column(
            children: [
              Icon(Icons.edit, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
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
      final width = stroke.strokeWidth < 6.0 ? activePenWidth : stroke.strokeWidth;
      final paint = _getPaint(stroke.color, width);
      _drawPoints(canvas, stroke.points, paint);
    }

    // 2. 個人の線(青)を描画 (X/YのリストからOffsetを復元)
    for (final stroke in privateStrokes) {
      final width = stroke.strokeWidth < 6.0 ? activePenWidth : stroke.strokeWidth;
      final paint = _getPaint(Color(stroke.colorValue), width);
      if (stroke.pointsX.length < 2) continue;
      
      final path = Path();
      path.moveTo(stroke.pointsX.first, stroke.pointsY.first);
      for (int i = 1; i < stroke.pointsX.length; i++) {
        path.lineTo(stroke.pointsX[i], stroke.pointsY[i]);
      }
      canvas.drawPath(path, paint);
    }

    // 3. 今まさに引いている線を描画
    if (currentPoints != null && currentPoints!.isNotEmpty) {
      final paint = _getPaint(currentLineColor, activePenWidth); // ★ 新しい太さを使用
      _drawPoints(canvas, currentPoints!, paint);
    }
  }

  Paint _getPaint(Color color, double width) {
    return Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ★ 画像OCR用のハイライト描画ペインター（計算不要の絶対座標版）
class OcrHighlightPainter extends CustomPainter {
  final List<dynamic> ocrWords;
  final String searchText;

  OcrHighlightPainter({
    required this.ocrWords,
    required this.searchText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (searchText.isEmpty) return;

    final paint = Paint()
      ..color = Colors.pinkAccent.withValues(alpha: 0.5) 
      ..style = PaintingStyle.fill;

    for (var wordData in ocrWords) {
      if (wordData is Map<String, dynamic>) {
        final text = wordData['text'] as String?;
        // 検索ワードが含まれているか判定
        if (text != null && text.toLowerCase().contains(searchText.toLowerCase())) {
          final vertices = wordData['vertices'] as List<dynamic>?;
          if (vertices != null && vertices.length == 4) {
            
            double minX = double.infinity, minY = double.infinity;
            double maxX = 0, maxY = 0;

            for (var vertex in vertices) {
              // ★ キャンバス自体が画像サイズと同じになったので、比率の掛け算が一切不要になりました！
              // AIが教えてくれた座標(x, y)をそのまま使うだけで、1ミリもズレません。
              final x = (vertex['x'] as num?)?.toDouble() ?? 0.0;
              final y = (vertex['y'] as num?)?.toDouble() ?? 0.0;
              if (x < minX) minX = x;
              if (y < minY) minY = y;
              if (x > maxX) maxX = x;
              if (y > maxY) maxY = y;
            }

            // 余白を少し持たせて角丸で綺麗に塗る（元の画像サイズ基準なので少し数値を大きくしています）
            final padding = size.width * 0.005; // 画像幅の0.5%の余白
            final rect = Rect.fromLTRB(minX - padding, minY - padding, maxX + padding, maxY + padding);
            canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(padding)), paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant OcrHighlightPainter oldDelegate) {
    return oldDelegate.searchText != searchText || oldDelegate.ocrWords != ocrWords;
  }
}