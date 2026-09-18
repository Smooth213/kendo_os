import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart'
    hide registeredTeamsProvider;
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_dynamic_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_app_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_player_select_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_order_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_confirm_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_sticky_bottom_bar.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_edit_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_parser.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_save_helper.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_program_dock_button.dart';

import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_providers.dart';
export 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_providers.dart';

class TeamRegistrationScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final int? initialPage;
  const TeamRegistrationScreen({
    super.key,
    required this.tournamentId,
    this.initialPage,
  });

  @override
  ConsumerState<TeamRegistrationScreen> createState() =>
      _TeamRegistrationScreenState();
}

class _TeamRegistrationScreenState
    extends ConsumerState<TeamRegistrationScreen> {
  late AppThemeColors _themeColors;
  // ★ 修正：2段階選択用の状態（初期値を「小学生」に）
  String _selectedMajorCategory = '小学生';
  String _selectedMinorCategory = '低学年';

  String get _selectedCategory =>
      TeamRegistrationCategoryParser.formatCategoryName(
        majorCategory: _selectedMajorCategory,
        minorCategory: _selectedMinorCategory,
      );

  bool _showExtraMajorCategories = false;
  bool _showExtraMatchTypes = false;
  String _matchType = '団体戦（5人制）';
  String? _editingTeamId;

  int _substituteCount = 0;

  final _teamNameController = TextEditingController();
  final FocusNode _teamNameFocusNode = FocusNode(); // ★ 追加：フォーカス状態を永続化

  final Map<int, String> _tempSelectedPlayers = {};

  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage ?? 0;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _teamNameFocusNode.dispose(); // ★ 追加：メモリリーク防止
    _pageController.dispose();
    super.dispose();
  }

  // ★ 修正：カテゴリ連動フィルタリング ＋ よみがな順ソートを搭載した選択ダイアログ
  Future<void> _selectPlayerDialog(
    int index,
    List<PlayerModel> players,
    List<String> posNames,
  ) async {
    final selected = await TeamRegistrationPlayerSelectBottomSheet.show(
      context: context,
      index: index,
      players: players,
      posNames: posNames,
      tempSelectedPlayers: _tempSelectedPlayers,
      selectedMajorCategory: _selectedMajorCategory,
      selectedMinorCategory: _selectedMinorCategory,
      themeColors: _themeColors,
    );

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final playerListAsync = ref.watch(playerListProvider);
    final registeredTeamsAsync = ref.watch(
      registeredTeamsProvider(widget.tournamentId),
    );

    final (basePlayerCount, basePosNames) = switch (_matchType) {
      final t when t.contains('3人制') => (3, ['先鋒', '中堅', '大将']),
      final t when t.contains('個人戦') => (1, ['選手']),
      final t when t.contains('7人制') => (
        7,
        ['先鋒', '次鋒', '五将', '中堅', '三将', '副将', '大将'],
      ),
      _ => (5, ['先鋒', '次鋒', '中堅', '副将', '大将']),
    };
    final posNames = [...basePosNames, ...List.filled(_substituteCount, '補欠')];
    final totalPlayerCount = basePlayerCount + _substituteCount;

    // ★ Phase 8-3: キーボードが開いているかを検知
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        // ★ 修正：標準の AppBar は使用せず、body 内のコンポーネントでヘッダーを構築（大会作成画面と統一）
        body: Stack(
          children: [
            SafeArea(
              bottom: false, // 下部は StickyBottomAction があるため SafeArea から外す
              child: Column(
                children: [
                  // ★ キーボードが開いた時はヘッダーをスッと隠し、入力エリアを最大化する
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: isKeyboardOpen
                        ? const SizedBox.shrink()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TeamRegistrationAppBar(
                                onBack: () => Navigator.pop(context),
                                registeredTeamCount:
                                    registeredTeamsAsync.value?.length ?? 0,
                                editingTeamName: _editingTeamId != null
                                    ? _teamNameController.text
                                    : null,
                                onViewRegisteredTeams: () {
                                  setState(() => _currentPage = 2);
                                  _pageController.jumpToPage(2);
                                },
                              ),
                              TeamRegistrationDynamicHeader(
                                currentPage: _currentPage,
                                themeColors: _themeColors,
                              ),
                            ],
                          ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      children: [
                        TeamRegistrationCategoryStep(
                          selectedMajorCategory: _selectedMajorCategory,
                          selectedMinorCategory: _selectedMinorCategory,
                          selectedCategory: _selectedCategory,
                          matchType: _matchType,
                          showExtraMajorCategories: _showExtraMajorCategories,
                          showExtraMatchTypes: _showExtraMatchTypes,
                          themeColors: _themeColors,
                          onMajorCategoryChanged: (cat) => setState(() {
                            _selectedMajorCategory = cat;
                            _selectedMinorCategory = '全体';
                          }),
                          onMinorCategoryChanged: (cat) => setState(() {
                            _selectedMinorCategory = cat;
                          }),
                          onMatchTypeChanged: (type) => setState(() {
                            _matchType = type;
                            _tempSelectedPlayers.clear();
                            _substituteCount = 0;
                          }),
                          onToggleExtraMajorCategories: () => setState(
                            () => _showExtraMajorCategories =
                                !_showExtraMajorCategories,
                          ),
                          onToggleExtraMatchTypes: () => setState(
                            () => _showExtraMatchTypes = !_showExtraMatchTypes,
                          ),
                        ),
                        playerListAsync.when(
                          data: (players) => _buildPage2TeamAndOrder(
                            totalPlayerCount,
                            posNames,
                            players,
                          ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, s) => Center(child: Text('エラー: $e')),
                        ),
                        _buildPage3Confirm(
                          registeredTeamsAsync,
                          totalPlayerCount,
                        ),
                      ],
                    ),
                  ),
                  // ★ キーボードが開いた時は下のボタンも隠し、画面を押し潰さないようにする
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: isKeyboardOpen
                        ? const SizedBox.shrink()
                        : _buildStickyBottomAction(totalPlayerCount),
                  ),
                ],
              ),
            ),
            FloatingProgramDockButton(tournamentId: widget.tournamentId),
          ],
        ),
      ),
    );
  }

  // ===== ウィザード構成部品 =====

  Widget _buildPage2TeamAndOrder(
    int playerCount,
    List<String> posNames,
    List<PlayerModel> players,
  ) {
    return TeamRegistrationOrderStep(
      playerCount: playerCount,
      posNames: posNames,
      players: players,
      teamNameController: _teamNameController,
      teamNameFocusNode: _teamNameFocusNode,
      teamNameSuggestions: ref.watch(customTeamNamesProvider).value ?? [],
      tempSelectedPlayers: _tempSelectedPlayers,
      substituteCount: _substituteCount,
      matchType: _matchType,
      themeColors: _themeColors,
      onSelectPlayer: (index) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await _selectPlayerDialog(index, players, posNames);
        if (!mounted) return;
        FocusManager.instance.primaryFocus?.unfocus();
      },
      onRemoveSubstitute: (index) {
        setState(() {
          for (int i = index; i < playerCount - 1; i++) {
            if (_tempSelectedPlayers.containsKey(i + 1)) {
              _tempSelectedPlayers[i] = _tempSelectedPlayers[i + 1]!;
            } else {
              _tempSelectedPlayers.remove(i);
            }
          }
          _tempSelectedPlayers.remove(playerCount - 1);
          _substituteCount--;
        });
      },
      onAddSubstitute: () => setState(() => _substituteCount++),
    );
  }

  Widget _buildPage3Confirm(
    AsyncValue<List<TeamModel>> registeredTeamsAsync,
    int playerCount,
  ) {
    return TeamRegistrationConfirmStep(
      registeredTeamsAsync: registeredTeamsAsync,
      playerCount: playerCount,
      selectedCategory: _selectedCategory,
      teamName: _teamNameController.text,
      matchType: _matchType,
      tempSelectedPlayers: _tempSelectedPlayers,
      themeColors: _themeColors,
      onEditTeam: (t) {
        final players = ref.read(playerListProvider).value ?? <PlayerModel>[];
        TeamEditBottomSheet.show(
          context: context,
          team: t,
          players: players,
          onSave: (updatedTeam) async {
            await ref.read(teamRepositoryProvider).saveTeam(updatedTeam);
          },
        );
      },
      onUpdateCategory: (team, newCategory) async {
        try {
          final updated = team.copyWith(category: newCategory);
          await ref.read(teamRepositoryProvider).saveTeam(updated);
          if (mounted) {
            AppSnackBar.showSuccess(
              context,
              '「${team.teamName}」を「$newCategory」に変更しました',
            );
          }
        } catch (e) {
          if (mounted) {
            AppSnackBar.showError(context, 'カテゴリ変更エラー: $e');
          }
        }
      },
      onDeleteTeam: (teamId) =>
          ref.read(teamRepositoryProvider).deleteTeam(teamId),
      onAddNewTeam: () {
        setState(() {
          _editingTeamId = null;
          _teamNameController.clear();
          _tempSelectedPlayers.clear();
          _substituteCount = 0;
          _currentPage = 0;
        });
        _pageController.jumpToPage(0);
      },
    );
  }

  Widget _buildStickyBottomAction(int playerCount) {
    final isInputting =
        _teamNameController.text.trim().isNotEmpty ||
        _tempSelectedPlayers.isNotEmpty;

    return TeamRegistrationStickyBottomBar(
      currentPage: _currentPage,
      editingTeamId: _editingTeamId,
      isInputting: isInputting,
      themeColors: _themeColors,
      onPrevious: () => _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
      onPrimaryAction: () async {
        if (_currentPage == 2) {
          // 未入力かつ非編集状態なら「＋ 新しいチームを追加」として Page 0 に移動
          if (!isInputting && _editingTeamId == null) {
            setState(() {
              _editingTeamId = null;
              _teamNameController.clear();
              _tempSelectedPlayers.clear();
              _substituteCount = 0;
              _currentPage = 0;
            });
            _pageController.jumpToPage(0);
            return;
          }

          if (_teamNameController.text.isEmpty) {
            AppSnackBar.showError(context, 'チーム名を入力してください');
            return;
          }
          await TeamRegistrationSaveHelper.saveTeamWithHistory(
            ref: ref,
            editingTeamId: _editingTeamId,
            tournamentId: widget.tournamentId,
            category: _selectedCategory,
            rawTeamName: _teamNameController.text,
            matchType: _matchType,
            playerCount: playerCount,
            tempSelectedPlayers: _tempSelectedPlayers,
          );

          if (!mounted) return;
          setState(() {
            _editingTeamId = null;
            _teamNameController.clear();
            _tempSelectedPlayers.clear();
            _substituteCount = 0;
            _currentPage = 0;
          });
          _pageController.jumpToPage(0);
          AppSnackBar.showSuccess(context, '登録しました。続けて登録できます。');
        } else {
          if (_currentPage == 1 && _teamNameController.text.isEmpty) {
            AppSnackBar.showError(context, 'チーム名を入力してください');
            return;
          }
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      onFinishToRules: () async {
        if (_teamNameController.text.trim().isNotEmpty) {
          try {
            await TeamRegistrationSaveHelper.saveTeamWithHistory(
              ref: ref,
              editingTeamId: _editingTeamId,
              tournamentId: widget.tournamentId,
              category: _selectedCategory,
              rawTeamName: _teamNameController.text,
              matchType: _matchType,
              playerCount: playerCount,
              tempSelectedPlayers: _tempSelectedPlayers,
            );
          } catch (e) {
            debugPrint('チーム自動保存エラー: $e');
          }
        }

        if (!mounted) return;
        context.go(
          '/tournament/${widget.tournamentId}/category-rules?isFromSetup=true',
        );
      },
    );
  }
}
