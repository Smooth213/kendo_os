import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/pdf/pdf_service.dart' deferred as pdf_service;
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/application/projections/tournament_projection.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

final isViewerExportingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

/// 🥋 観客席 公式記録画面の PDF印刷・画像シェア 操作バー
class ViewerOfficialRecordExportBar extends ConsumerWidget {
  final String category;
  final List<String> sortedGroupKeys;
  final TournamentProjection proj;
  final String? tournamentName;
  final String? tournamentDate;
  final String? tournamentVenue;

  const ViewerOfficialRecordExportBar({
    super.key,
    required this.category,
    required this.sortedGroupKeys,
    required this.proj,
    this.tournamentName,
    this.tournamentDate,
    this.tournamentVenue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExporting = ref.watch(isViewerExportingProvider);
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(
          isDark: Theme.of(context).brightness == Brightness.dark,
          mode: 'normal',
        );
    final cardColor = themeColors.cardBackground;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          bottom: BorderSide(color: context.appColors.separatorColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              key: const Key('viewer_export_pdf_button'),
              onPressed: isExporting
                  ? null
                  : () async {
                      if (ref.read(isViewerExportingProvider)) {
                        return;
                      }
                      ref.read(isViewerExportingProvider.notifier).state = true;
                      final groupDataList = sortedGroupKeys.map((key) {
                        return {
                          'groupName': key,
                          'matches': List<MatchListProjection>.from(
                            proj.teamMatches[key]!.matches,
                          )..sort((a, b) => a.order.compareTo(b.order)),
                        };
                      }).toList();

                      BuildContext? dialogContext;
                      showAppDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) {
                          dialogContext = ctx;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      );

                      try {
                        final now = ref.read(timeSourceProvider).now();
                        await pdf_service.loadLibrary();
                        await pdf_service.PdfService.printOfficialRecord(
                          category,
                          groupDataList,
                          tournamentName: tournamentName,
                          tournamentDate: tournamentDate,
                          tournamentVenue: tournamentVenue,
                          outputTime: now,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          AppSnackBar.showError(context, '出力に失敗しました: $e');
                        }
                      } finally {
                        ref.read(isViewerExportingProvider.notifier).state =
                            false;
                        if (dialogContext != null && dialogContext!.mounted) {
                          Navigator.pop(dialogContext!);
                        } else if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }
                      }
                    },
              icon: const Icon(Icons.print),
              label: const Text(
                'PDF印刷',
                style: TextStyle(fontWeight: AppFontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appColors.errorColor,
                foregroundColor: AppKendoColors.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ElevatedButton.icon(
              key: const Key('viewer_export_image_button'),
              onPressed: () async {
                final groupDataList = sortedGroupKeys.map((key) {
                  return {
                    'groupName': key,
                    'matches': List<MatchListProjection>.from(
                      proj.teamMatches[key]!.matches,
                    )..sort((a, b) => a.order.compareTo(b.order)),
                  };
                }).toList();

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
                  await pdf_service.PdfService.shareOfficialRecordAsImage(
                    category,
                    groupDataList,
                    tournamentName: tournamentName,
                    tournamentDate: tournamentDate,
                    tournamentVenue: tournamentVenue,
                    outputTime: now,
                  );
                } catch (e) {
                  if (context.mounted) {
                    AppSnackBar.showError(context, '出力に失敗しました: $e');
                  }
                } finally {
                  if (dialogContext != null && dialogContext!.mounted) {
                    Navigator.pop(dialogContext!);
                  } else if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                }
              },
              icon: const Icon(Icons.share),
              label: const Text(
                '画像シェア',
                style: TextStyle(fontWeight: AppFontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06C755),
                foregroundColor: AppKendoColors.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
