import 'package:kendo_os/shared/theme/app_tokens.dart';
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
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_dynamic_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_app_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_autocomplete_field.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_player_select_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final inputBgColor = themeColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          'チーム名とオーダーを\n入力してください',
          style: TextStyle(
            fontSize: AppFontSize.display,
            fontWeight: AppFontWeight.bold,
            height: 1.4,
            color: textColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // ★ 修正：通常のTextFieldと履歴チップを廃止し、マスタ連動のサジェスト入力に統合！
        _buildTeamAutocomplete(
          controller: _teamNameController,
          focusNode: _teamNameFocusNode, // ★ 追加：永続化したFocusNodeを渡す
          suggestions: ref.watch(customTeamNamesProvider).value ?? [],
          labelText: 'チーム名 (例: 〇〇剣友会A)',
          hintText: 'タップして登録済みリストから選択',
          fillColor: inputBgColor,
          borderColor: borderColor,
          textColor: textColor,
          subTextColor: _themeColors.primaryAccent,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.xxl),
        _buildSectionTitle('オーダー編成（タップして選択）'),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: inputBgColor,
            borderRadius: AppRadius.medium,
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: AppKendoColors.transparent,
            child: Column(
              children: List.generate(playerCount, (index) {
                // ★ 補欠かどうかの判定
                final bool isSubstitute =
                    index >= (playerCount - _substituteCount);

                return Column(
                  children: [
                    ListTile(
                      // ★ 真の解決：ダイアログ終了後に自動でフォーカスが戻ってサジェストが暴発する「ゴーストフォーカス」を完全に殺す
                      onTap: () async {
                        FocusManager.instance.primaryFocus?.unfocus(); // 開く前に殺す
                        await _selectPlayerDialog(index, players, posNames);
                        if (!mounted) return;
                        FocusManager.instance.primaryFocus
                            ?.unfocus(); // 閉じた直後に確実にもう一度殺す
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: AppSpacing.md,
                      ),
                      leading: CircleAvatar(
                        radius: 22,
                        // 補欠枠は少し色を変えて差別化
                        backgroundColor: isSubstitute
                            ? (isDark
                                  ? const Color(
                                      0xFFFF9800,
                                    ).withValues(alpha: 0.3)
                                  : const Color(0xFFFF9800))
                            : _themeColors.softAccent,
                        child: Text(
                          isSubstitute ? '補' : posNames[index].substring(0, 1),
                          style: TextStyle(
                            color: isSubstitute
                                ? (isDark
                                      ? const Color(0xFFFF9800)
                                      : const Color(0xFFFF9800))
                                : _themeColors.primaryAccent,
                            fontWeight: AppFontWeight.bold,
                            fontSize: AppFontSize.subhead,
                          ),
                        ),
                      ),
                      title: Text(
                        _tempSelectedPlayers[index] ?? '未選択',
                        style: TextStyle(
                          fontSize: AppFontSize.headline,
                          fontWeight: AppFontWeight.bold,
                          color: _tempSelectedPlayers[index] == null
                              ? (isDark
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0x8A000000))
                              : textColor,
                        ),
                      ),
                      subtitle: Text(
                        posNames[index],
                        style: TextStyle(
                          color: isSubstitute
                              ? const Color(0xFFFF9800)
                              : _themeColors.primaryAccent,
                          fontSize: AppFontSize.small,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      // 補欠行には「削除」ボタンを表示
                      trailing: isSubstitute
                          ? IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: AppKendoColors.redAccent,
                              ),
                              tooltip: 'この補欠枠を削除',
                              onPressed: () {
                                setState(() {
                                  // ★ 削除時の詰め処理を汎用化（MAX4名など複数対応）
                                  for (
                                    int i = index;
                                    i < playerCount - 1;
                                    i++
                                  ) {
                                    if (_tempSelectedPlayers.containsKey(
                                      i + 1,
                                    )) {
                                      _tempSelectedPlayers[i] =
                                          _tempSelectedPlayers[i + 1]!;
                                    } else {
                                      _tempSelectedPlayers.remove(i);
                                    }
                                  }
                                  // 一番後ろの枠を消去
                                  _tempSelectedPlayers.remove(playerCount - 1);
                                  _substituteCount--;
                                });
                              },
                            )
                          : const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppKendoColors.grey,
                            ),
                    ),
                    if (index < playerCount - 1)
                      Divider(
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                        color: isDark
                            ? const Color(0xFF38383A)
                            : const Color(0xFFF2F2F7),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),

        // ★ 上限を4名に変更
        if (_substituteCount < 4 && !_matchType.contains('個人戦')) ...[
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _substituteCount++),
              icon: Icon(
                Icons.person_add_alt_1,
                color: _themeColors.primaryAccent,
                size: 18,
              ),
              // ★ ラベルも 4 に変更
              label: Text(
                '補欠を追加 ($_substituteCount/4)',
                style: TextStyle(
                  color: _themeColors.primaryAccent,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF38383A)
                      : _themeColors.primaryAccent.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                backgroundColor: isDark
                    ? const Color(0xFF1C1C1E)
                    : _themeColors.softAccent,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPage3Confirm(
    AsyncValue<List<TeamModel>> registeredTeamsAsync,
    int playerCount,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final inputBgColor = themeColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(
          '登録内容の確認と\n登録済みの一覧です',
          style: TextStyle(
            fontSize: AppFontSize.titleLarge,
            fontWeight: AppFontWeight.bold,
            height: 1.4,
            color: textColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _buildSectionTitle('今回登録するチームのプレビュー'),
        Card(
          elevation: 0,
          color: inputBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.large,
            side: BorderSide(color: _themeColors.primaryAccent, width: 2),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppSpacing.lg),
            title: Text(
              '$_selectedCategory : ${_teamNameController.text.isEmpty ? "(チーム名未入力)" : _teamNameController.text}',
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.subhead,
                color: textColor,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                '$_matchType\n選手: ${List.generate(playerCount, (i) => _tempSelectedPlayers[i] ?? '').where((n) => n.isNotEmpty).join(", ")}',
                style: TextStyle(
                  height: 1.5,
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xDE000000),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _buildSectionTitle('現在の登録済み一覧'),
        registeredTeamsAsync.when(
          data: (teams) {
            if (teams.isEmpty) {
              return const Text(
                'まだ登録されたチームはありません',
                style: TextStyle(color: AppKendoColors.grey),
              );
            }
            return Column(
              children: teams
                  .map(
                    (t) => Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      elevation: 0,
                      color: inputBgColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.large,
                        side: BorderSide(color: borderColor),
                      ),
                      child: ListTile(
                        title: Text(
                          '${t.category} : ${t.teamName}',
                          style: TextStyle(
                            fontWeight: AppFontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        subtitle: Text(
                          '${t.matchType} / 選手: ${t.playerNames.where((n) => n.isNotEmpty).join(", ")}',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFFFFFFF)
                                : const Color(0x8A000000),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: _themeColors.primaryAccent,
                              ),
                              onPressed: () {
                                setState(() {
                                  _editingTeamId = t.id;
                                  _parseCategoryToState(
                                    t.category,
                                  ); // ★ 修正：逆算して大分類と小分類を美しく復元
                                  _matchType = t.matchType;
                                  _teamNameController.text = t.teamName;
                                  _tempSelectedPlayers.clear();
                                  for (
                                    int i = 0;
                                    i < t.playerNames.length;
                                    i++
                                  ) {
                                    _tempSelectedPlayers[i] = t.playerNames[i];
                                  }

                                  // ★ 編集時に補欠の人数を逆算して復元する（上限4へ変更）
                                  int baseLen = 5;
                                  if (t.matchType.contains('3人制')) {
                                    baseLen = 3;
                                  } else if (t.matchType.contains('個人戦')) {
                                    baseLen = 1;
                                  } else if (t.matchType.contains('7人制')) {
                                    baseLen = 7;
                                  }
                                  _substituteCount =
                                      (t.playerNames.length - baseLen).clamp(
                                        0,
                                        4,
                                      );

                                  _currentPage = 0;
                                });
                                _pageController.jumpToPage(0);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AppKendoColors.red,
                              ),
                              onPressed: () => ref
                                  .read(teamRepositoryProvider)
                                  .deleteTeam(t.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('エラー: $e'),
        ),
      ],
    );
  }

  Widget _buildStickyBottomAction(int playerCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;
    final bottomColor = enableLiquidGlass
        ? Colors.transparent
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF));
    final borderColor = enableLiquidGlass
        ? Colors.transparent
        : (isDark ? const Color(0xFF38383A) : const Color(0x33000000));

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bottomColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (_currentPage > 0)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  child: OutlinedButton(
                    onPressed: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      shape: const CircleBorder(),
                      side: BorderSide(color: borderColor),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: _themeColors.primaryAccent,
                    ),
                  ),
                ),
              Expanded(
                child: GlassButton(
                  onPressed: () async {
                    if (_currentPage == 2) {
                      if (_teamNameController.text.isEmpty) {
                        AppSnackBar.showError(context, 'チーム名を入力してください');
                        return;
                      }
                      final cleanTeamName = TextSanitizer.clean(
                        _teamNameController.text,
                      );
                      final team = TeamModel(
                        id: _editingTeamId ?? '',
                        tournamentId: widget.tournamentId,
                        category: _selectedCategory,
                        teamName: cleanTeamName,
                        matchType: _matchType,
                        playerNames: List.generate(
                          playerCount,
                          (i) => _tempSelectedPlayers[i] ?? '',
                        ), // ★ 補欠も含めて保存！
                      );
                      await ref.read(teamRepositoryProvider).saveTeam(team);

                      // ★ 履歴に保存
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
                      if (_currentPage == 1 &&
                          _teamNameController.text.isEmpty) {
                        AppSnackBar.showError(context, 'チーム名を入力してください');
                        return;
                      }
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  color: _themeColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  label: _currentPage == 2
                      ? (_editingTeamId != null ? '変更を保存' : '登録して続けて追加')
                      : '次へ進む',
                  icon: _currentPage == 2
                      ? (_editingTeamId != null ? Icons.save : Icons.add_task)
                      : null,
                  expandContent: false,
                ),
              ),
            ],
          ),
          if (_currentPage == 2) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                onPressed: () async {
                  // ★ 自動保存機能
                  if (_teamNameController.text.trim().isNotEmpty) {
                    try {
                      final cleanTeamName = TextSanitizer.clean(
                        _teamNameController.text,
                      );
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
                      // ★ 履歴に保存
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
                color: _themeColors.primaryAccent,
                icon: Icons.navigate_next,
                label: '登録を完了してルール設定へ',
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                expandContent: false,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppFontSize.subhead,
          fontWeight: AppFontWeight.bold,
          color: _themeColors.primaryAccent,
        ),
      ),
    );
  }

  // ★ 予測変換（サジェスト）と手入力を両立する入力フィールド
  Widget _buildTeamAutocomplete({
    required TextEditingController controller,
    required FocusNode focusNode,
    required List<String> suggestions,
    required String labelText,
    required String hintText,
    required Color fillColor,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
    required bool isDark,
  }) {
    return TeamRegistrationAutocompleteField(
      controller: controller,
      focusNode: focusNode,
      suggestions: suggestions,
      labelText: labelText,
      hintText: hintText,
      fillColor: fillColor,
      borderColor: borderColor,
      textColor: textColor,
      subTextColor: subTextColor,
      isDark: isDark,
    );
  }
}
