import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/pdf/pdf_service.dart' deferred as pdf_service;
import 'package:kendo_os/features/tournament/domain/services/bunaiksen_helper.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 部内戦公式記録のエクスポート（PDF印刷 / 画像シェア）ヘルパー
class BunaiksenRecordExportHelper {
  /// 個人戦ID形式のグループを1つに統合する
  static Map<String, List<MatchModel>> mergeIndividualGroups(
    Map<String, List<MatchModel>> groupsMap,
  ) {
    final mergedGroups = <String, List<MatchModel>>{};
    final List<MatchModel> individualMergedList = [];
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    groupsMap.forEach((key, matches) {
      final isIndiv = matches.any(
        (m) =>
            m.matchType == 'individual' ||
            m.matchType == '選手' ||
            m.matchType.contains('個人戦'),
      );
      final isLeague = BunaiksenHelper.isLeagueMatches(matches);

      if (isIndiv &&
          !isLeague &&
          (uuidRegex.hasMatch(key) || key.length > 20)) {
        individualMergedList.addAll(matches);
      } else {
        mergedGroups[key] = matches;
      }
    });

    if (individualMergedList.isNotEmpty) {
      individualMergedList.sort((a, b) => a.order.compareTo(b.order));
      mergedGroups['__merged_individual__'] = individualMergedList;
    }

    return mergedGroups;
  }

  /// グループ別試合マップから公式記録用グループデータリストを生成する
  static List<Map<String, dynamic>> buildGroupDataList(
    Map<String, List<MatchModel>> mergedGroups,
  ) {
    final sortedGroupKeys = mergedGroups.keys.toList()..sort();
    return sortedGroupKeys
        .map(
          (key) => {
            'groupName': key,
            'matches': mergedGroups[key]!
              ..sort((a, b) => a.order.compareTo(b.order)),
          },
        )
        .toList();
  }

  /// 全カテゴリ（全試合形式）の公式記録データを生成する
  static List<({String categoryName, List<Map<String, dynamic>> groupDataList})>
  buildAllCategoryData(
    Map<String, Map<String, List<MatchModel>>> categoryGroups,
  ) {
    return categoryGroups.entries.map((entry) {
      final mergedGroups = mergeIndividualGroups(entry.value);
      return (
        categoryName: entry.key,
        groupDataList: buildGroupDataList(mergedGroups),
      );
    }).toList();
  }

  static Future<void> handleExport({
    required BuildContext context,
    required WidgetRef ref,
    required StateController<bool> isExportingController,
    required String cat,
    required Map<String, List<MatchModel>> groupsMap,
    required List<String> sortedGroupKeys,
    required bool isPdf,
    String? tName,
    String? tDate,
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
          cat,
          groupDataList,
          tournamentName: tName,
          tournamentDate: tDate,
          outputTime: now,
        );
      } else {
        await pdf_service.PdfService.shareOfficialRecordAsImage(
          cat,
          groupDataList,
          tournamentName: tName,
          tournamentDate: tDate,
          outputTime: now,
        );
      }
      if (context.mounted) {
        final label = isPdf ? 'PDF' : '画像';
        AppSnackBar.showSuccess(context, '公式記録（$label）を出力しました');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, '出力に失敗しました: $e');
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

  /// 全カテゴリ一括エクスポート
  static Future<void> handleExportAll({
    required BuildContext context,
    required WidgetRef ref,
    required StateController<bool> isExportingController,
    required List<
      ({String categoryName, List<Map<String, dynamic>> groupDataList})
    >
    allCategoryData,
    required bool isPdf,
    String? tName,
    String? tDate,
  }) async {
    if (isExportingController.state) return;
    isExportingController.state = true;

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
        await pdf_service.PdfService.printOfficialRecordAll(
          allCategoryData,
          tournamentName: tName,
          tournamentDate: tDate,
          outputTime: now,
        );
      } else {
        await pdf_service.PdfService.shareOfficialRecordAllAsImage(
          allCategoryData,
          tournamentName: tName,
          tournamentDate: tDate,
          outputTime: now,
        );
      }
      if (context.mounted) {
        final label = isPdf ? 'PDF' : '画像';
        AppSnackBar.showSuccess(context, '全試合形式の公式記録（$label）を出力しました');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, '出力に失敗しました: $e');
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
