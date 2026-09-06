import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/pdf/pdf_service.dart' deferred as pdf_service;
import 'package:kendo_os/shared/application/services/csv_service.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 公式記録画面のエクスポート（PDF印刷 / 画像シェア / CSV）ヘルパー
class OfficialRecordExportHelper {
  static Future<void> handleExport({
    required BuildContext context,
    required WidgetRef ref,
    required StateController<bool> isExportingController,
    StateController<String?>? exportingTypeController,
    required List<String> sortedGroupKeys,
    required Map<String, List<MatchModel>> mergedGroups,
    required String cat,
    required String type,
    String? tName,
    String? tDate,
    String? tVenue,
    bool isBottomSheet = false,
  }) async {
    if (isExportingController.state) return;
    isExportingController.state = true;
    exportingTypeController?.state = type;

    final groupDataList = sortedGroupKeys
        .map(
          (key) => {
            'groupName': key,
            'matches': mergedGroups[key]!
              ..sort((a, b) => a.order.compareTo(b.order)),
          },
        )
        .toList();

    BuildContext? dialogContext;
    // ボトムシート内では最前面Overlay背後にダイアログが潜るのを防ぐため、ボタン内プログレスで表現
    if (!isBottomSheet) {
      showAppDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext = ctx;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    try {
      final now = ref.read(timeSourceProvider).now();
      if (type == 'pdf') {
        await pdf_service.loadLibrary();
        await pdf_service.PdfService.printOfficialRecord(
          cat,
          groupDataList,
          tournamentName: tName,
          tournamentDate: tDate,
          tournamentVenue: tVenue,
          outputTime: now,
        );
      } else if (type == 'image') {
        await pdf_service.loadLibrary();
        await pdf_service.PdfService.shareOfficialRecordAsImage(
          cat,
          groupDataList,
          tournamentName: tName,
          tournamentDate: tDate,
          tournamentVenue: tVenue,
          outputTime: now,
        );
      } else if (type == 'csv') {
        await CsvService.shareOfficialRecordAsCsv(cat, groupDataList);
      }

      if (context.mounted) {
        final label = type == 'pdf' ? 'PDF' : (type == 'image' ? '画像' : 'CSV');
        AppSnackBar.showSuccess(context, '公式記録（$label）を出力しました');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, '出力に失敗しました: $e');
      }
    } finally {
      isExportingController.state = false;
      exportingTypeController?.state = null;
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      } else if (!isBottomSheet && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }
}
