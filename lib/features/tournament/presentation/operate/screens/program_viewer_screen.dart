import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/score/stroke_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_drawing_toolbar.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_image_body.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_material_placeholder.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_pdf_body.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_stroke_eraser.dart';
import 'package:kendo_os/features/tournament/presentation/painters/program_viewer_painters.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart'
    hide StrokeModel;
import 'package:kendo_os/shared/infrastructure/persistence/models/local_stroke_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_stroke_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/program_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/stroke_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../providers/permission_provider.dart';
import '../providers/role_provider.dart';

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
  static const Color _yellowPenColor = Color(0xFFCA8A04);

  late PageController _pageController;
  late int _currentIndex;
  final Map<String, int> _pdfPageCounts = {};

  @visibleForTesting
  Map<String, int> get pdfPageCountsForTesting => _pdfPageCounts;

  final TransformationController _transformationController =
      TransformationController();
  bool _isZoomed = false;

  String _selectedTool = 'pen';
  List<StrokeModel> _cachedSharedStrokes = [];
  List<LocalStrokeModel> _cachedPrivateStrokes = [];

  final PdfViewerController _pdfViewerController = PdfViewerController();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  final TextEditingController _searchTextController = TextEditingController();
  bool _isSearchMode = false;
  String _currentSearchText = "";

  bool _isDrawingMode = false;
  Color _selectedPenColor = AppKendoColors.pink;
  bool get _isSharedPen =>
      _selectedPenColor == AppKendoColors.pink ||
      _selectedPenColor == _yellowPenColor;
  List<Offset> _currentPoints = [];

  final Map<String, Future<Size>> _imageSizeCache = {};
  final int _sessionBuster = DateTime.now().millisecondsSinceEpoch;

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
      _sdkPdfBytesCache[url] = FirebaseStorage.instance
          .refFromURL(url)
          .getData(32 * 1024 * 1024)
          .then((value) {
            return value!;
          });
    }
    return _sdkPdfBytesCache[url]!;
  }

  dynamic _getActiveRepository(WidgetRef ref) {
    return ref.read(strokeRepositoryProvider);
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
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
    final bool zoomed = scale > 1.01;
    if (zoomed != _isZoomed) {
      setState(() {
        _isZoomed = zoomed;
      });
    }
  }

  Future<void> _eraseStrokeAt(Offset touchPoint) async {
    const double threshold = 25.0;
    final currentRole = ref.read(activeRoleProvider);
    final canUseSharedPen =
        currentRole == Role.admin ||
        currentRole == Role.scorer ||
        currentRole == Role.editor;

    if (canUseSharedPen) {
      for (final stroke in _cachedSharedStrokes) {
        if (ProgramViewerStrokeEraser.isNearStroke(
          touchPoint,
          stroke.points,
          threshold,
        )) {
          await _getActiveRepository(ref).deleteStroke(stroke.id);
          return;
        }
      }
    }

    for (final stroke in _cachedPrivateStrokes) {
      if (ProgramViewerStrokeEraser.isNearLocalStroke(
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

  Future<Size> _fetchImageSize(String url) async {
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
          completer.complete(const Size(800, 1000));
        }
      },
    );

    image.image.resolve(const ImageConfiguration()).addListener(listener);
    return completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        if (!completer.isCompleted) {
          image.image
              .resolve(const ImageConfiguration())
              .removeListener(listener);
        }
        return const Size(800, 1000);
      },
    );
  }

  Future<Size> _getCachedImageSize(String url) {
    if (!_imageSizeCache.containsKey(url)) {
      _imageSizeCache[url] = _fetchImageSize(url);
    }
    return _imageSizeCache[url]!;
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(permissionProvider);
    final currentRole = ref.watch(activeRoleProvider);
    final canUseSharedPen =
        currentRole == Role.admin ||
        currentRole == Role.scorer ||
        currentRole == Role.editor;

    final activePenColor = (!canUseSharedPen && _isSharedPen)
        ? AppKendoColors.blue
        : _selectedPenColor;
    final activeIsShared =
        activePenColor == AppKendoColors.pink ||
        activePenColor == _yellowPenColor;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tournamentId = widget.programs.isNotEmpty
        ? widget.programs.first.tournamentId
        : '';
    final AsyncValue<List<ProgramModel>?> realtimeProgramsAsync =
        tournamentId.isNotEmpty
        ? ref.watch(viewerProgramListProvider(tournamentId))
        : const AsyncData<List<ProgramModel>?>(null);

    final displayPrograms = realtimeProgramsAsync.when(
      data: (realtimeList) => realtimeList ?? widget.programs,
      loading: () => widget.programs,
      error: (error, stackTrace) => widget.programs,
    );

    if (displayPrograms.isEmpty) {
      return LiquidBackground(
        child: Scaffold(
          backgroundColor: AppKendoColors.transparent,
          appBar: const AppHeader(title: 'プログラム'),
          body: const Center(child: Text('表示できるプログラムがありません。')),
        ),
      );
    }

    final safeIndex = _currentIndex.clamp(0, displayPrograms.length - 1);
    final currentProgram = displayPrograms[safeIndex];

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
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          backgroundColor: isDark
              ? const Color(0xFF1C1C1E)
              : context.appColors.cardBackground,
          foregroundColor: context.appColors.textColor,
          elevation: _isDrawingMode ? 0 : 1,
          titleWidget: _isSearchMode
              ? AppTextField(
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
                      _searchResult = _pdfViewerController.searchText(value);
                      _searchResult.addListener(() {
                        if (mounted) setState(() {});
                      });
                    } else {
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
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.subhead,
                  ),
                ),
          actions: [
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
            if (!_isSearchMode) ...[
              if (!isFilePdf)
                Tooltip(
                  message: (currentProgram.isOcrProcessed ?? false)
                      ? '文字検索の準備完了'
                      : '画像解析の準備中',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Icon(
                      Icons.bolt,
                      color: (currentProgram.isOcrProcessed ?? false)
                          ? AppKendoColors.amber
                          : const Color(0xFFBDBDBD),
                      size: 20,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => setState(() => _isSearchMode = true),
              ),
            ],
            if (!permissions.isReadOnly)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: MediaQuery.of(context).size.width < 600 || _isSearchMode
                    ? IconButton(
                        onPressed: () => setState(() {
                          _isDrawingMode = !_isDrawingMode;
                        }),
                        icon: Icon(_isDrawingMode ? Icons.check : Icons.edit),
                        color: _isDrawingMode
                            ? activePenColor
                            : (context.appColors.textColor),
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
                              : (context.appColors.separatorColor),
                          foregroundColor: _isDrawingMode
                              ? AppKendoColors.pureWhite
                              : (context.appColors.textColor),
                          elevation: 0,
                        ),
                      ),
              ),
          ],
        ),
        body: Column(
          children: [
            if (_isDrawingMode)
              ProgramViewerDrawingToolbar(
                selectedTool: _selectedTool,
                activePenColor: activePenColor,
                activeIsShared: activeIsShared,
                canUseSharedPen: canUseSharedPen,
                isDark: isDark,
                onSelectTool: (tool) => setState(() => _selectedTool = tool),
                onSelectPenColor: (color) =>
                    setState(() => _selectedPenColor = color),
                onUndo: () {
                  if (activeIsShared) {
                    _getActiveRepository(ref).undoLastStroke(programId);
                  } else {
                    ref
                        .read(localStrokeRepositoryProvider)
                        .undoLastStroke(programId);
                  }
                },
                onClearAll: () {
                  if (activeIsShared) {
                    _getActiveRepository(ref).clearStrokes(programId);
                  } else {
                    ref
                        .read(localStrokeRepositoryProvider)
                        .clearStrokes(programId);
                  }
                },
              ),
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

                  final isItemMaterialOnly =
                      program.fileUrl.isEmpty ||
                      !program.fileUrl.startsWith('http');
                  if (isItemMaterialOnly) {
                    return ProgramViewerMaterialPlaceholder(
                      program: program,
                      isDark: isDark,
                    );
                  }

                  final isFilePdf =
                      program.fileType == 'pdf' ||
                      program.fileUrl.toLowerCase().contains('.pdf');
                  final programId = program.id.isNotEmpty
                      ? program.id
                      : program.fileUrl;

                  Widget buildOverlayLayers({required double penWidth}) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: StreamBuilder<List<StrokeModel>>(
                            stream: ref
                                .watch(strokeRepositoryProvider)
                                .watchStrokes(programId),
                            builder: (context, sharedSnapshot) {
                              final sharedStrokes = sharedSnapshot.data ?? [];
                              _cachedSharedStrokes = sharedStrokes;
                              return StreamBuilder<List<LocalStrokeModel>>(
                                stream: ref
                                    .watch(localStrokeRepositoryProvider)
                                    .watchStrokes(programId),
                                builder: (context, privateSnapshot) {
                                  final privateStrokes =
                                      privateSnapshot.data ?? [];
                                  _cachedPrivateStrokes = privateStrokes;

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
                        if (_isDrawingMode)
                          Positioned.fill(
                            child: Listener(
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
                          ? ProgramViewerPdfBody(
                              program: program,
                              pageCount: _pdfPageCounts[program.fileUrl] ?? 1,
                              pdfViewerController: _pdfViewerController,
                              sdkPdfBytesFuture: kIsWeb
                                  ? getCachedPdfBytesViaSdk(program.fileUrl)
                                  : null,
                              onPageCountLoaded: (count) {
                                if (mounted &&
                                    _pdfPageCounts[program.fileUrl] != count) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      setState(() {
                                        _pdfPageCounts[program.fileUrl] = count;
                                      });
                                    }
                                  });
                                }
                              },
                              overlayLayers: buildOverlayLayers(penWidth: 10.0),
                            )
                          : ProgramViewerImageBody(
                              program: program,
                              imageSizeFuture: _getCachedImageSize(
                                program.fileUrl,
                              ),
                              safeUrl: _getSafeUrl(program.fileUrl),
                              isSearchMode: _isSearchMode,
                              currentSearchText: _currentSearchText,
                              buildOverlayLayers: (w) =>
                                  buildOverlayLayers(penWidth: w),
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
}
