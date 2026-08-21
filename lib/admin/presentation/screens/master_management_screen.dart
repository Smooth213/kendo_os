import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';

// ★ 新セキュリティ一元管理システムを導入
import 'package:kendo_os/security/feature_gate.dart';
import 'package:kendo_os/admin/presentation/components/master_player_tile.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/security_level_provider.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import 'package:kendo_os/shared/utils/text_sanitizer.dart';
import 'package:flutter/services.dart'; // ★ 長押し時のバイブレーション用
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/admin/presentation/components/master_empty_state_card.dart';
import 'package:kendo_os/admin/presentation/components/master_data_cleanup_dialog.dart';
import 'package:kendo_os/admin/presentation/components/master_team_name_management_sheet.dart';
import 'package:kendo_os/admin/presentation/components/master_edit_organization_bottom_sheet.dart';
import 'package:kendo_os/admin/presentation/components/master_player_edit_bottom_sheet.dart';

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
  // 表示モード (0: 学年別, 1: カテゴリ別)
  int _groupingMode = 0;

  // ★ 追加：選択モード用の状態管理
  bool _isSelectionMode = false;
  final Set<String> _selectedPlayerIds = {};

  @override
  Widget build(BuildContext context) {
    final playerListAsync = ref.watch(playerListProvider);
    final cloudDojoName = ref.watch(currentDojoNameProvider).value ?? '';

    // ★ 状態のリアルタイム監視をバインド
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
    final Color textColor = context.appColors.textColor;

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
                          : () => _confirmBulkDelete(context, ref),
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
                                _showMasterMenuBottomSheet(context, ref),
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
            // ★ 直感UX改修：Empty Stateも「透かしアイコン」の世界観に完全統一
            if (players.isEmpty && cloudDojoName.isEmpty) {
              return MasterEmptyStateCard(
                primaryColor: primaryColor,
                isReadOnly: isReadOnly,
                onRegisterDojo: () => _showInitialOrgBottomSheet(context),
              );
            }

            if (players.isNotEmpty) {
              players.sort((a, b) => a.grade.compareTo(b.grade));
            }
            final orgName = players.isNotEmpty
                ? players.first.organization
                : cloudDojoName;

            Map<String, List<PlayerModel>> groupedPlayers = {};
            if (_groupingMode == 0) {
              for (var p in players) {
                groupedPlayers.putIfAbsent(p.gradeName, () => []).add(p);
              }
            } else {
              for (var p in players) {
                String cat = _getCategoryName(p.grade);
                groupedPlayers.putIfAbsent(cat, () => []).add(p);
              }
            }
            final groupKeys = groupedPlayers.keys.toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.lg,
                    left: 32,
                    right: 32,
                    bottom: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        color: primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          orgName,
                          style: TextStyle(
                            fontSize: AppFontSize.headline,
                            fontWeight: AppFontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),

                      if (!_isSelectionMode &&
                          !isReadOnly &&
                          canManageMaster) ...[
                        IconButton(
                          icon: Icon(
                            Icons.format_list_bulleted_add,
                            color: primaryColor.withValues(alpha: 0.7),
                          ),
                          tooltip: 'よく使うチーム名の管理',
                          onPressed: () => showAppBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            enableDrag: false,
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.85,
                            ),
                            builder: (ctx) =>
                                MasterTeamNameManagementSheet(orgName: orgName),
                          ),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(AppSpacing.sm),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit_note,
                            color: context.appColors.subTextColor,
                          ),
                          tooltip: '道場名・学校名を一括変更',
                          onPressed: () =>
                              MasterEditOrganizationBottomSheet.show(
                                context,
                                currentName: orgName,
                                players: players,
                              ),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(AppSpacing.sm),
                        ),
                      ],
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('学年別')),
                      ButtonSegment(value: 1, label: Text('カテゴリ別')),
                    ],
                    selected: {_groupingMode},
                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() => _groupingMode = newSelection.first);
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: isDark
                          ? const Color(0xFF9C27B0).withValues(alpha: 0.4)
                          : const Color(0xFF9C27B0),
                      selectedForegroundColor: primaryColor,
                      side: BorderSide(color: context.appColors.separatorColor),
                    ),
                  ),
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
                    _showMustRegisterOrgDialog(context);
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

  // ★ 修正：チーム登録画面と文字列を完全に同期させ、「自動並び替え・抽出」を正常化する
  String _getCategoryName(int grade) {
    if (grade == -1) return '初心者の部'; // ★ 追加：初心者を抽出できるようにする
    if (grade == 0) return '幼年の部';
    if (grade >= 1 && grade <= 4) return '小学生低学年の部';
    if (grade >= 5 && grade <= 6) return '小学生高学年の部';
    if (grade >= 7 && grade <= 9) return '中学生の部';
    if (grade >= 10 && grade <= 12) return '高校生の部';
    return '一般の部';
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
      onDelete: () => _confirmSingleDelete(context, ref, player),
    );
  }

  // ★ 初期道場名入力専用ボトムシート
  void _showInitialOrgBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppKendoColors.purpleAccent
        : context.appColors.primaryAccent;
    final dialogBgColor = isDark
        ? const Color(0xFF1E1E1E)
        : context.appColors.textColor;
    final inputBgColor = isDark
        ? const Color(0xFF2C2C2C)
        : context.appColors.cardBackground;
    final textColor = context.appColors.textColor;

    final initialName = ref.read(currentDojoNameProvider).value ?? '';
    final controller = TextEditingController(text: initialName);

    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final keyboardHeight = kIsWeb
              ? 0.0
              : MediaQuery.of(context).viewInsets.bottom;
          final isKeyboardVisible = keyboardHeight > 0;
          final screenHeight = MediaQuery.of(context).size.height;
          final maxSheetHeight = screenHeight * 0.9;

          return Container(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            decoration: BoxDecoration(
              color: dialogBgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xlargeValue),
              ),
            ),
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              bottom: AppSpacing.xl,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFFFFFFF)
                            : const Color(0x33000000),
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    '道場名・学校名の登録',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      color: isDark
                          ? AppKendoColors.purpleAccent
                          : const Color(0xFF9C27B0),
                      fontSize: AppFontSize.header,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    '選手を追加する前に、道場名または学校名を入力してください。',
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      color: AppKendoColors.grey,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    controller: controller,
                    autofocus: false,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: '道場名・学校名',
                      prefixIcon: Icon(
                        Icons.account_balance,
                        color: isDark
                            ? const Color(0xFFFFFFFF)
                            : AppKendoColors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.medium,
                      ),
                      filled: true,
                      fillColor: inputBgColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'キャンセル',
                          style: TextStyle(
                            color: isDark
                                ? context.appColors.subTextColor
                                : AppKendoColors.grey,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: AppKendoColors.pureWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.medium,
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.lg,
                          ),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('登録'),
                        onPressed: () async {
                          final newName = TextSanitizer.clean(controller.text);
                          if (newName.isEmpty) return;

                          final dojoId = ref.read(currentDojoIdProvider);
                          final safeDojoId = dojoId.isNotEmpty
                              ? dojoId
                              : 'test201';
                          final firestore = ref.read(firestoreProvider);

                          await firestore
                              .collection('organizations')
                              .doc(safeDojoId)
                              .set({'name': newName}, SetOptions(merge: true));

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                  if (!kIsWeb && isKeyboardVisible)
                    SizedBox(height: keyboardHeight),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ★ 先行入力強制ダイアログ
  void _showMustRegisterOrgDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppKendoColors.purpleAccent
        : context.appColors.primaryAccent;

    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        titleIcon: Icons.warning_amber_rounded,
        iconColor: context.appColors.warningColor,
        title: '道場名の登録が必要です',
        content: const Text(
          '選手を登録する前に、まずは道場名・学校名を登録してください。',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: AppKendoColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showInitialOrgBottomSheet(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: AppKendoColors.pureWhite,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
              elevation: 0,
            ),
            child: const Text(
              '道場名を入力',
              style: TextStyle(fontWeight: AppFontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ★ 追加：他画面と操作感を統一したマスタ管理用のボトムシートメニュー
  void _showMasterMenuBottomSheet(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showAppBottomSheet(
      context: context,
      builder: (ctx) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.appColors.cardBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xlargeValue),
          ),
        ),
        child: Material(
          color: AppKendoColors.transparent,
          child: Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: 56,
            ), // 下部の余白を増やして角丸との干渉を防ぐ
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0x8A000000),
                      borderRadius: AppRadius.medium,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppKendoColors.purple.withValues(
                      alpha: 0.1,
                    ),
                    child: Icon(
                      Icons.cleaning_services,
                      color: const Color(0xFF9C27B0),
                    ),
                  ),
                  title: Text(
                    'データとストレージ管理',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      color: context.appColors.textColor,
                    ),
                  ),
                  subtitle: const Text(
                    'キャッシュクリアやデータのエクスポート・整理を行います',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      color: AppKendoColors.grey,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    showAppDialog(
                      context: context,
                      builder: (dialogCtx) => const MasterDataCleanupDialog(),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF38383A)
                        : context.appColors.separatorColor,
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppKendoColors.indigo.withValues(
                      alpha: 0.1,
                    ),
                    child: Icon(Icons.school, color: const Color(0xFF3F51B5)),
                  ),
                  title: Text(
                    '新年度の一括進級',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      color: context.appColors.textColor,
                    ),
                  ),
                  subtitle: const Text(
                    'すべての選手の学年を1つ繰り上げます',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      color: AppKendoColors.grey,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPromoteConfirmDialog(context, ref);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPromoteConfirmDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        titleIcon: Icons.school,
        iconColor: context.appColors.primaryAccent,
        title: '新年度の一括進級',
        content: const Text(
          'すべての選手の学年を1つ繰り上げます。\n（例：小学6年 ➔ 中学1年）\n\n※この操作は取り消せません。本当によろしいですか？',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: AppKendoColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: AppKendoColors.pureWhite,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
              elevation: 0,
            ),
            child: const Text(
              '一括進級を実行',
              style: TextStyle(fontWeight: AppFontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      showAppDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      try {
        await ref.read(playerRepositoryProvider).promoteAllPlayers();
        if (!context.mounted) return;
        Navigator.pop(context);
        AppSnackBar.showSuccess(context, '一括進級が完了しました🌸');
      } catch (e) {
        if (!context.mounted) return;
        Navigator.pop(context);
        AppSnackBar.showError(context, 'エラーが発生しました: $e');
      }
    }
  }

  void _confirmSingleDelete(
    BuildContext context,
    WidgetRef ref,
    PlayerModel player,
  ) {
    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: '削除の確認',
        content: const Text('選手データを完全に削除します。この操作は取り消せません。よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final dojoId = ref.read(currentDojoIdProvider);
              final safeDojoId = dojoId.isNotEmpty ? dojoId : 'test201';
              final firestore = ref.read(firestoreProvider);
              await firestore
                  .collection('organizations')
                  .doc(safeDojoId)
                  .collection('players')
                  .doc(player.id)
                  .delete();
            },
            child: const Text(
              '削除',
              style: TextStyle(
                color: AppKendoColors.red,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ★ 追加：選択された複数選手の一括削除処理
  void _confirmBulkDelete(BuildContext context, WidgetRef ref) {
    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: '一括削除の確認',
        content: Text(
          '${_selectedPlayerIds.length}人の選手データを完全に削除します。この操作は取り消せません。よろしいですか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              final idsToDelete = _selectedPlayerIds.toList();
              Navigator.pop(ctx);

              final dojoId = ref.read(currentDojoIdProvider);
              final safeDojoId = dojoId.isNotEmpty ? dojoId : 'test201';
              final firestore = ref.read(firestoreProvider);
              final batch = firestore.batch();

              for (final id in idsToDelete) {
                final docRef = firestore
                    .collection('organizations')
                    .doc(safeDojoId)
                    .collection('players')
                    .doc(id);
                batch.delete(docRef);
              }

              await batch.commit();

              setState(() {
                _isSelectionMode = false;
                _selectedPlayerIds.clear();
              });
            },
            child: const Text(
              'すべて削除',
              style: TextStyle(
                color: AppKendoColors.red,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
