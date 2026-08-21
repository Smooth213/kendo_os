import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/admin/presentation/components/master_delete_dialog_helper.dart';
import 'package:kendo_os/admin/presentation/components/master_empty_state_card.dart';
import 'package:kendo_os/admin/presentation/components/master_menu_bottom_sheet.dart';
import 'package:kendo_os/admin/presentation/components/master_organization_header_bar.dart';
import 'package:kendo_os/admin/presentation/components/master_player_edit_bottom_sheet.dart';
import 'package:kendo_os/admin/presentation/components/master_player_tile.dart';
import 'package:kendo_os/admin/presentation/components/master_player_grouping_helper.dart';
import 'package:kendo_os/admin/presentation/components/master_register_organization_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/security/feature_gate.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/security_level_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';

// 選手一覧のProvider
final playerListProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  final dojoId = ref.watch(currentDojoIdProvider);
  final safeDojoId = dojoId.isNotEmpty ? dojoId : 'test201';
  FirebaseFirestore? firestore;
  try {
    firestore = ref.watch(firestoreProvider);
  } catch (_) {}
  if (firestore == null) {
    return Stream.value([]);
  }
  return firestore
      .collection('organizations')
      .doc(safeDojoId)
      .collection('players')
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((doc) => PlayerModel.fromMap(doc.data(), doc.id))
            .toList(),
      );
});

class MasterManagementScreen extends ConsumerStatefulWidget {
  const MasterManagementScreen({super.key});

  @override
  ConsumerState<MasterManagementScreen> createState() =>
      _MasterManagementScreenState();
}

