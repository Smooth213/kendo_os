import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_parser.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_player_select_bottom_sheet.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_edit_basic_fields.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_edit_order_list.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

/// 🥋 チーム登録: チーム情報・オーダー編集ボトムシート
class TeamEditBottomSheet extends ConsumerStatefulWidget {
  final TeamModel team;
  final List<PlayerModel> players;
  final Future<void> Function(TeamModel updatedTeam) onSave;

  const TeamEditBottomSheet({
    super.key,
    required this.team,
    required this.players,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required TeamModel team,
    required List<PlayerModel> players,
    required Future<void> Function(TeamModel updatedTeam) onSave,
  }) {
    return showAppBottomSheet<void>(
      context: context,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      builder: (ctx) =>
          TeamEditBottomSheet(team: team, players: players, onSave: onSave),
    );
  }

  @override
  ConsumerState<TeamEditBottomSheet> createState() =>
      _TeamEditBottomSheetState();
}

class _TeamEditBottomSheetState extends ConsumerState<TeamEditBottomSheet> {
  late final TextEditingController _teamNameController;
  late String _selectedCategory;
  late String _matchType;
  late final Map<int, String> _tempSelectedPlayers;
  late int _substituteCount;
  late List<String> _slotIds;
  bool _isSaving = false;

  final List<String> _candidateCategories = [
    '小学生低学年',
    '小学生高学年',
    '小学生',
    '中学生',
    '中学生男子',
    '中学生女子',
    '高校生',
    '一般',
  ];

  final List<String> _matchTypes = ['団体戦（3人制）', '団体戦（5人制）', '団体戦（7人制）', '個人戦'];

