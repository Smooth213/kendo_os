import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/pdf/pdf_service.dart' deferred as pdf_service;
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 🥋 観客用 部内戦公式記録 エクスポートサービス
class ViewerBunaiksenExportService {
  const ViewerBunaiksenExportService();

  Future<void> exportOfficialRecord({
    required BuildContext context,
    required WidgetRef ref,
    required String category,
    required Map<String, List<MatchModel>> groupsMap,
    required List<String> sortedGroupKeys,
    required bool isPdf,
    required StateController<bool> isExportingController,
    String? tournamentName,
    String? tournamentDate,
  }) async {
    if (isExportingController.state) return;
    isExportingController.state = true;

    final groupDataList = sortedGroupKeys
        .map(
          (key) => {
            'groupName': key,
            'matches': groupsMap[key]!
              ..sort((a, b) => a.order.compareTo(b.order)),
          },
        )
        .toList();

    BuildContext? dialogContext;
    showAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final now = ref.read(timeSourceProvider).now();
      await pdf_service.loadLibrary();
      if (isPdf) {
        await pdf_service.PdfService.printOfficialRecord(
          category,
          groupDataList,
          tournamentName: tournamentName,
          tournamentDate: tournamentDate,
          outputTime: now,
        );
      } else {
        await pdf_service.PdfService.shareOfficialRecordAsImage(
          category,
          groupDataList,
          tournamentName: tournamentName,
          tournamentDate: tournamentDate,
          outputTime: now,
        );
      }
    } finally {
      isExportingController.state = false;
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      } else if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }
}
