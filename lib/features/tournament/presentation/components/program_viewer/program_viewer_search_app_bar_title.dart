import 'package:flutter/material.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart'
    hide StrokeModel;
import 'package:kendo_os/shared/theme/app_tokens.dart';
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

    final int totalPdfPages = pdfPageCounts[currentProgram.fileUrl] ?? 1;
    final int curPdfPage = pdfCurrentPages[currentProgram.fileUrl] ?? 1;
    final String pageSuffix = isFilePdf && totalPdfPages > 1
        ? ' - $curPdfPage/$totalPdfPages 頁'
        : '';

    return Text(
      '${currentProgram.title} (${safeIndex + 1}/$totalPrograms)$pageSuffix',
      style: const TextStyle(
        fontWeight: AppFontWeight.bold,
        fontSize: AppFontSize.subhead,
      ),
    );
  }
}
