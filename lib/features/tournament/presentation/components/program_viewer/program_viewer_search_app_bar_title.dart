import 'package:flutter/material.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart'
    hide StrokeModel;
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// 📖 プログラムビューア AppBar タイトル領域（検索入力 ⇄ 通常タイトル）
class ProgramViewerSearchAppBarTitle extends StatelessWidget {
  final bool isSearchMode;
  final bool isFilePdf;
  final ProgramModel currentProgram;
  final int safeIndex;
  final int totalPrograms;
  final Map<String, int> pdfPageCounts;
  final Map<String, int> pdfCurrentPages;
  final TextEditingController searchTextController;
  final PdfViewerController pdfViewerController;
  final ValueChanged<String> onSearchSubmitted;
  final ValueChanged<PdfTextSearchResult> onPdfSearchResult;
  final ValueChanged<int>? onProgramChanged;

  const ProgramViewerSearchAppBarTitle({
    super.key,
    required this.isSearchMode,
    required this.isFilePdf,
    required this.currentProgram,
    required this.safeIndex,
    required this.totalPrograms,
    required this.pdfPageCounts,
    required this.pdfCurrentPages,
    required this.searchTextController,
    required this.pdfViewerController,
    required this.onSearchSubmitted,
    required this.onPdfSearchResult,
    this.onProgramChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearchMode) {
      return AppTextField(
        controller: searchTextController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '選手名・団体名を検索...',
          border: InputBorder.none,
        ),
        onSubmitted: (value) async {
          onSearchSubmitted(value);
          if (value.isEmpty) {
            return;
          }
          if (isFilePdf) {
            final result = pdfViewerController.searchText(value);
            onPdfSearchResult(result);
          } else {
            if (!(currentProgram.isOcrProcessed ?? false)) {
              AppSnackBar.show(context, '現在クラウドで解析中です。しばらくお待ちください。');
            } else if (currentProgram.ocrWords == null ||
                currentProgram.ocrWords!.isEmpty) {
              AppSnackBar.show(context, 'この画像から文字が検出されませんでした。');
            }
          }
        },
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final int loadedCount =
        pdfPageCounts[currentProgram.fileUrl] ?? currentProgram.pageCount;
    final int totalPdfPages = loadedCount >= currentProgram.pageCount
        ? loadedCount
        : currentProgram.pageCount;
    final int curPdfPage =
        pdfCurrentPages[currentProgram.id.isNotEmpty
            ? currentProgram.id
            : currentProgram.fileUrl] ??
        pdfCurrentPages[currentProgram.fileUrl] ??
        1;
    final String pageSuffix = isFilePdf && totalPdfPages > 1
        ? ' - $curPdfPage/$totalPdfPages 頁'
        : '';

    final titleWidget = Text(
      '${currentProgram.title} (${safeIndex + 1}/$totalPrograms)$pageSuffix',
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: AppFontWeight.bold,
        fontSize: AppFontSize.subhead,
        color: themeColors.textColor,
      ),
    );

    if (totalPrograms <= 1) {
      return titleWidget;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: themeColors.inputBackground,
        borderRadius: AppRadius.capsule,
        border: Border.all(color: themeColors.subtleBorderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: '前のプログラム',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: AppRadius.capsule,
                onTap: safeIndex > 0
                    ? () => onProgramChanged?.call(safeIndex - 1)
                    : null,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: safeIndex > 0
                        ? themeColors.textColor.withAlpha(20)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 20,
                    color: safeIndex > 0
                        ? themeColors.textColor
                        : themeColors.disabledColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              child: titleWidget,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Tooltip(
            message: '次のプログラム',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: AppRadius.capsule,
                onTap: safeIndex < totalPrograms - 1
                    ? () => onProgramChanged?.call(safeIndex + 1)
                    : null,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: safeIndex < totalPrograms - 1
                        ? themeColors.textColor.withAlpha(20)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: safeIndex < totalPrograms - 1
                        ? themeColors.textColor
                        : themeColors.disabledColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