  @override
  void initState() {
    super.initState();
    _teamNameController = TextEditingController(text: widget.team.teamName);
    _selectedCategory = widget.team.category.trim().isNotEmpty
        ? widget.team.category.trim()
        : '小学生の部';
    _matchType = widget.team.matchType.trim().isNotEmpty
        ? widget.team.matchType.trim()
        : '団体戦（5人制）';

    _tempSelectedPlayers = {};
    for (int i = 0; i < widget.team.playerNames.length; i++) {
      final name = widget.team.playerNames[i];
      if (name.isNotEmpty) {
        _tempSelectedPlayers[i] = name;
      }
    }

    final baseLen = _getBasePlayerCount(_matchType);
    _substituteCount = (widget.team.playerNames.length - baseLen).clamp(0, 4);
    final totalCount = baseLen + _substituteCount;
    _slotIds = List.generate(
      totalCount,
      (i) => 'slot_${DateTime.now().microsecondsSinceEpoch}_$i',
    );
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  int _getBasePlayerCount(String matchType) {
    if (matchType.contains('3人制')) return 3;
    if (matchType.contains('個人戦')) return 1;
    if (matchType.contains('7人制')) return 7;
    return 5;
  }

  List<String> _getPosNames(String matchType, int substituteCount) {
    List<String> base;
    if (matchType.contains('3人制')) {
      base = ['先鋒', '中堅', '大将'];
    } else if (matchType.contains('個人戦')) {
      base = ['選手'];
    } else if (matchType.contains('7人制')) {
      base = ['先鋒', '次鋒', '五将', '中堅', '三将', '副将', '大将'];
    } else {
      base = ['先鋒', '次鋒', '中堅', '副将', '大将'];
    }
    for (int i = 0; i < substituteCount; i++) {
      base.add('補欠');
    }
    return base;
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      if (oldIndex == newIndex) return;

      final baseLen = _getBasePlayerCount(_matchType);
      final totalCount = baseLen + _substituteCount;

      // slotIds の並び替え
      if (oldIndex < _slotIds.length && newIndex < _slotIds.length) {
        final movedSlotId = _slotIds.removeAt(oldIndex);
        _slotIds.insert(newIndex, movedSlotId);
      }

      // 選手割り当ての並び替え
      final currentPlayers = List<String?>.generate(
        totalCount,
        (i) => _tempSelectedPlayers[i],
      );
      final movedPlayer = currentPlayers.removeAt(oldIndex);
      currentPlayers.insert(newIndex, movedPlayer);

      _tempSelectedPlayers.clear();
      for (int i = 0; i < currentPlayers.length; i++) {
        final p = currentPlayers[i];
        if (p != null && p.isNotEmpty) {
          _tempSelectedPlayers[i] = p;
        }
      }
    });
  }

  Future<void> _handleSelectPlayer(
    int index,
    List<String> posNames,
    AppThemeColors themeColors,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final categoryParsed = TeamRegistrationCategoryParser.parseCategoryToState(
      _selectedCategory,
    );

    final selected = await TeamRegistrationPlayerSelectBottomSheet.show(
      context: context,
      index: index,
      players: widget.players,
      posNames: posNames,
      tempSelectedPlayers: _tempSelectedPlayers,
      selectedMajorCategory: categoryParsed.majorCategory,
      selectedMinorCategory: categoryParsed.minorCategory,
      themeColors: themeColors,
    );

    if (!mounted) return;

    if (selected == 'CLEAR_FLAG') {
      setState(() => _tempSelectedPlayers.remove(index));
    } else if (selected != null && selected.trim().isNotEmpty) {
      setState(() {
        int existingIndex = -1;
        _tempSelectedPlayers.forEach((key, value) {
          if (value == selected) existingIndex = key;
        });

        if (existingIndex != -1 && existingIndex != index) {
          final currentOccupant = _tempSelectedPlayers[index];
          if (currentOccupant != null) {
            _tempSelectedPlayers[existingIndex] = currentOccupant;
          } else {
            _tempSelectedPlayers.remove(existingIndex);
          }
        }
        _tempSelectedPlayers[index] = selected;
      });
    }
  }

  Future<void> _handleSave() async {
    final name = _teamNameController.text.trim();
    if (name.isEmpty) {
      AppSnackBar.showError(context, 'チーム名を入力してください');
      return;
    }

    final baseLen = _getBasePlayerCount(_matchType);
    final totalCount = baseLen + _substituteCount;
    final List<String> playerNames = List.generate(
      totalCount,
      (i) => _tempSelectedPlayers[i] ?? '',
    );

    setState(() => _isSaving = true);
    try {
      final updated = widget.team.copyWith(
        teamName: name,
        category: _selectedCategory,
        matchType: _matchType,
        playerNames: playerNames,
      );

      await widget.onSave(updated);

      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.showSuccess(context, '「$name」の変更を保存しました');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.showError(context, '保存に失敗しました: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final accentColor = themeColors.primaryAccent;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;
    final inputBgColor = themeColors.cardBackground;

    final baseCount = _getBasePlayerCount(_matchType);
    final totalCount = baseCount + _substituteCount;
    final posNames = _getPosNames(_matchType, _substituteCount);

    return AppBottomSheetContent(
      title: 'チームとオーダーの編集',
      titleIcon: Icons.edit_note,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              children: [
                TeamEditBasicFields(
                  teamNameController: _teamNameController,
                  selectedCategory: _selectedCategory,
                  matchType: _matchType,
                  candidateCategories: _candidateCategories,
                  matchTypes: _matchTypes,
                  themeColors: themeColors,
                  borderColor: borderColor,
                  onCategoryChanged: (cat) =>
                      setState(() => _selectedCategory = cat),
                  onMatchTypeChanged: (type) {
                    setState(() {
                      _matchType = type;
                      _substituteCount = 0;
                      final baseLen = _getBasePlayerCount(type);
                      _slotIds = List.generate(
                        baseLen,
                        (i) =>
                            'slot_${DateTime.now().microsecondsSinceEpoch}_$i',
                      );
                    });
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // 4. オーダー編成
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'オーダー編成',
                        style: TextStyle(
                          fontSize: AppFontSize.subhead,
                          fontWeight: AppFontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                    if (_substituteCount < 4)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _substituteCount++;
                          _slotIds.add(
                            'slot_${DateTime.now().microsecondsSinceEpoch}_${_slotIds.length}',
                          );
                        }),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('補欠を追加'),
                        style: TextButton.styleFrom(
                          foregroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                TeamEditOrderList(
                  totalCount: totalCount,
                  baseCount: baseCount,
                  posNames: posNames,
                  tempSelectedPlayers: _tempSelectedPlayers,
                  slotKeys: _slotIds,
                  themeColors: themeColors,
                  borderColor: borderColor,
                  inputBgColor: inputBgColor,
                  onSelectPlayer: (index) =>
                      _handleSelectPlayer(index, posNames, themeColors),
                  onClearPlayer: (index) =>
                      setState(() => _tempSelectedPlayers.remove(index)),
                  onRemoveSubstitute: (index) {
                    setState(() {
                      for (int i = index; i < totalCount - 1; i++) {
                        if (_tempSelectedPlayers.containsKey(i + 1)) {
                          _tempSelectedPlayers[i] =
                              _tempSelectedPlayers[i + 1]!;
                        } else {
                          _tempSelectedPlayers.remove(i);
                        }
                      }
                      _tempSelectedPlayers.remove(totalCount - 1);
                      if (index < _slotIds.length) {
                        _slotIds.removeAt(index);
                      }
                      _substituteCount--;
                    });
                  },
                  onReorder: _handleReorder,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),

          // 保存ボタン（最下部固定）
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              top: AppSpacing.md,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: themeColors.cardBackground,
              border: Border(top: BorderSide(color: borderColor, width: 0.5)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: GlassButton(
                onPressed: _isSaving ? () {} : _handleSave,
                color: accentColor,
                icon: _isSaving ? null : Icons.check_circle_outline,
                label: _isSaving ? '保存中...' : '変更を保存する',
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                expandContent: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
