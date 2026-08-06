import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:clock/clock.dart';

// ★ 新セキュリティ一元管理システムを導入
import 'package:kendo_os/security/feature_gate.dart';
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
import 'package:flutter_slidable/flutter_slidable.dart'; // ★ iPhoneライクなスワイプ用
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        ? Colors.purpleAccent
        : Colors.purple.shade700;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
              ? Colors.transparent
              : themeColors.cardBackground,
          actions: _isSelectionMode
              ? [
                  if (!isReadOnly && canManageMaster)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: '選択した選手を削除',
                      onPressed: _selectedPlayerIds.isEmpty
                          ? null
                          : () => _confirmBulkDelete(context, ref),
                    ),
                  const SizedBox(width: 8),
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
                        const SizedBox(width: 8),
                      ]),
        ),
        body: playerListAsync.when(
          data: (players) {
            // ★ 直感UX改修：Empty Stateも「透かしアイコン」の世界観に完全統一
            if (players.isEmpty && cloudDojoName.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/kendo_icon.png',
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'まだ選手が登録されていません',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '選手を追加する前に、まずはあなたたちの道場名・学校名を登録することから始めましょう！',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (!isReadOnly)
                      SizedBox(
                        width: 240,
                        child: GlassButton(
                          onPressed: () => _showInitialOrgBottomSheet(context),
                          color: primaryColor,
                          icon: Icons.account_balance,
                          label: '道場名を登録する',
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                  ],
                ),
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
                    top: 16,
                    left: 32,
                    right: 32,
                    bottom: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        color: primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          orgName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                          padding: const EdgeInsets.all(8),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit_note,
                            color: Colors.grey.shade400,
                          ),
                          tooltip: '道場名・学校名を一括変更',
                          onPressed: () => _showEditOrgBottomSheet(
                            context,
                            ref,
                            orgName,
                            players,
                          ),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
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
                          ? Colors.purple.shade900.withValues(alpha: 0.4)
                          : Colors.purple.shade50,
                      selectedForegroundColor: primaryColor,
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF38383A)
                            : Colors.grey.shade200,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: groupKeys.length,
                    itemBuilder: (context, index) {
                      final groupName = groupKeys[index];
                      final groupItems = groupedPlayers[groupName]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 24,
                              bottom: 8,
                              left: 32,
                            ),
                            child: Text(
                              groupName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1C1C1E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
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
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.person_add),
                label: const Text(
                  '選手を追加',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMale = player.gender == '男子';

    final genderColor = isMale
        ? (isDark ? Colors.blue.shade300 : Colors.blue.shade600)
        : (isDark ? Colors.pink.shade300 : Colors.pink.shade600);
    final bgColor = isMale
        ? (isDark
              ? Colors.blue.withValues(alpha: 0.25)
              : Colors.blue.withValues(alpha: 0.1))
        : (isDark
              ? Colors.pink.withValues(alpha: 0.25)
              : Colors.pink.withValues(alpha: 0.1));

    final bool isSelected = _selectedPlayerIds.contains(player.id);
    final selectedColor = isDark
        ? Colors.purple.withValues(alpha: 0.2)
        : Colors.purple.shade50;

    final tile = Material(
      color: _isSelectionMode && isSelected
          ? selectedColor
          : Colors.transparent,
      child: InkWell(
        onTap: _isSelectionMode
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedPlayerIds.remove(player.id);
                  } else {
                    _selectedPlayerIds.add(player.id);
                  }
                });
              }
            : null,
        onLongPress: () {
          if (!_isSelectionMode && !isReadOnly && canManageMaster) {
            HapticFeedback.heavyImpact();
            setState(() {
              _isSelectionMode = true;
              _selectedPlayerIds.add(player.id);
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected
                        ? Colors.purple.shade700
                        : Colors.grey.shade400,
                    size: 22,
                  ),
                ),
              CircleAvatar(
                backgroundColor: bgColor,
                foregroundColor: genderColor,
                radius: 18,
                child: Text(
                  player.lastName.isNotEmpty
                      ? player.lastName.substring(0, 1)
                      : '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (player.isBeginner) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.eco, size: 10, color: Colors.white),
                                SizedBox(width: 2),
                                Text(
                                  '初心者',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (player.nameKana.isNotEmpty)
                          Text(
                            '${player.nameKana} ',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400,
                              fontSize: 11,
                            ),
                          ),
                        Text(
                          '${player.gradeName} / ${player.gender}',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (_isSelectionMode || isReadOnly || !canManageMaster) {
      return tile;
    }

    return Slidable(
      key: ValueKey(player.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _showPlayerBottomSheet(
              context,
              ref,
              player: player,
              cloudDojoName: player.organization,
            ),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: '編集',
          ),
          SlidableAction(
            onPressed: (context) => _confirmSingleDelete(context, ref, player),
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '削除',
          ),
        ],
      ),
      child: tile,
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
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
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
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 20,
                      ),
                    ),
                    // ★ 修正：初心者トグルスイッチ
                    Row(
                      children: [
                        Text(
                          '🔰 初心者',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isBeginner ? Colors.green : Colors.grey,
                          ),
                        ),
                        Switch(
                          value: isBeginner,
                          activeThumbColor: Colors.green,
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
                      child: TextField(
                        controller: lastNameKanaController,
                        style: TextStyle(color: textColor, fontSize: 12),
                        decoration: InputDecoration(
                          labelText: 'よみがな (せい)',
                          labelStyle: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          isDense: true,
                          contentPadding: isKeyboardVisible
                              ? const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                )
                              : const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                          filled: true,
                          fillColor: inputBgColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: firstNameKanaController,
                        style: TextStyle(color: textColor, fontSize: 12),
                        decoration: InputDecoration(
                          labelText: 'よみがな (めい)',
                          labelStyle: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          isDense: true,
                          contentPadding: isKeyboardVisible
                              ? const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                )
                              : const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                          filled: true,
                          fillColor: inputBgColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
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
                      child: TextField(
                        controller: lastNameController,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: '名字',
                          hintText: '例: 山田',
                          prefixIcon: isKeyboardVisible
                              ? null
                              : Icon(
                                  Icons.person,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey,
                                ),
                          isDense: isKeyboardVisible,
                          contentPadding: isKeyboardVisible
                              ? const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: inputBgColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: firstNameController,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: '名前',
                          hintText: '例: 太郎',
                          isDense: isKeyboardVisible,
                          contentPadding: isKeyboardVisible
                              ? const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade400 : Colors.grey,
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
                        Colors.blue,
                        selectedGender == '男子',
                        isDark,
                        () => setState(() => selectedGender = '男子'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildGenderBtn(
                        context,
                        setState,
                        '女子',
                        Icons.woman,
                        Colors.pink,
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
                      color: isDark ? Colors.grey.shade400 : Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: inputBgColor,
                  ),
                  dropdownColor: dialogBgColor,
                  style: TextStyle(color: textColor, fontSize: 16),
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
                          color: isDark ? Colors.grey.shade400 : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        '保存して登録',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.only(
                top: 16,
                left: 24,
                right: 24,
                bottom: 24,
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
    final primaryColor = isDark ? Colors.purpleAccent : Colors.purple.shade700;
    final dialogBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputBgColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50;
    final textColor = isDark ? Colors.white : Colors.black87;

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
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.only(
              top: 16,
              left: 24,
              right: 24,
              bottom: 24,
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
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '道場名・学校名の登録',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.purpleAccent
                          : Colors.purple.shade800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '選手を追加する前に、道場名または学校名を入力してください。',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller,
                    autofocus: false,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: '道場名・学校名',
                      prefixIcon: Icon(
                        Icons.account_balance,
                        color: isDark ? Colors.grey.shade400 : Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: inputBgColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'キャンセル',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
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
    final primaryColor = isDark ? Colors.purpleAccent : Colors.purple.shade700;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Text(
              '道場名の登録が必要です',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          '選手を登録する前に、まずは道場名・学校名を登録してください。',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showInitialOrgBottomSheet(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              '道場名を入力',
              style: TextStyle(fontWeight: FontWeight.bold),
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
    final finalColor = isSel
        ? color
        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSel
            ? color.withValues(alpha: isDark ? 0.2 : 0.1)
            : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50),
        side: BorderSide(
          color: isSel
              ? color
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          width: isSel ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: finalColor),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
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
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.only(
              top: 16,
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
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.cleaning_services,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  title: Text(
                    'データとストレージ管理',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: const Text(
                    'キャッシュクリアやデータのエクスポート・整理を行います',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDataCleanupDialog(context, ref);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF38383A)
                        : Colors.grey.shade300,
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                    child: Icon(Icons.school, color: Colors.indigo.shade700),
                  ),
                  title: Text(
                    '新年度の一括進級',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: const Text(
                    'すべての選手の学年を1つ繰り上げます',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ), // ★ フェーズ2：角丸の統一
        title: Row(
          children: [
            Icon(Icons.school, color: Colors.purple.shade700),
            const SizedBox(width: 8),
            Text(
              '新年度の一括進級',
              style: TextStyle(
                color: Colors.purple.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'すべての選手の学年を1つ繰り上げます。\n（例：小学6年 ➔ 中学1年）\n\n※この操作は取り消せません。本当によろしいですか？',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              '一括進級を実行',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      showDialog(
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除の確認'),
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
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ★ 追加：選択された複数選手の一括削除処理
  void _confirmBulkDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('一括削除の確認'),
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
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
    final primaryColor = Colors.purple.shade700;

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
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.only(
              top: 16,
              left: 24,
              right: 24,
              bottom: 24,
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
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    '所属名の変更',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '登録されている全選手の所属名を一括で書き換えます。',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller,
                    autofocus: false,
                    decoration: InputDecoration(
                      labelText: '新しい道場名・学校名',
                      prefixIcon: const Icon(
                        Icons.account_balance,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'キャンセル',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        icon: const Icon(Icons.check),
                        onPressed: () async {
                          // ★ 修正：一括修正する道場名もお掃除フィルターに通す！
                          final newName = TextSanitizer.clean(controller.text);
                          if (newName.isEmpty) return;

                          Navigator.pop(context);
                          // ぐるぐるを表示
                          showDialog(
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
                          style: TextStyle(fontWeight: FontWeight.bold),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ), // ★ フェーズ2：角丸の統一
        title: Row(
          children: [
            Icon(Icons.cleaning_services, color: Colors.purple.shade700),
            const SizedBox(width: 8),
            const Text(
              'データとストレージ管理',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'アプリの動作が重い場合や、ストレージ容量を空けたい場合に実行してください。',
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 24),

            // 1. キャッシュクリア
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade50,
                child: Icon(Icons.cached, color: Colors.purple.shade700),
              ),
              title: const Text(
                '一時キャッシュをクリア',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text(
                '表示を軽くします（データは消えません）',
                style: TextStyle(fontSize: 12),
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  AppSnackBar.showSuccess(context, 'キャッシュをクリアし、メモリを解放しました ✨');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade50,
                  foregroundColor: Colors.purple.shade800,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '実行',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Divider(height: 24),

            // ★ Phase 2: JSONエクスポート（物理バックアップ）
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: Icon(Icons.download, color: Colors.blue.shade700),
              ),
              title: const Text(
                '全データをJSONでバックアップ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text(
                '端末内に完全な状態のファイルを書き出します',
                style: TextStyle(fontSize: 12),
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
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade800,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '書き出し',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                  backgroundColor: Colors.red.shade50,
                  child: const Icon(Icons.delete_sweep, color: Colors.red),
                ),
                title: const Text(
                  '1年以上前の大会を削除',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  '古いデータを完全に消去し容量を空けます',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '警告',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        content: const Text(
                          '1年以上前の「大会」と「試合データ」をすべて完全に削除します。\nこの操作は元に戻せません。実行しますか？',
                          style: TextStyle(height: 1.5),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text(
                              'キャンセル',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text(
                              '完全に削除する',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      if (!context.mounted) return;
                      showDialog(
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
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '削除',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる', style: TextStyle(color: Colors.grey)),
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
    final primaryColor = isDark ? Colors.purpleAccent : Colors.purple.shade700;

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
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.only(
              top: 16,
              left: 24,
              right: 24,
              bottom: 24,
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
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'チーム名の管理',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: 20,
                  ),
                ),
                const Text(
                  '試合作成時にボタンで選べる「自チーム名」を登録します。',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // 入力エリア
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: '例：〇〇剣友会A',
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('追加'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // リスト表示
                Flexible(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final names = ref.watch(teamNameHistoryProvider);

                      if (names.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              '登録されたチーム名はありません',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
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
                              : Colors.grey.shade50,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              names[index],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
                                      color: Colors.redAccent,
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
