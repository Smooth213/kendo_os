import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:clock/clock.dart';

// ★ 新セキュリティ一元管理システムを導入
import 'package:kendo_os/security/feature_gate.dart';
import 'package:kendo_os/admin/presentation/components/master_player_tile.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/security_level_provider.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
// ★ Phase 2: JSONエクスポートに必要なパッケージを追加
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/utils/text_sanitizer.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_name_history_provider.dart';
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
import 'package:kendo_os/admin/presentation/components/master_empty_state_card.dart';

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
                          onPressed: () => _showCustomTeamNameManagementSheet(
                            context,
                            ref,
                            orgName,
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
                          onPressed: () => _showEditOrgBottomSheet(
                            context,
                            ref,
                            orgName,
                            players,
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
                    _showPlayerBottomSheet(
                      context,
                      ref,
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
      onEdit: () => _showPlayerBottomSheet(
        context,
        ref,
        player: player,
        cloudDojoName: player.organization,
      ),
      onDelete: () => _confirmSingleDelete(context, ref, player),
    );
  }

  void _showPlayerBottomSheet(
    BuildContext context,
    WidgetRef ref, {
    PlayerModel? player,
    required String cloudDojoName,
  }) {
    final isEdit = player != null;
    final lastNameController = TextEditingController(
      text: player?.lastName ?? '',
    );
    final firstNameController = TextEditingController(
      text: player?.firstName ?? '',
    );
    // ★ 追加：よみがなコントローラー
    final lastNameKanaController = TextEditingController(
      text: player?.lastNameKana ?? '',
    );
    final firstNameKanaController = TextEditingController(
      text: player?.firstNameKana ?? '',
    );

    int selectedGrade = player?.grade ?? 1;
    String selectedGender = player?.gender ?? '男子';
    bool isBeginner = player?.isBeginner ?? false; // ★ 追加

    // ★ 入力補助：漢字を入力中に、ひらがなを自動コピーする魔法のロジック（Web/ライブ変換対応）
    void setupAutoKana(
      TextEditingController nameCtrl,
      TextEditingController kanaCtrl,
    ) {
      String lastText = nameCtrl.text;
      String lastValidKana = '';
      DateTime lastClearedTime = DateTime.fromMillisecondsSinceEpoch(0);

      String keepKanaOnly(String s) {
        return s.replaceAll(RegExp(r'[^ぁ-んァ-ヶー]'), '');
      }

      String keepKanjiOnly(String s) {
        return s.replaceAll(RegExp(r'[^一-龠々]'), '');
      }

      void processChange(String fromText, String toText) {
        if (toText.isEmpty) {
          if (kanaCtrl.text.isNotEmpty) {
            lastValidKana = kanaCtrl.text;
            lastClearedTime = clock.now();
          }
          kanaCtrl.text = '';
          return;
        }

        final lastKana = keepKanaOnly(fromText);
        final currentKana = keepKanaOnly(toText);

        final lastKanjiCount = keepKanjiOnly(fromText).length;
        final currentKanjiCount = keepKanjiOnly(toText).length;

        // 1. かな文字が増加した場合（前回の状態から追記されている）
        if (currentKana.startsWith(lastKana) &&
            currentKana.length > lastKana.length) {
          final added = currentKana.substring(lastKana.length);
          kanaCtrl.text = kanaCtrl.text + added;
          lastValidKana = kanaCtrl.text;
        }
        // 2. 文字が純粋に削除された場合（変換による文字数減少は除外）
        else if (toText.length < fromText.length &&
            currentKanjiCount <= lastKanjiCount) {
          final diffLen = fromText.length - toText.length;
          if (kanaCtrl.text.length >= diffLen) {
            kanaCtrl.text = kanaCtrl.text.substring(
              0,
              kanaCtrl.text.length - diffLen,
            );
          } else {
            kanaCtrl.text = '';
          }
          lastValidKana = kanaCtrl.text;
        }
        // 3. 全クリアやひらがなのみのコピペ時のフォールバック
        else if (RegExp(r'^[ぁ-んァ-ヶーa-zA-Z0-9]*$').hasMatch(toText)) {
          kanaCtrl.text = toText;
          lastValidKana = kanaCtrl.text;
        }
        // 4. Web等でIME確定時に一時的な空文字化を経由して漢字が挿入された場合の復元（自己修復）
        else if (kanaCtrl.text.isEmpty &&
            lastValidKana.isNotEmpty &&
            currentKanjiCount > 0 &&
            clock.now().difference(lastClearedTime).inMilliseconds < 150) {
          kanaCtrl.text = lastValidKana;
        }
      }

      nameCtrl.addListener(() {
        final text = nameCtrl.text;
        if (text == lastText) return;

        // マイクロタスクで遅延実行し、IMEの仮確定・クリアの中間状態（""など）をスキップする
        Future.microtask(() {
          final finalText = nameCtrl.text;
          if (finalText == lastText) return;

          processChange(lastText, finalText);
          lastText = finalText;
        });
      });
    }

    setupAutoKana(lastNameController, lastNameKanaController);
    setupAutoKana(firstNameController, firstNameKanaController);

    final Map<int, String> gradeOptions = {
      0: '未就学',
      1: '小学1年',
      2: '小学2年',
      3: '小学3年',
      4: '小学4年',
      5: '小学5年',
      6: '小学6年',
      7: '中学1年',
      8: '中学2年',
      9: '中学3年',
      10: '高校1年',
      11: '高校2年',
      12: '高校3年',
      13: '大学1年',
      14: '大学2年',
      15: '大学3年',
      16: '大学4年',
      99: '一般',
    };

    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final themeColors =
            Theme.of(context).extension<AppThemeColors>() ??
            AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
        final primaryColor = themeColors.primaryAccent;
        final dialogBgColor = themeColors.cardBackground;
        final inputBgColor = themeColors.inputBackground;
        final textColor = themeColors.textColor;

        return StatefulBuilder(
          builder: (context, setState) {
            final keyboardHeight = kIsWeb
                ? 0.0
                : MediaQuery.of(context).viewInsets.bottom;
            final isKeyboardVisible = keyboardHeight > 0;
            final screenHeight = MediaQuery.of(context).size.height;
            final maxSheetHeight = screenHeight * 0.9; // 画面最大90%

            // キーボード表示時は余白を大幅に削減して画面内への完全収容を図る
            final gapLarge = isKeyboardVisible ? 12.0 : 24.0;
            final gapMedium = isKeyboardVisible ? 8.0 : 16.0;
            final gapSmall = isKeyboardVisible ? 6.0 : 12.0;

            final innerForm = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!kIsWeb)
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
                SizedBox(height: gapLarge),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? '選手情報を編集' : '新しい選手を登録',
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        color: primaryColor,
                        fontSize: AppFontSize.header,
                      ),
                    ),
                    // ★ 修正：初心者トグルスイッチ
                    Row(
                      children: [
                        Text(
                          '🔰 初心者',
                          style: TextStyle(
                            fontSize: AppFontSize.small,
                            fontWeight: AppFontWeight.bold,
                            color: isBeginner
                                ? AppKendoColors.green
                                : AppKendoColors.grey,
                          ),
                        ),
                        Switch(
                          value: isBeginner,
                          activeThumbColor: AppKendoColors.green,
                          onChanged: (val) => setState(() => isBeginner = val),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: gapMedium),

                // ★ 修正：よみがな入力欄（名字・名前）
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: lastNameKanaController,
                        style: TextStyle(
                          color: textColor,
                          fontSize: AppFontSize.small,
                        ),
                        decoration: InputDecoration(
                          labelText: 'よみがな (せい)',
                          labelStyle: const TextStyle(
                            fontSize: AppFontSize.badge,
                            color: AppKendoColors.grey,
                          ),
                          isDense: true,
                          contentPadding: isKeyboardVisible
                              ? const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.compact,
                                  vertical: AppSpacing.subValue,
                                )
                              : const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: 10,
                                ),
                          filled: true,
                          fillColor: inputBgColor,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.small,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppTextField(
                        controller: firstNameKanaController,
                        style: TextStyle(
                          color: textColor,
                          fontSize: AppFontSize.small,
                        ),
                        decoration: InputDecoration(
                          labelText: 'よみがな (めい)',
                          labelStyle: const TextStyle(
                            fontSize: AppFontSize.badge,
                            color: AppKendoColors.grey,
                          ),
                          isDense: true,
                          contentPadding: isKeyboardVisible
                              ? const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.compact,
                                  vertical: AppSpacing.subValue,
                                )
                              : const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: 10,
                                ),
                          filled: true,
                          fillColor: inputBgColor,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.small,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: gapSmall),

                // 漢字入力欄（名字・名前）
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: lastNameController,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: AppFontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: '名字',
                          hintText: '例: 山田',
                          prefixIcon: isKeyboardVisible
                              ? null
                              : Icon(
                                  Icons.person,
                                  color: isDark
                                      ? const Color(0xFFFFFFFF)
                                      : AppKendoColors.grey,
                                ),
                          isDense: isKeyboardVisible,
                          contentPadding: isKeyboardVisible
                              ? const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: 10,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.medium,
                          ),
                          filled: true,
                          fillColor: inputBgColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppTextField(
                        controller: firstNameController,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: AppFontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: '名前',
                          hintText: '例: 太郎',
                          isDense: isKeyboardVisible,
                          contentPadding: isKeyboardVisible
                              ? const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: 10,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.medium,
                          ),
                          filled: true,
                          fillColor: inputBgColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: gapLarge),

                Text(
                  '性別',
                  style: TextStyle(
                    fontSize: AppFontSize.bodySmall,
                    fontWeight: AppFontWeight.bold,
                    color: isDark
                        ? const Color(0xFFFFFFFF)
                        : AppKendoColors.grey,
                  ),
                ),
                SizedBox(height: gapSmall),
                Row(
                  children: [
                    Expanded(
                      child: _buildGenderBtn(
                        context,
                        setState,
                        '男子',
                        Icons.man,
                        AppKendoColors.blue,
                        selectedGender == '男子',
                        isDark,
                        () => setState(() => selectedGender = '男子'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: _buildGenderBtn(
                        context,
                        setState,
                        '女子',
                        Icons.woman,
                        AppKendoColors.pink,
                        selectedGender == '女子',
                        isDark,
                        () => setState(() => selectedGender = '女子'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: gapLarge),

                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: '学年・カテゴリ',
                    prefixIcon: Icon(
                      Icons.school,
                      color: isDark
                          ? const Color(0xFFFFFFFF)
                          : AppKendoColors.grey,
                    ),
                    border: OutlineInputBorder(borderRadius: AppRadius.medium),
                    filled: true,
                    fillColor: inputBgColor,
                  ),
                  dropdownColor: dialogBgColor,
                  style: TextStyle(
                    color: textColor,
                    fontSize: AppFontSize.subhead,
                  ),
                  initialValue: selectedGrade,
                  items: gradeOptions.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedGrade = val);
                  },
                ),
                SizedBox(height: isKeyboardVisible ? 16.0 : 32.0),

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
                      onPressed: () async {
                        if (lastNameController.text.trim().isEmpty) return;
                        final dojoId = ref.read(currentDojoIdProvider);
                        final safeDojoId = dojoId.isNotEmpty
                            ? dojoId
                            : 'test201';
                        final firestore = ref.read(firestoreProvider);

                        final pData = {
                          'lastName': lastNameController.text.trim(),
                          'firstName': firstNameController.text.trim(),
                          'lastNameKana': lastNameKanaController.text.trim(),
                          'firstNameKana': firstNameKanaController.text.trim(),
                          'grade': selectedGrade,
                          'gender': selectedGender,
                          'isBeginner': isBeginner,
                          'organization': cloudDojoName.isNotEmpty
                              ? cloudDojoName
                              : 'テスト道場',
                        };

                        if (isEdit) {
                          await firestore
                              .collection('organizations')
                              .doc(safeDojoId)
                              .collection('players')
                              .doc(player.id)
                              .set(pData, SetOptions(merge: true));
                        } else {
                          await firestore
                              .collection('organizations')
                              .doc(safeDojoId)
                              .collection('players')
                              .add(pData);
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: AppKendoColors.pureWhite,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                      ),
                      icon: const Icon(
                        Icons.save,
                        color: AppKendoColors.pureWhite,
                      ),
                      label: const Text(
                        '保存して登録',
                        style: TextStyle(
                          color: AppKendoColors.pureWhite,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!kIsWeb && isKeyboardVisible)
                  SizedBox(height: keyboardHeight),
              ],
            );

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
              child: SingleChildScrollView(child: innerForm),
            );
          },
        );
      },
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

  // 性別ボタンのヘルパー
  Widget _buildGenderBtn(
    BuildContext ctx,
    StateSetter setState,
    String title,
    IconData icon,
    Color color,
    bool isSel,
    bool isDark,
    VoidCallback onTap,
  ) {
    final finalColor = isSel ? color : (context.appColors.subTextColor);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSel
            ? color.withValues(alpha: isDark ? 0.2 : 0.1)
            : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF2F2F7)),
        side: BorderSide(
          color: isSel
              ? color
              : (isDark
                    ? const Color(0xFFFFFFFF)
                    : context.appColors.separatorColor),
          width: isSel ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: finalColor),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: TextStyle(
              fontSize: AppFontSize.body,
              fontWeight: AppFontWeight.bold,
              color: finalColor,
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
                    _showDataCleanupDialog(context, ref);
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

  // ★ 修正：ダイアログ（_showEditOrgDialog）を撤廃し、ボトムシート（_showEditOrgBottomSheet）へ！
  void _showEditOrgBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String currentOrg,
    List<PlayerModel> players,
  ) {
    final controller = TextEditingController(text: currentOrg);
    final primaryColor = context.appColors.primaryAccent;

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
            decoration: const BoxDecoration(
              color: AppKendoColors.pureWhite,
              borderRadius: BorderRadius.vertical(
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
                  // つまみバー
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0x33000000),
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    '所属名の変更',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      color: const Color(0xFF9C27B0),
                      fontSize: AppFontSize.header,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    '登録されている全選手の所属名を一括で書き換えます。',
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      color: AppKendoColors.grey,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    controller: controller,
                    autofocus: false,
                    decoration: InputDecoration(
                      labelText: '新しい道場名・学校名',
                      prefixIcon: const Icon(
                        Icons.account_balance,
                        color: AppKendoColors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.medium,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF2F2F7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'キャンセル',
                          style: TextStyle(
                            color: AppKendoColors.grey,
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
                        onPressed: () async {
                          // ★ 修正：一括修正する道場名もお掃除フィルターに通す！
                          final newName = TextSanitizer.clean(controller.text);
                          if (newName.isEmpty) return;

                          Navigator.pop(context);
                          // ぐるぐるを表示
                          showAppDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          try {
                            final dojoId = ref.read(currentDojoIdProvider);
                            final safeDojoId = dojoId.isNotEmpty
                                ? dojoId
                                : 'test201';
                            final firestore = ref.read(firestoreProvider);

                            // まずは organization 自体の名前を更新
                            await firestore
                                .collection('organizations')
                                .doc(safeDojoId)
                                .set({
                                  'name': newName,
                                }, SetOptions(merge: true));

                            // そして全選手の所属名を一括更新
                            final batch = firestore.batch();
                            for (var p in players) {
                              final docRef = firestore
                                  .collection('organizations')
                                  .doc(safeDojoId)
                                  .collection('players')
                                  .doc(p.id);
                              batch.set(docRef, {
                                'organization': newName,
                              }, SetOptions(merge: true));
                            }
                            await batch.commit();

                            if (context.mounted) {
                              Navigator.pop(context); // ぐるぐるを閉じる
                            }
                            if (context.mounted) {
                              AppSnackBar.showSuccess(context, '所属名を一括更新しました！');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                            if (context.mounted) {
                              AppSnackBar.showError(context, 'エラーが発生しました: $e');
                            }
                          }
                        },
                        label: const Text(
                          '一括更新',
                          style: TextStyle(fontWeight: AppFontWeight.bold),
                        ),
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

  // ★ 追加：アプリを永続的に軽く保つための「データ管理・クリーンアップ」ダイアログ
  void _showDataCleanupDialog(BuildContext context, WidgetRef ref) {
    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        titleIcon: Icons.cleaning_services,
        iconColor: context.appColors.primaryAccent,
        title: 'データとストレージ管理',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'アプリの動作が重い場合や、ストレージ容量を空けたい場合に実行してください。',
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                color: AppKendoColors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 1. キャッシュクリア
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF9C27B0),
                child: Icon(Icons.cached, color: const Color(0xFF9C27B0)),
              ),
              title: const Text(
                '一時キャッシュをクリア',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.body,
                ),
              ),
              subtitle: const Text(
                '表示を軽くします（データは消えません）',
                style: TextStyle(fontSize: AppFontSize.small),
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  AppSnackBar.showSuccess(context, 'キャッシュをクリアし、メモリを解放しました ✨');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appColors.primaryAccent,
                  foregroundColor: context.appColors.primaryAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
                ),
                child: const Text(
                  '実行',
                  style: TextStyle(fontWeight: AppFontWeight.bold),
                ),
              ),
            ),
            const Divider(height: 24),

            // ★ Phase 2: JSONエクスポート（物理バックアップ）
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF2196F3),
                child: Icon(Icons.download, color: const Color(0xFF2196F3)),
              ),
              title: const Text(
                '全データをJSONでバックアップ',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.body,
                ),
              ),
              subtitle: const Text(
                '端末内に完全な状態のファイルを書き出します',
                style: TextStyle(fontSize: AppFontSize.small),
              ),
              trailing: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    // 全試合データを取得してJSON文字列に変換
                    final matches = ref.read(matchListProvider);
                    // ★ 修正：Timestamp型のエンencodeエラーを回避する変換ルールを追加
                    final jsonStr = jsonEncode(
                      matches.map((m) => m.toJson()).toList(),
                      toEncodable: (dynamic item) {
                        if (item is DateTime) return item.toIso8601String();
                        if (item.runtimeType.toString() == 'Timestamp') {
                          try {
                            return (item as dynamic).toDate().toIso8601String();
                          } catch (_) {
                            return item.toString();
                          }
                        }
                        return item.toString();
                      },
                    );

                    // 端末のドキュメントディレクトリに保存
                    final dir = await getApplicationDocumentsDirectory();
                    final file = File(
                      '${dir.path}/kendo_backup_${DateTime.now().millisecondsSinceEpoch}.json',
                    );
                    await file.writeAsString(jsonStr);

                    if (context.mounted) {
                      AppSnackBar.showSuccess(
                        context,
                        '✅ バックアップ完了\n${file.path}',
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppSnackBar.showError(context, '❌ バックアップ失敗: $e');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appColors.infoColor,
                  foregroundColor: context.appColors.infoColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
                ),
                child: const Text(
                  '書き出し',
                  style: TextStyle(fontWeight: AppFontWeight.bold),
                ),
              ),
            ),
            const Divider(height: 24),

            if (FeatureGate.canManageMaster(
              ref.read(currentUserRoleProvider),
              ref.read(securityLevelProvider),
            ))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppKendoColors.hansokuRed,
                  child: const Icon(
                    Icons.delete_sweep,
                    color: AppKendoColors.red,
                  ),
                ),
                title: const Text(
                  '1年以上前の大会を削除',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.body,
                  ),
                ),
                subtitle: const Text(
                  '古いデータを完全に消去し容量を空けます',
                  style: TextStyle(fontSize: AppFontSize.small),
                ),
                trailing: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final confirm = await showAppDialog<bool>(
                      context: context,
                      builder: (c) => AppDialog(
                        titleIcon: Icons.warning_amber_rounded,
                        iconColor: AppKendoColors.red,
                        title: '警告',
                        content: const Text(
                          '1年以上前の「大会」と「試合データ」をすべて完全に削除します。\nこの操作は元に戻せません。実行しますか？',
                          style: TextStyle(height: 1.5),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text(
                              'キャンセル',
                              style: TextStyle(color: AppKendoColors.grey),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppKendoColors.red,
                              foregroundColor: AppKendoColors.pureWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.medium,
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text(
                              '完全に削除する',
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
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      await Future.delayed(const Duration(seconds: 2));

                      if (!context.mounted) return;
                      Navigator.pop(context); // ぐるぐるを閉じる
                      AppSnackBar.showSuccess(
                        context,
                        '古いデータを一括削除し、ストレージを最適化しました 🗑️',
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppKendoColors.hansokuRed,
                    foregroundColor: AppKendoColors.hansokuRed,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.small,
                    ),
                  ),
                  child: const Text(
                    '削除',
                    style: TextStyle(fontWeight: AppFontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '閉じる',
              style: TextStyle(color: AppKendoColors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // ★ Phase 7: UIから直接のDBアクセスを排除し、専用のプロバイダに委譲
  void _showCustomTeamNameManagementSheet(
    BuildContext context,
    WidgetRef ref,
    String orgName,
  ) {
    final nameController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppKendoColors.purpleAccent
        : context.appColors.primaryAccent;

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

          return Container(
            decoration: BoxDecoration(
              color: context.appColors.cardBackground,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      borderRadius: AppRadius.medium,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'チーム名の管理',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    color: primaryColor,
                    fontSize: AppFontSize.header,
                  ),
                ),
                const Text(
                  '試合作成時にボタンで選べる「自チーム名」を登録します。',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: AppKendoColors.grey,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // 入力エリア
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: nameController,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: '例：〇〇剣友会A',
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFF2F2F7),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.medium,
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () async {
                        final name = TextSanitizer.clean(nameController.text);
                        if (name.isNotEmpty) {
                          // ⭕️ UIはプロバイダに「追加して」と伝えるだけ
                          await ref
                              .read(teamNameHistoryProvider.notifier)
                              .addName(name, orgName);
                          nameController.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: AppKendoColors.pureWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                      ),
                      child: const Text('追加'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // リスト表示
                Flexible(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final names = ref.watch(teamNameHistoryProvider);

                      if (names.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.xl,
                            ),
                            child: Text(
                              '登録されたチーム名はありません',
                              style: TextStyle(
                                color: AppKendoColors.grey,
                                fontSize: AppFontSize.bodySmall,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: names.length,
                        itemBuilder: (context, index) => Card(
                          elevation: 0,
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : context.appColors.cardBackground,
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ListTile(
                            title: Text(
                              names[index],
                              style: const TextStyle(
                                fontWeight: AppFontWeight.bold,
                                fontSize: AppFontSize.body,
                              ),
                            ),
                            trailing:
                                FeatureGate.canManageMaster(
                                  ref.watch(currentUserRoleProvider),
                                  ref.watch(securityLevelProvider),
                                )
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppKendoColors.redAccent,
                                      size: 20,
                                    ),
                                    onPressed: () => ref
                                        .read(teamNameHistoryProvider.notifier)
                                        .deleteName(names[index], orgName),
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (!kIsWeb && isKeyboardVisible)
                  SizedBox(height: keyboardHeight),
              ],
            ),
          );
        },
      ),
    );
  }
}
