import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_category_tab_view.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_export_bar.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_group_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

export 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_category_tab_view.dart'
    show isExportingProvider, exportingTypeProvider;
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:go_router/go_router.dart';
import '../components/program_management/floating_program_dock_button.dart';

class OfficialRecordScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final bool isBottomSheet;
  final VoidCallback? onFullScreen;

  const OfficialRecordScreen({
    super.key,
    required this.tournamentId,
    this.isBottomSheet = false,
    this.onFullScreen,
  });

  static Future<void> showAsBottomSheet(
    BuildContext context, {
    required String tournamentId,
    bool isViewerMode = false,
  }) {
    final isBunaiksen = tournamentId.startsWith('bunaiksen_');
    final String fullScreenRoute;
    if (isBunaiksen) {
      fullScreenRoute = isViewerMode
          ? '/bunaiksen-viewer-record/$tournamentId'
          : '/bunaiksen-record';
    } else {
      fullScreenRoute = isViewerMode
          ? '/viewer-record/$tournamentId'
          : '/official-record/$tournamentId';
    }

    return showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: AppKendoColors.transparent,
      builder: (context) => OfficialRecordScreen(
        tournamentId: tournamentId,
        isBottomSheet: true,
        onFullScreen: () {
          Navigator.of(context).pop();
          context.push(fullScreenRoute);
        },
      ),
    );
  }

  @override
  ConsumerState<OfficialRecordScreen> createState() =>
      _OfficialRecordScreenState();
}

class _OfficialRecordScreenState extends ConsumerState<OfficialRecordScreen> {
  OfficialRecordExportScope _exportScope = OfficialRecordExportScope.current;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentId = widget.tournamentId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExporting = ref.watch(isExportingProvider);

    final permissions = ref.watch(permissionProvider);
    final String screenTitle = permissions.isReadOnly ? '全試合スコア' : '大会 公式記録';

    final tournamentAsync = ref.watch(tournamentProvider(tournamentId));
    final tName = tournamentAsync.value?.name;
    final tDate = tournamentAsync.value != null
        ? DateFormat('yyyy年MM月dd日').format(tournamentAsync.value!.date)
        : null;
    final tVenue = tournamentAsync.value?.venue;

    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final cardColor = themeColors.cardBackground;
    final headerTextColor = isDark
        ? const Color(0xFFFFFFFF)
        : context.appColors.primaryAccent;

    final registeredTeamsAsync = ref.watch(
      registeredTeamsProvider(tournamentId),
    );
    final registeredTeams = registeredTeamsAsync.value ?? [];
    final registeredTeamNames = registeredTeams
        .map((t) => t.teamName.trim())
        .where((n) => n.isNotEmpty)
        .toSet();
    final registeredPlayerNames = registeredTeams
        .expand((t) => t.playerNames)
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toSet();

    final matchesForThisTournament = ref
        .watch(
          matchListProvider.select(
            (list) => ListEqualityWrapper<MatchModel>(
              list.where((m) => m.tournamentId == tournamentId).toList(),
            ),
          ),
        )
        .list;

    final categoryGroups = OfficialRecordGroupHelper.groupMatchesByCategory(
      matchesForThisTournament,
    );

