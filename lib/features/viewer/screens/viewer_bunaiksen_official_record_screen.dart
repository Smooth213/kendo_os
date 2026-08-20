import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/presentation/providers/match_view_model_provider.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_category_content.dart';
import 'package:kendo_os/features/viewer/services/viewer_bunaiksen_export_service.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';

final isExportingProvider = StateProvider.autoDispose<bool>((ref) => false);

class ViewerBunaiksenOfficialRecordScreen extends ConsumerWidget {
  final String tournamentId;
  static const _exportService = ViewerBunaiksenExportService();

  const ViewerBunaiksenOfficialRecordScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExporting = ref.watch(isExportingProvider);
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;

    // tournamentId から日付をパース (例: bunaiksen_20241010)
    String dateDisplay = '部内戦';
    String tDate = '';
    if (tournamentId.startsWith('bunaiksen_') && tournamentId.length == 18) {
      final dateStr = tournamentId.substring(10);
      if (dateStr.length == 8) {
        dateDisplay =
            '${dateStr.substring(0, 4)}/${dateStr.substring(4, 6)}/${dateStr.substring(6, 8)}';
        tDate =
            '${dateStr.substring(0, 4)}年${dateStr.substring(4, 6)}月${dateStr.substring(6, 8)}日';
      }
    }

    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen_viewer');
    final cardColor = themeColors.cardBackground;
    final headerTextColor = isDark
        ? const Color(0xFFFFFFFF)
        : themeColors.primaryAccent;

    final categoryGroups = ref.watch(
      bunaiksenRecordCategoryGroupsProvider(tournamentId),
    );

    if (categoryGroups.isEmpty) {
      return LiquidBackground(
        child: Scaffold(
          backgroundColor: AppKendoColors.transparent,
          appBar: AppHeader(
            backgroundColor: enableLiquidGlass
                ? AppKendoColors.transparent
                : cardColor,
            foregroundColor: headerTextColor,
            title: '成績一覧 (観戦)',
            elevation: 0,
            centerTitle: true,
            leading: GoRouter.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => context.pop(),
                  )
                : null,
          ),
          body: const Center(
            child: Text(
              'この日の記録データはありません',
              style: TextStyle(color: AppKendoColors.grey),
            ),
          ),
        ),
      );
    }

    final categories = categoryGroups.keys.toList();

    return PopScope(
      canPop: false,
      child: DefaultTabController(
        length: categories.length,
        child: LiquidBackground(
          child: Scaffold(
            backgroundColor: AppKendoColors.transparent,
            appBar: AppHeader(
              backgroundColor: enableLiquidGlass
                  ? AppKendoColors.transparent
                  : cardColor,
              foregroundColor: headerTextColor,
              title: '$dateDisplay 成績 (観戦)',
              elevation: 0,
              centerTitle: true,
              leading: GoRouter.of(context).canPop()
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => context.pop(),
                    )
                  : null,
              bottom: TabBar(
                isScrollable: true,
                labelColor: headerTextColor,
                unselectedLabelColor: AppKendoColors.grey,
                indicatorColor: themeColors.primaryAccent,
                tabs: categories.map((cat) => Tab(text: cat)).toList(),
              ),
            ),
            body: TabBarView(
              children: categories.map((cat) {
                final groupsMap = categoryGroups[cat]!;
                return ViewerBunaiksenCategoryContent(
                  category: cat,
                  groupsMap: groupsMap,
                  cardColor: cardColor,
                  themeColors: themeColors,
                  isDark: isDark,
                  isExporting: isExporting,
                  isExportingController: ref.watch(
                    isExportingProvider.notifier,
                  ),
                  tDate: tDate,
                  exportService: _exportService,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