class _MasterManagementScreenState
    extends ConsumerState<MasterManagementScreen> {
  int _groupingMode = 0;
  bool _isSelectionMode = false;
  final Set<String> _selectedPlayerIds = {};

  @override
  Widget build(BuildContext context) {
    final playerListAsync = ref.watch(playerListProvider);
    final cloudDojoName = ref.watch(currentDojoNameProvider).value ?? '';

    final currentRole = ref.watch(currentUserRoleProvider);
    final currentLevel = ref.watch(securityLevelProvider);

    final bool canManageMaster = FeatureGate.canManageMaster(
      currentRole,
      currentLevel,
    );
    final bool isReadOnly = (currentRole == UserRole.viewer);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;

    final Color primaryColor = isDark
        ? AppKendoColors.purpleAccent
        : context.appColors.primaryAccent;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedPlayerIds.clear();
                    });
                  },
                )
              : null,
          title: _isSelectionMode
              ? '${_selectedPlayerIds.length}人選択中'
              : '選手マスタ管理',
          backgroundColor: enableLiquidGlass
              ? AppKendoColors.transparent
              : themeColors.cardBackground,
          actions: _isSelectionMode
              ? [
                  if (!isReadOnly && canManageMaster)
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppKendoColors.red),
                      tooltip: '選択した選手を削除',
                      onPressed: _selectedPlayerIds.isEmpty
                          ? null
                          : () => MasterDeleteDialogHelper.confirmBulkDelete(
                              context: context,
                              ref: ref,
                              selectedPlayerIds: _selectedPlayerIds,
                              onDeleted: () {
                                setState(() {
                                  _isSelectionMode = false;
                                  _selectedPlayerIds.clear();
                                });
                              },
                            ),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                ]
              : (isReadOnly
                    ? []
                    : [
                        if (canManageMaster)
                          IconButton(
                            icon: Icon(
                              Icons.more_horiz,
                              color: primaryColor,
                              size: 28,
                            ),
                            tooltip: 'マスタ管理メニュー',
                            onPressed: () =>
                                MasterMenuBottomSheet.show(context, ref),
                          ),
                        ManualHelpButton(
                          manualPath: 'docs/manuals/operator/settings.md',
                          color: primaryColor,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ]),
        ),
        body: playerListAsync.when(
          data: (players) {
            if (players.isEmpty && cloudDojoName.isEmpty) {
              return MasterEmptyStateCard(
                primaryColor: primaryColor,
                isReadOnly: isReadOnly,
                onRegisterDojo: () =>
                    MasterRegisterOrganizationBottomSheet.show(context, ref),
              );
            }

            if (players.isNotEmpty) {
              players.sort((a, b) => a.grade.compareTo(b.grade));
            }
            final orgName = players.isNotEmpty
                ? players.first.organization
                : cloudDojoName;

            final Map<String, List<PlayerModel>> groupedPlayers =
                MasterPlayerGroupingHelper.groupPlayers(
                  players: players,
                  groupingMode: _groupingMode,
                );
            final groupKeys = groupedPlayers.keys.toList();

            return Column(
              children: [
                MasterOrganizationHeaderBar(
                  orgName: orgName,
                  players: players,
                  groupingMode: _groupingMode,
                  isSelectionMode: _isSelectionMode,
                  isReadOnly: isReadOnly,
                  canManageMaster: canManageMaster,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  onGroupingModeChanged: (val) =>
                      setState(() => _groupingMode = val),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.giant * 2.5,
                    ),
                    itemCount: groupKeys.length,
                    itemBuilder: (context, index) {
                      final groupName = groupKeys[index];
                      final groupItems = groupedPlayers[groupName]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.xl,
                              bottom: AppSpacing.sm,
                              left: 32,
                            ),
                            child: Text(
                              groupName.toUpperCase(),
                              style: TextStyle(
                                fontSize: AppFontSize.bodySmall,
                                fontWeight: AppFontWeight.semiBold,
                                color: isDark
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0x8A000000),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            decoration: BoxDecoration(
                              color: context.appColors.cardBackground,
                              borderRadius: AppRadius.medium,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: groupItems.asMap().entries.map((entry) {
                                final int idx = entry.key;
                                final PlayerModel player = entry.value;
                                final bool isLast =
                                    idx == groupItems.length - 1;
                                return Column(
                                  children: [
                                    _buildPlayerTile(
                                      context,
                                      ref,
                                      player,
                                      isReadOnly,
                                      canManageMaster,
                                    ),
                                    if (!isLast)
                                      Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: isDark
                                            ? const Color(0xFF38383A)
                                            : const Color(0xFFC6C6C8),
                                        indent: 68,
                                        endIndent: 0,
                                      ),
                                  ],
                                );
                              }).toList(),
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('エラーが発生しました: $err')),
        ),
        floatingActionButton: isReadOnly || _isSelectionMode || !canManageMaster
            ? null
            : FloatingActionButton.extended(
                onPressed: () {
                  if (cloudDojoName.isEmpty) {
                    MasterRegisterOrganizationBottomSheet.showMustRegisterDialog(
                      context,
                      ref,
                    );
                  } else {
                    MasterPlayerEditBottomSheet.show(
                      context,
                      cloudDojoName: cloudDojoName,
                    );
                  }
                },
                backgroundColor: primaryColor,
                foregroundColor: AppKendoColors.pureWhite,
                elevation: 4,
                icon: const Icon(Icons.person_add),
                label: const Text(
                  '選手を追加',
                  style: TextStyle(fontWeight: AppFontWeight.bold),
                ),
              ),
      ),
    );
  }

  Widget _buildPlayerTile(
    BuildContext context,
    WidgetRef ref,
    PlayerModel player,
    bool isReadOnly,
    bool canManageMaster,
  ) {
    final bool isSelected = _selectedPlayerIds.contains(player.id);

    return MasterPlayerTile(
      player: player,
      isReadOnly: isReadOnly,
      canManageMaster: canManageMaster,
      isSelectionMode: _isSelectionMode,
      isSelected: isSelected,
      onTapSelection: () {
        setState(() {
          if (isSelected) {
            _selectedPlayerIds.remove(player.id);
          } else {
            _selectedPlayerIds.add(player.id);
          }
        });
      },
      onLongPress: () {
        if (!_isSelectionMode && !isReadOnly && canManageMaster) {
          HapticFeedback.heavyImpact();
          setState(() {
            _isSelectionMode = true;
            _selectedPlayerIds.add(player.id);
          });
        }
      },
      onEdit: () => MasterPlayerEditBottomSheet.show(
        context,
        player: player,
        cloudDojoName: player.organization,
      ),
      onDelete: () =>
          MasterDeleteDialogHelper.confirmSingleDelete(context, ref, player),
    );
  }
}