    if (categoryGroups.isEmpty) {
      if (widget.isBottomSheet) {
        return DockDraggableSheet(
          backgroundColor: cardColor,
          builder: (context, scrollController) => Column(
            children: [
              DockBottomSheetHeader(
                title: screenTitle,
                icon: Icons.table_chart_rounded,
                iconColor: AppKendoColors.amber,
                onFullScreen: widget.onFullScreen,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '記録データがありません',
                    style: TextStyle(color: context.appColors.textColor),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return LiquidBackground(
        child: Scaffold(
          backgroundColor: AppKendoColors.transparent,
          appBar: AppHeader(
            title: screenTitle,
            backgroundColor: cardColor,
            actions: [
              ManualHelpButton(
                manualPath: 'docs/manuals/operator/official_record.md',
                color: headerTextColor,
              ),
            ],
          ),
          body: Center(
            child: Text(
              '記録データがありません',
              style: TextStyle(color: context.appColors.textColor),
            ),
          ),
        ),
      );
    }

    final categories = categoryGroups.keys.toList();
    final hasMultipleCategories = categories.length > 1;

    final allCategoryData = categories.map((cat) {
      final groupsMap = categoryGroups[cat]!;
      final mergedGroups = OfficialRecordGroupHelper.mergeIndividualGroups(
        groupsMap,
      );
      final sortedGroupKeys = mergedGroups.keys.toList()
        ..sort((a, b) {
          final aLast = _getLastTimestamp(mergedGroups[a]!);
          final bLast = _getLastTimestamp(mergedGroups[b]!);
          return aLast.compareTo(bLast);
        });

      final groupDataList = sortedGroupKeys
          .map(
            (key) => {
              'groupName': key,
              'matches': mergedGroups[key]!
                ..sort((a, b) => a.order.compareTo(b.order)),
            },
          )
          .toList();

      return (categoryName: cat, groupDataList: groupDataList);
    }).toList();

    final tabWidget = TabBar(
      isScrollable: true,
      labelColor: headerTextColor,
      unselectedLabelColor: isDark
          ? const Color(0xFFFFFFFF)
          : const Color(0x8A000000),
      indicatorColor: const Color(0xFF3F51B5),
      tabs: categories.map((cat) => Tab(text: cat)).toList(),
    );

    final tabViews = categories.map((cat) {
      final groupsMap = categoryGroups[cat]!;
      final mergedGroups = OfficialRecordGroupHelper.mergeIndividualGroups(
        groupsMap,
      );

      final sortedGroupKeys = mergedGroups.keys.toList()
        ..sort((a, b) {
          final aLast = _getLastTimestamp(mergedGroups[a]!);
          final bLast = _getLastTimestamp(mergedGroups[b]!);
          return aLast.compareTo(bLast);
        });

      final categoryMatches = matchesForThisTournament.where((m) {
        final cName = (m.category != null && m.category!.isNotEmpty)
            ? m.category!
            : '一般';
        return cName == cat;
      }).toList();

      final (
        categoryRegisteredTeamNames,
        categoryRegisteredPlayerNames,
      ) = OfficialRecordGroupHelper.resolveRegisteredNames(
        category: cat,
        categoryMatches: categoryMatches,
        registeredTeams: registeredTeams,
        allRegisteredTeamNames: registeredTeamNames,
        allRegisteredPlayerNames: registeredPlayerNames,
      );

      return OfficialRecordCategoryTabView(
        cat: cat,
        categoryMatches: categoryMatches,
        mergedGroups: mergedGroups,
        sortedGroupKeys: sortedGroupKeys,
        categoryRegisteredTeamNames: categoryRegisteredTeamNames,
        categoryRegisteredPlayerNames: categoryRegisteredPlayerNames,
        allCategoryData: allCategoryData,
        isExporting: isExporting,
        exportingType: ref.watch(exportingTypeProvider),
        isDark: isDark,
        cardColor: cardColor,
        hasMultipleCategories: hasMultipleCategories,
        exportScope: _exportScope,
        onScopeChanged: (newScope) => setState(() => _exportScope = newScope),
        tName: tName,
        tDate: tDate,
        tVenue: tVenue,
        isBottomSheet: widget.isBottomSheet,
        isReadOnly: permissions.isReadOnly,
        ref: ref,
        highlightQuery: _searchQuery,
      );
    }).toList();

    final searchTextField = AppTextField(
      controller: _searchController,
      autofocus: true,
      hintText: '選手名・チーム名を検索...',
      suffixIcon: _searchQuery.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.cancel, size: 18, color: themeColors.hintColor),
              tooltip: '入力をクリア',
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            )
          : null,
      onChanged: (val) => setState(() => _searchQuery = val.trim()),
    );

    final searchActions = [
      if (!_isSearching)
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: '選手・チームを検索',
          color: headerTextColor,
          onPressed: () => setState(() => _isSearching = true),
        )
      else
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: '検索終了',
          color: headerTextColor,
          onPressed: () {
            _searchController.clear();
            setState(() {
              _isSearching = false;
              _searchQuery = '';
            });
          },
        ),
      if (!_isSearching)
        ManualHelpButton(
          manualPath: 'docs/manuals/operator/official_record.md',
          color: headerTextColor,
        ),
    ];

    return DefaultTabController(
      length: categories.length,
      child: widget.isBottomSheet
          ? DockDraggableSheet(
              backgroundColor: cardColor,
              builder: (context, scrollController) => Column(
                children: [
                  DockBottomSheetHeader(
                    title: screenTitle,
                    icon: Icons.table_chart_rounded,
                    iconColor: AppKendoColors.amber,
                    onFullScreen: widget.onFullScreen,
                    extraActions: [
                      IconButton(
                        icon: Icon(
                          _isSearching ? Icons.close : Icons.search,
                          size: 20,
                          color: headerTextColor,
                        ),
                        onPressed: () {
                          if (_isSearching) {
                            _searchController.clear();
                            setState(() {
                              _isSearching = false;
                              _searchQuery = '';
                            });
                          } else {
                            setState(() => _isSearching = true);
                          }
                        },
                      ),
                    ],
                  ),
                  if (_isSearching)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: themeColors.inputBackground,
                          borderRadius: AppRadius.medium,
                          border: Border.all(
                            color: AppKendoColors.amber,
                            width: 1,
                          ),
                        ),
                        child: searchTextField,
                      ),
                    ),
                  tabWidget,
                  Expanded(child: TabBarView(children: tabViews)),
                ],
              ),
            )
          : LiquidBackground(
              child: Scaffold(
                backgroundColor: AppKendoColors.transparent,
                appBar: AppHeader(
                  title: _isSearching ? null : screenTitle,
                  titleWidget: _isSearching ? searchTextField : null,
                  backgroundColor: cardColor,
                  actions: searchActions,
                  bottom: tabWidget,
                ),
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    TabBarView(children: tabViews),
                    FloatingProgramDockButton(
                      tournamentId: tournamentId,
                      isViewerMode: permissions.isReadOnly,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  DateTime _getLastTimestamp(List<MatchModel> ms) {
    DateTime last = DateTime.fromMillisecondsSinceEpoch(0);
    for (var m in ms) {
      if (m.events.isNotEmpty && m.events.last.timestamp.isAfter(last)) {
        last = m.events.last.timestamp;
      }
    }
    return last;
  }
}
