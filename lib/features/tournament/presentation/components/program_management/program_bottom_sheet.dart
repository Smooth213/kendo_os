import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/program_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_sheet_empty_state.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_sheet_image_viewer.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_sheet_pagination_bar.dart';
import 'package:kendo_os/shared/routing/app_router.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../program_viewer/program_viewer_media_cache.dart';
import '../program_viewer/program_viewer_pdf_body.dart';
import 'program_stroke_layer.dart';
import 'program_view_state_service.dart';

/// 🥋 大会プログラム 2画面クイック確認シート（ボトムシート＆サイドパネル両対応）
class ProgramBottomSheet extends ConsumerStatefulWidget {
  final String tournamentId;
  final bool isViewerMode;
  final int initialIndex;

  const ProgramBottomSheet({
    super.key,
    required this.tournamentId,
    this.isViewerMode = false,
    this.initialIndex = 0,
  });

  /// ボトムシートを表示するエントリーポイント
  static Future<void> show(
    BuildContext context, {
    required String tournamentId,
    bool isViewerMode = false,
    int initialIndex = 0,
  }) {
    return showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: AppKendoColors.transparent,
      builder: (ctx) => ProgramBottomSheet(
        tournamentId: tournamentId,
        isViewerMode: isViewerMode,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  ConsumerState<ProgramBottomSheet> createState() => _ProgramBottomSheetState();
}

class _ProgramBottomSheetState extends ConsumerState<ProgramBottomSheet> {
  late int _currentIndex;
  final ProgramViewerMediaCache _mediaCache = ProgramViewerMediaCache.shared;
  late PdfViewerController _pdfController;
  final TransformationController _transformationController =
      TransformationController();
  int _pageNumber = 1;
  int _pageCount = 0;
  bool _hasRestoredInitialPage = false;
  bool _isInitialPageRestorePending = false;
  String? _cachedPdfUrl;
  Future<Uint8List>? _cachedPdfBytesFuture;

  @override
  void initState() {
    super.initState();
    final savedIndex = ProgramViewStateService.instance.getLastProgramIndex(
      widget.tournamentId,
      defaultIndex: widget.initialIndex,
    );
    _currentIndex = savedIndex;
    _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pdfController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    }
  }

  Future<Uint8List> _getPdfBytes(String url) {
    if (_cachedPdfUrl == url && _cachedPdfBytesFuture != null) {
      return _cachedPdfBytesFuture!;
    }
    _cachedPdfUrl = url;
    _cachedPdfBytesFuture = _mediaCache.getCachedPdfBytesViaSdk(url);
    return _cachedPdfBytesFuture!;
  }

  void _openProgramViewer(
    BuildContext context,
    List<ProgramModel> programs, {
    required bool isDrawingMode,
  }) {
    AppHaptics.selection();
    FloatingDockSheetManager.close(immediate: true);
    if (programs.isNotEmpty && _currentIndex < programs.length) {
      final cur = programs[_currentIndex];
      final itemKey = cur.id.isNotEmpty ? cur.id : cur.fileUrl;
      ProgramViewStateService.instance.setLastProgramIndex(
        widget.tournamentId,
        _currentIndex,
      );
      ProgramViewStateService.instance.setLastPageNumber(itemKey, _pageNumber);
    }
    appRouter.push(
      widget.isViewerMode ? '/program-viewer?role=viewer' : '/program-viewer',
      extra: {
        'programs': programs,
        'index': _currentIndex,
        'initialDrawingMode': isDrawingMode,
        'initialPage': _pageNumber,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final programAsync = ref.watch(programListProvider(widget.tournamentId));
    final currentPrograms = programAsync.valueOrNull;

    return DockDraggableSheet(
      backgroundColor: isDark
          ? const Color(0xFF1E1E20)
          : themeColors.cardBackground,
      builder: (context, scrollController) {
        return Column(
          children: [
            // 統一ヘッダー
            _buildHeader(context, themeColors, isDark, currentPrograms),
            // プログラムコンテンツ
            Expanded(
              child: programAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text(
                    'プログラム読み込みエラー: $err',
                    style: TextStyle(color: themeColors.subTextColor),
                  ),
                ),
                data: (programs) {
                  if (programs.isEmpty) {
                    return ProgramSheetEmptyState(
                      tournamentId: widget.tournamentId,
                      isViewerMode: widget.isViewerMode,
                      themeColors: themeColors,
                    );
                  }
                  if (_currentIndex >= programs.length || _currentIndex < 0) {
                    _currentIndex = 0;
                  }
                  if (!_hasRestoredInitialPage) {
                    _hasRestoredInitialPage = true;
                    final activeProg = programs[_currentIndex];
                    final itemKey = activeProg.id.isNotEmpty
                        ? activeProg.id
                        : activeProg.fileUrl;
                    final savedPage = ProgramViewStateService.instance
                        .getLastPageNumber(itemKey, defaultPage: 1);
                    _pageNumber = savedPage;
                    _isInitialPageRestorePending = savedPage > 1;
                  }
                  return Column(
                    children: [
                      if (programs.length > 1)
                        _buildProgramSelector(programs, themeColors, isDark),
                      Expanded(
                        child: _buildViewer(
                          programs[_currentIndex],
                          programs,
                          themeColors,
                          isDark,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppThemeColors themeColors,
    bool isDark,
    List<ProgramModel>? programs,
  ) {
    return DockBottomSheetHeader(
      title: '大会プログラム・進行表',
      icon: Icons.menu_book_rounded,
      iconColor: themeColors.primaryAccent,
      extraActions: [
        IconButton(
          icon: Icon(
            Icons.brush_rounded,
            size: 18,
            color: themeColors.primaryAccent,
          ),
          tooltip: 'ペンでメモを記入（全画面手書きモード）',
          onPressed: () {
            final activePrograms =
                programs ??
                ref
                    .read(programListProvider(widget.tournamentId))
                    .valueOrNull ??
                [];
            _openProgramViewer(context, activePrograms, isDrawingMode: true);
          },
        ),
      ],
      onFullScreen: () {
        final activePrograms =
            programs ??
            ref.read(programListProvider(widget.tournamentId)).valueOrNull ??
            [];
        _openProgramViewer(context, activePrograms, isDrawingMode: false);
      },
    );
  }

  Widget _buildProgramSelector(
    List<ProgramModel> programs,
    AppThemeColors themeColors,
    bool isDark,
  ) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: programs.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, idx) {
          final p = programs[idx];
          final isSelected = idx == _currentIndex;
          return AppFilterChip(
            selected: isSelected,
            label: Text(
              p.title,
              style: TextStyle(
                fontSize: AppFontSize.small,
                fontWeight: isSelected
                    ? AppFontWeight.bold
                    : AppFontWeight.medium,
                color: isSelected
                    ? (isDark
                          ? AppKendoColors.pureWhite
                          : themeColors.primaryAccent)
                    : themeColors.textColor,
              ),
            ),
            onSelected: (_) {
              _resetZoom();
              final newProg = programs[idx];
              final itemKey = newProg.id.isNotEmpty
                  ? newProg.id
                  : newProg.fileUrl;
              final savedPage = ProgramViewStateService.instance
                  .getLastPageNumber(itemKey, defaultPage: 1);
              setState(() {
                _currentIndex = idx;
                _pageNumber = savedPage;
                _isInitialPageRestorePending = savedPage > 1;
              });
              ProgramViewStateService.instance.setLastProgramIndex(
                widget.tournamentId,
                idx,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildViewer(
    ProgramModel program,
    List<ProgramModel> allPrograms,
    AppThemeColors themeColors,
    bool isDark,
  ) {
    final itemProgramId = program.id.isNotEmpty ? program.id : program.fileUrl;

    if (program.fileType == 'pdf') {
      final effectivePageCount = _pageCount > 0
          ? _pageCount
          : (program.pageCount >= _pageNumber
                ? program.pageCount
                : _pageNumber);

      return Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            child: GestureDetector(
              onDoubleTap: _resetZoom,
              child: InteractiveViewer(
                key: ValueKey('sheet_iv_${program.id}_$_currentIndex'),
                transformationController: _transformationController,
                alignment: Alignment.center,
                minScale: 1.0,
                maxScale: 6.0,
                boundaryMargin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.giant * 4,
                  vertical: AppSpacing.giant * 6,
                ),
                onInteractionEnd: (_) {
                  final double currentScale = _transformationController.value
                      .getMaxScaleOnAxis();
                  if (currentScale <= 1.05) {
                    _resetZoom();
                  }
                },
                child: Center(
                  child: ProgramViewerPdfBody(
                    program: program,
                    pageCount: effectivePageCount,
                    pdfViewerController: _pdfController,
                    sdkPdfBytesFuture: _getPdfBytes(program.fileUrl),
                    onPageCountLoaded: (count) {
                      if (_pageCount != count) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _pageCount != count) {
                            setState(() => _pageCount = count);
                          }
                        });
                      }
                    },
                    buildPageOverlay: (pIndex) => ProgramStrokeLayer(
                      programId: itemProgramId,
                      pageIndex: pIndex,
                      penWidth: 10.0,
                    ),
                    initialPage: _pageNumber - 1,
                    onPageChanged: (pIndex) {
                      final newPage = pIndex + 1;
                      if (_isInitialPageRestorePending &&
                          newPage == 1 &&
                          _pageNumber > 1) {
                        // 🛡️ 初期レイアウト時の一時的な0発火による保存値破壊を防止
                        return;
                      }
                      _isInitialPageRestorePending = false;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _pageNumber != newPage) {
                          setState(() => _pageNumber = newPage);
                        }
                      });
                      ProgramViewStateService.instance.setLastPageNumber(
                        itemProgramId,
                        newPage,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          // 📄 複数ページPDF対応のページ送りナビゲーションバー
          Positioned(
            bottom: AppSpacing.sm,
            child: ProgramSheetPaginationBar(
              currentPage: _pageNumber,
              pageCount: effectivePageCount,
              themeColors: themeColors,
              isDark: isDark,
              onPageChanged: (newPage) {
                if (mounted && newPage >= 1 && newPage <= effectivePageCount) {
                  setState(() => _pageNumber = newPage);
                  ProgramViewStateService.instance.setLastPageNumber(
                    itemProgramId,
                    newPage,
                  );
                }
              },
            ),
          ),
        ],
      );
    }

    return ProgramSheetImageViewer(
      program: program,
      programId: itemProgramId,
      pageIndex: _currentIndex,
      themeColors: themeColors,
      mediaCache: _mediaCache,
    );
  }
}
