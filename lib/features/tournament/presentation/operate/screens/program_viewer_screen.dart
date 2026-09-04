import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_canvas_overlay.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_drawing_toolbar.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_image_body.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_material_placeholder.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_media_cache.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_pdf_body.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart'
    hide StrokeModel;
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
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';

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
  final Map<String, int> _pdfCurrentPages = {};

  @visibleForTesting
  Map<String, int> get pdfPageCountsForTesting => _pdfPageCounts;

  final TransformationController _transformationController =
      TransformationController();
  bool _isZoomed = false;

  String _selectedTool = 'pen';

  final PdfViewerController _pdfViewerController = PdfViewerController();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  final TextEditingController _searchTextController = TextEditingController();
  bool _isSearchMode = false;
  String _currentSearchText = "";

  bool _isDrawingMode = false;
  Color _selectedPenColor = AppKendoColors.blue;
  bool get _isSharedPen =>
      _selectedPenColor == AppKendoColors.pink ||
      _selectedPenColor == _yellowPenColor;

  final ProgramViewerMediaCache _mediaCache = ProgramViewerMediaCache();

  @visibleForTesting
  Map<String, Future<Uint8List>> get sdkPdfBytesCacheForTesting =>
      _mediaCache.sdkPdfBytesCache;

  @visibleForTesting
  Future<Uint8List> getCachedPdfBytesViaSdk(String url) =>
      _mediaCache.getCachedPdfBytesViaSdk(url);

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
    _searchTextController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(permissionProvider);
    final currentRole = ref.watch(activeRoleProvider);
    final userRole = ref.watch(currentUserRoleProvider);

    final canUseSharedPen =
        !permissions.isReadOnly &&
        userRole != UserRole.viewer &&
        (currentRole == Role.admin ||
            currentRole == Role.scorer ||
            currentRole == Role.editor);

    final activePenColor = (!canUseSharedPen && _isSharedPen)
        ? AppKendoColors.blue
        : _selectedPenColor;
    final activeIsShared =
        canUseSharedPen &&
        (activePenColor == AppKendoColors.pink ||
            activePenColor == _yellowPenColor);

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
              : Builder(
                  builder: (context) {
                    final int totalPdfPages =
                        _pdfPageCounts[currentProgram.fileUrl] ?? 1;
                    final int curPdfPage =
                        _pdfCurrentPages[currentProgram.fileUrl] ?? 1;
                    final String pageSuffix = isFilePdf && totalPdfPages > 1
                        ? ' - $curPdfPage/$totalPdfPages 頁'
                        : '';
                    return Text(
                      '${currentProgram.title} (${safeIndex + 1}/${displayPrograms.length})$pageSuffix',
                      style: const TextStyle(
                        fontWeight: AppFontWeight.bold,
                        fontSize: AppFontSize.subhead,
                      ),
                    );
                  },
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
                    ref
                        .read(strokeRepositoryProvider)
                        .undoLastStroke(programId);
                  } else {
                    ref
                        .read(localStrokeRepositoryProvider)
                        .undoLastStroke(programId);
                  }
                },
                onClearAll: () {
                  if (activeIsShared) {
                    ref.read(strokeRepositoryProvider).clearStrokes(programId);
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
                  final itemProgramId = program.id.isNotEmpty
                      ? program.id
                      : program.fileUrl;

                  Widget buildCanvas({
                    required double penWidth,
                    int? pageIndex,
                  }) {
                    return ProgramViewerCanvasOverlay(
                      programId: itemProgramId,
                      pageIndex: isFilePdf ? (pageIndex ?? 0) : _currentIndex,
                      penWidth: penWidth,
                      isDrawingMode: _isDrawingMode,
                      selectedTool: _selectedTool,
                      activePenColor: activePenColor,
                      activeIsShared: activeIsShared,
                      canUseSharedPen: canUseSharedPen,
                    );
                  }

                  final Widget childWidget = isFilePdf
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
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _pdfPageCounts[program.fileUrl] = count;
                                  });
                                }
                              });
                            }
                          },
                          buildPageOverlay: (pIndex) =>
                              buildCanvas(penWidth: 10.0, pageIndex: pIndex),
                          isDrawingMode: _isDrawingMode,
                          isZoomed: _isZoomed,
                          initialPage:
                              (_pdfCurrentPages[program.fileUrl] ?? 1) - 1,
                          onPageChanged: (pIndex) {
                            if (mounted) {
                              setState(() {
                                _pdfCurrentPages[program.fileUrl] = pIndex + 1;
                              });
                            }
                          },
                        )
                      : ProgramViewerImageBody(
                          program: program,
                          imageSizeFuture: _mediaCache.getCachedImageSize(
                            program.fileUrl,
                          ),
                          safeUrl: _mediaCache.getSafeUrl(program.fileUrl),
                          isSearchMode: _isSearchMode,
                          currentSearchText: _currentSearchText,
                          buildOverlayLayers: (w) => buildCanvas(penWidth: w),
                        );

                  return InteractiveViewer(
                    transformationController: _transformationController,
                    panEnabled: !_isDrawingMode,
                    scaleEnabled: !_isDrawingMode,
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: Center(child: childWidget),
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
