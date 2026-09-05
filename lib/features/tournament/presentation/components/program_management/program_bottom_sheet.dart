import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/program_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../program_viewer/program_viewer_media_cache.dart';
import 'program_stroke_layer.dart';

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
  final ProgramViewerMediaCache _mediaCache = ProgramViewerMediaCache();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final programAsync = ref.watch(programListProvider(widget.tournamentId));

    return DockDraggableSheet(
      backgroundColor: isDark
          ? const Color(0xFF1E1E20)
          : themeColors.cardBackground,
      builder: (context, scrollController) {
        return Column(
          children: [
            // 統一ヘッダー
            _buildHeader(context, themeColors, isDark),
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
                    return _buildEmptyState(context, themeColors);
                  }
                  if (_currentIndex >= programs.length) {
                    _currentIndex = 0;
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
          tooltip: 'ペンでメモを記入',
          onPressed: () {
            final programs = ref
                .read(programListProvider(widget.tournamentId))
                .valueOrNull;
            if (programs != null && programs.isNotEmpty) {
              Navigator.pop(context);
              context.push(
                widget.isViewerMode
                    ? '/program-viewer?role=viewer'
                    : '/program-viewer',
                extra: {
                  'programs': programs,
                  'index': _currentIndex,
                  'initialDrawingMode': true,
                },
              );
            }
          },
        ),
      ],
      onFullScreen: () {
        final programs = ref
            .read(programListProvider(widget.tournamentId))
            .valueOrNull;
        if (programs != null && programs.isNotEmpty) {
          Navigator.pop(context);
          context.push(
            widget.isViewerMode
                ? '/program-viewer?role=viewer'
                : '/program-viewer',
            extra: {'programs': programs, 'index': _currentIndex},
          );
        }
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
            onSelected: (_) => setState(() => _currentIndex = idx),
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
      const double canvasWidth = 1000.0;
      const double canvasHeight = 1414.0;

      return ClipRRect(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: canvasWidth,
                height: canvasHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: kIsWeb
                            ? FutureBuilder<Uint8List>(
                                future: _mediaCache.getCachedPdfBytesViaSdk(
                                  program.fileUrl,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text(
                                        'PDFロード失敗: ${snapshot.error}',
                                        style: const TextStyle(
                                          color: AppKendoColors.redAccent,
                                        ),
                                      ),
                                    );
                                  }
                                  if (!snapshot.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: AppKendoColors.ipponGold,
                                      ),
                                    );
                                  }
                                  return SfPdfViewer.memory(
                                    snapshot.data!,
                                    key: ValueKey(program.fileUrl),
                                    initialPageNumber: 1,
                                    pageLayoutMode: PdfPageLayoutMode.single,
                                    canShowScrollHead: false,
                                    canShowScrollStatus: false,
                                    canShowPaginationDialog: false,
                                    enableDoubleTapZooming: false,
                                    enableTextSelection: false,
                                  );
                                },
                              )
                            : SfPdfViewer.network(
                                program.fileUrl,
                                key: ValueKey(program.fileUrl),
                                initialPageNumber: 1,
                                pageLayoutMode: PdfPageLayoutMode.single,
                                canShowScrollHead: false,
                                canShowScrollStatus: false,
                                canShowPaginationDialog: false,
                                enableDoubleTapZooming: false,
                                enableTextSelection: false,
                              ),
                      ),
                    ),
                    Positioned.fill(
                      child: ProgramStrokeLayer(
                        programId: itemProgramId,
                        pageIndex: 0,
                        penWidth: 10.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      child: InteractiveViewer(
        minScale: 0.8,
        maxScale: 4.0,
        child: Center(
          child: FutureBuilder<Size>(
            future: _mediaCache.getCachedImageSize(program.fileUrl),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppKendoColors.ipponGold,
                  ),
                );
              }
              final imgSize = snapshot.data!;
              const double maxDimension = 2048.0;
              final bool isTooLarge =
                  imgSize.width > maxDimension || imgSize.height > maxDimension;
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
              final double imagePenWidth = (displaySize.width * 0.005).clamp(
                8.0,
                50.0,
              );

              return FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: displaySize.width,
                  height: displaySize.height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: program.fileUrl.contains('example.com')
                            ? Container(
                                color: themeColors.cardBackground,
                                child: Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 64,
                                    color: themeColors.primaryAccent,
                                  ),
                                ),
                              )
                            : Image.network(
                                _mediaCache.getSafeUrl(program.fileUrl),
                                fit: BoxFit.fill,
                                errorBuilder: (context, _, _) => Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.broken_image,
                                        size: 48,
                                        color: AppKendoColors.grey,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        '画像を読み込めませんでした',
                                        style: TextStyle(
                                          color: themeColors.subTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      Positioned.fill(
                        child: ProgramStrokeLayer(
                          programId: itemProgramId,
                          pageIndex: _currentIndex,
                          penWidth: imagePenWidth,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppThemeColors themeColors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 56,
            color: themeColors.subTextColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.isViewerMode
                ? '大会プログラムはまだ登録されていません'
                : 'プログラム（進行表・トーナメント表）を登録してください',
            style: TextStyle(
              color: themeColors.subTextColor,
              fontSize: AppFontSize.body,
            ),
          ),
          if (!widget.isViewerMode) ...[
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('プログラムを追加する'),
              onPressed: () {
                Navigator.pop(context);
                context.push('/tournament/${widget.tournamentId}/programs');
              },
            ),
          ],
        ],
      ),
    );
  }
}
