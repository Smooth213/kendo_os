import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import '../providers/team_name_history_provider.dart'; // ★ 追加：履歴プロバイダ
import 'package:kendo_os/shared/utils/text_sanitizer.dart'; // ★ お掃除フィルターを追加
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

// ★ 安定したProvider定義
final registeredTeamsProvider = StreamProvider.family
    .autoDispose<List<TeamModel>, String>((ref, tournamentId) {
      return ref
          .watch(teamRepositoryProvider)
          .watchTeamsByTournament(tournamentId);
    });

final playerListProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).getPlayers();
});

// ★ 追加：登録した「よく使う自チーム名」をマスタから取得するプロバイダー
final customTeamNamesProvider = StreamProvider.autoDispose<List<String>>((ref) {
  return ref.watch(playerRepositoryProvider).watchCustomTeamNames();
});

class TeamRegistrationScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const TeamRegistrationScreen({super.key, required this.tournamentId});

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

  // ★ 修正：最終的なカテゴリ名を生成。マスタ画面の判定と文字列を100%一致させる
  String get _selectedCategory {
    if (_selectedMajorCategory == '初心者') {
      return '初心者の部';
    }
    if (_selectedMajorCategory == '幼年') {
      return '幼年の部';
    }
    if (_selectedMinorCategory == '全体') {
      return '$_selectedMajorCategoryの部';
    }
    if (_selectedMajorCategory == '大学・一般') {
      return '$_selectedMinorCategoryの部';
    }
    return '$_selectedMajorCategory$_selectedMinorCategoryの部';
  }

  // ★ 修正：編集時に文字列からUI状態を復元するロジック
  void _parseCategoryToState(String categoryName) {
    if (categoryName == '初心者の部') {
      _selectedMajorCategory = '初心者';
      _selectedMinorCategory = '全体';
      return;
    }
    if (categoryName == '幼年の部') {
      _selectedMajorCategory = '幼年';
      _selectedMinorCategory = '全体';
      return;
    }
    final cleanCat = categoryName.replaceAll('の部', '');
    if (['大学生', '一般', 'シニア'].contains(cleanCat)) {
      _selectedMajorCategory = '大学・一般';
      _selectedMinorCategory = cleanCat;
      return;
    }
    for (var major in ['幼年', '小学生', '中学生', '高校生']) {
      if (cleanCat.startsWith(major)) {
        _selectedMajorCategory = major;
        final minor = cleanCat.substring(major.length);
        _selectedMinorCategory = minor.isEmpty ? '全体' : minor;
        return;
      }
    }
  }

  bool _showExtraMajorCategories = false;
  bool _showExtraMatchTypes = false;
  String _matchType = '団体戦（5人制）';
  String? _editingTeamId;

  int _substituteCount = 0;

  final _teamNameController = TextEditingController();
  final FocusNode _teamNameFocusNode = FocusNode(); // ★ 追加：フォーカス状態を永続化

  final Map<int, String> _tempSelectedPlayers = {};

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _teamNameController.dispose();
    _teamNameFocusNode.dispose(); // ★ 追加：メモリリーク防止
    _pageController.dispose();
    super.dispose();
  }

  // ★ AppBar
  Widget _buildImmersiveAppBar(BuildContext context) {
    return TeamRegistrationAppBar(onBack: () => Navigator.pop(context));
  }

  // ★ Tealグラデーションヘッダー
  Widget _buildDynamicHeader() {
    return TeamRegistrationDynamicHeader(
      currentPage: _currentPage,
      themeColors: _themeColors,
    );
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

    int basePlayerCount = 5;
    List<String> posNames = ['先鋒', '次鋒', '中堅', '副将', '大将'];
    if (_matchType.contains('3人制')) {
      basePlayerCount = 3;
      posNames = ['先鋒', '中堅', '大将'];
    } else if (_matchType.contains('個人戦')) {
      basePlayerCount = 1;
      posNames = ['選手'];
    } else if (_matchType.contains('7人制')) {
      basePlayerCount = 7;
      posNames = ['先鋒', '次鋒', '五将', '中堅', '三将', '副将', '大将'];
    }

    // ★ 新機能：ベースの人数に補欠の人数を足す
    int totalPlayerCount = basePlayerCount + _substituteCount;
    for (int i = 0; i < _substituteCount; i++) {
      posNames.add('補欠'); // 役職名として「補欠」を追加
    }

    // ★ Phase 8-3: キーボードが開いているかを検知
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        // ★ 修正：標準の AppBar は使用せず、body 内のコンポーネントでヘッダーを構築（大会作成画面と統一）
        body: SafeArea(
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
                          _buildImmersiveAppBar(context),
                          _buildDynamicHeader(),
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
                    _buildPage3Confirm(registeredTeamsAsync, totalPlayerCount),
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
          ), // Column
        ), // SafeArea
      ), // Scaffold
    ); // LiquidBackground
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
        setState(() {
          _editingTeamId = t.id;
          _parseCategoryToState(t.category);
          _matchType = t.matchType;
          _teamNameController.text = t.teamName;
          _tempSelectedPlayers.clear();
          for (int i = 0; i < t.playerNames.length; i++) {
            _tempSelectedPlayers[i] = t.playerNames[i];
          }
          int baseLen = 5;
          if (t.matchType.contains('3人制')) {
            baseLen = 3;
          } else if (t.matchType.contains('個人戦')) {
            baseLen = 1;
          } else if (t.matchType.contains('7人制')) {
            baseLen = 7;
          }
          _substituteCount = (t.playerNames.length - baseLen).clamp(0, 4);
          _currentPage = 0;
        });
        _pageController.jumpToPage(0);
      },
      onDeleteTeam: (teamId) =>
          ref.read(teamRepositoryProvider).deleteTeam(teamId),
    );
  }

  Widget _buildStickyBottomAction(int playerCount) {
    return TeamRegistrationStickyBottomBar(
      currentPage: _currentPage,
      editingTeamId: _editingTeamId,
      themeColors: _themeColors,
      onPrevious: () => _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
      onPrimaryAction: () async {
        if (_currentPage == 2) {
          if (_teamNameController.text.isEmpty) {
            AppSnackBar.showError(context, 'チーム名を入力してください');
            return;
          }
          final cleanTeamName = TextSanitizer.clean(_teamNameController.text);
          final team = TeamModel(
            id: _editingTeamId ?? '',
            tournamentId: widget.tournamentId,
            category: _selectedCategory,
            teamName: cleanTeamName,
            matchType: _matchType,
            playerNames: List.generate(
              playerCount,
              (i) => _tempSelectedPlayers[i] ?? '',
            ),
          );
          await ref.read(teamRepositoryProvider).saveTeam(team);

          ref
              .read(teamNameHistoryProvider.notifier)
              .addHistory(_teamNameController.text);

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
            final cleanTeamName = TextSanitizer.clean(_teamNameController.text);
            await ref
                .read(teamRepositoryProvider)
                .saveTeam(
                  TeamModel(
                    id: _editingTeamId ?? '',
                    tournamentId: widget.tournamentId,
                    category: _selectedCategory,
                    teamName: cleanTeamName,
                    matchType: _matchType,
                    playerNames: List.generate(
                      playerCount,
                      (i) => _tempSelectedPlayers[i] ?? '',
                    ),
                  ),
                );
            ref
                .read(teamNameHistoryProvider.notifier)
                .addHistory(_teamNameController.text.trim());
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
