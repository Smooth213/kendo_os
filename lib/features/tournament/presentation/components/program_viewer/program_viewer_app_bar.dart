import 'package:flutter/material.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart'
    hide StrokeModel;
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'program_viewer_search_app_bar_title.dart';

/// 📖 プログラムビューア用 AppBar（検索・OCR・手書きトグル統合）
class ProgramViewerAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final bool isDark;
  final bool isDrawingMode;
  final bool isSearchMode;
  final bool isFilePdf;
  final ProgramModel currentProgram;
  final int safeIndex;
  final int totalPrograms;
  final Map<String, int> pdfPageCounts;
  final Map<String, int> pdfCurrentPages;
  final TextEditingController searchTextController;
  final PdfViewerController pdfViewerController;
  final PdfTextSearchResult searchResult;
  final Color activePenColor;
  final ValueChanged<String> onSearchSubmitted;
  final ValueChanged<PdfTextSearchResult> onPdfSearchResult;
  final VoidCallback onCloseSearch;
  final VoidCallback onOpenSearch;
  final VoidCallback onToggleDrawingMode;

  const ProgramViewerAppBar({
    super.key,
    required this.isDark,
    required this.isDrawingMode,
    required this.isSearchMode,
    required this.isFilePdf,
    required this.currentProgram,
    required this.safeIndex,
    required this.totalPrograms,
    required this.pdfPageCounts,
    required this.pdfCurrentPages,
    required this.searchTextController,
    required this.pdfViewerController,
    required this.searchResult,
    required this.activePenColor,
    required this.onSearchSubmitted,
    required this.onPdfSearchResult,
    required this.onCloseSearch,
    required this.onOpenSearch,
    required this.onToggleDrawingMode,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppHeader(
      backgroundColor: isDark
          ? const Color(0xFF1C1C1E)
          : context.appColors.cardBackground,
      foregroundColor: context.appColors.textColor,
      elevation: isDrawingMode ? 0 : 1,
      titleWidget: ProgramViewerSearchAppBarTitle(
        isSearchMode: isSearchMode,
        isFilePdf: isFilePdf,
        currentProgram: currentProgram,
        safeIndex: safeIndex,
        totalPrograms: totalPrograms,
        pdfPageCounts: pdfPageCounts,
        pdfCurrentPages: pdfCurrentPages,
        searchTextController: searchTextController,
        pdfViewerController: pdfViewerController,
        onSearchSubmitted: onSearchSubmitted,
        onPdfSearchResult: onPdfSearchResult,
      ),
      actions: [
        if (isSearchMode) ...[
          if (isFilePdf) ...[
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: () => searchResult.previousInstance(),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => searchResult.nextInstance(),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: '検索を終了',
            onPressed: onCloseSearch,
          ),
        ],
        if (!isSearchMode) ...[
          if (!isFilePdf)
            Tooltip(
              message: (currentProgram.isOcrProcessed ?? false)
                  ? '文字検索の準備完了'
                  : '画像解析の準備中',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Icon(
                  Icons.bolt,
                  color: (currentProgram.isOcrProcessed ?? false)
                      ? AppKendoColors.amber
                      : const Color(0xFFBDBDBD),
                  size: 20,
                ),
              ),
            ),
          IconButton(icon: const Icon(Icons.search), onPressed: onOpenSearch),
        ],
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: MediaQuery.of(context).size.width < 600 || isSearchMode
              ? IconButton(
                  onPressed: onToggleDrawingMode,
                  icon: Icon(isDrawingMode ? Icons.check : Icons.edit),
                  color: isDrawingMode
                      ? activePenColor
                      : (context.appColors.textColor),
                  tooltip: isDrawingMode ? '完了' : '書き込む',
                )
              : ElevatedButton.icon(
                  onPressed: onToggleDrawingMode,
                  icon: Icon(
                    isDrawingMode ? Icons.check : Icons.edit,
                    size: 18,
                  ),
                  label: Text(isDrawingMode ? '完了' : '書き込む'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDrawingMode
                        ? activePenColor
                        : (context.appColors.separatorColor),
                    foregroundColor: isDrawingMode
                        ? AppKendoColors.pureWhite
                        : (context.appColors.textColor),
                    elevation: 0,
                  ),
                ),
        ),
      ],
    );
  }
}
