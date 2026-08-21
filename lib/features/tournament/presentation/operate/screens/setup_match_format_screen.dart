import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import '../providers/last_used_settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_category_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_dynamic_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_section_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_team_detail_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_sticky_bottom_action.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_sync_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_save_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_form_state.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';

final noteHistoryProvider = StateProvider<List<String>>((ref) {
  return ['1回戦', '2回戦', '準決勝', '決勝', '第1試合', '第2コート'];
});

final playerListProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).getPlayers();
});

class SetupMatchFormatScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const SetupMatchFormatScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<SetupMatchFormatScreen> createState() =>
      _SetupMatchFormatScreenState();
}

class _SetupMatchFormatScreenState
    extends ConsumerState<SetupMatchFormatScreen> {
  late AppThemeColors _themeColors;
  final _state = MatchFormatFormState();

  final _overallTimeController = TextEditingController(text: '30');
  final _winPointController = TextEditingController(text: '0');
  final _lossPointController = TextEditingController(text: '0');
  final _drawPointController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  final _courtController = TextEditingController();

  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _lastCheckedNote = '';

  String get _category => _state.getCategory();

  @override
  void initState() {
    super.initState();
    final last = ref.read(lastUsedSettingsProvider);
    _state.matchType = last['matchType'] ?? '団体戦';

    final (maj, min) = MatchFormatSetupHelper.parseCategoryToState(
      last['category'] ?? '小学生低学年の部',
    );
    _state.selectedMajorCategory = maj;
    _state.selectedMinorCategory = min;
    _state.matchTime = last['matchTime'] ?? 3.0;
    _state.isRunningTime = last['isRunningTime'] ?? false;
    _state.hasExtension = last['hasExtension'] ?? false;
    _state.hasHantei = last['hasHantei'] ?? true;
    _state.isRenseikai = last['isRenseikai'] ?? false;
    _state.kachinukiUnlimitedType = last['kachinukiUnlimitedType'] ?? '大将対大将';
    _state.hasLeagueDaihyo = last['hasLeagueDaihyo'] ?? false;
    _state.renseikaiType = last['renseikaiType'] ?? '一試合制';
    _state.isDaihyoIpponShobu = last['isDaihyoIpponShobu'] ?? true;
    _state.daihyoMatchTime =
        (last['daihyoMatchTime'] as num?)?.toDouble() ?? 0.0;
    _state.daihyoHasExtension = last['daihyoHasExtension'] ?? true;
    _state.daihyoEnchoTime =
        (last['daihyoEnchoTime'] as num?)?.toDouble() ?? 3.0;
    _state.daihyoEnchoCount = last['daihyoEnchoCount'] ?? -2;
    _state.daihyoHasHantei = last['daihyoHasHantei'] ?? false;
    _state.isIpponShobu = last['isIpponShobu'] ?? false;
    _state.ipponLimit = last['ipponLimit'] ?? 2;
    _state.hansokuLimit = last['hansokuLimit'] ?? 2;

    _winPointController.text = (last['winPoint'] ?? 0).toString();
    _lossPointController.text = (last['lossPoint'] ?? 0).toString();
    _drawPointController.text = (last['drawPoint'] ?? 0).toString();

    _noteController.addListener(_onNoteChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategoryRules());
  }

  @override
  void dispose() {
    _noteController.removeListener(_onNoteChanged);
    _noteController.dispose();
    _courtController.dispose();
    _overallTimeController.dispose();
    _winPointController.dispose();
    _lossPointController.dispose();
    _drawPointController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleHeadingPreset(String preset) {
    final current = _courtController.text.trim();
    if (current.isEmpty) {
      setState(() => _courtController.text = preset);
      return;
    }
    final items = current
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (items.contains(preset)) {
      items.remove(preset);
    } else {
      items.add(preset);
    }
    setState(() => _courtController.text = items.join(', '));
  }

  void _showTeamDetailDialog(BuildContext context, TeamModel team) {
    final baseLen = MatchFormatSetupHelper.calculateTeamSize(
      matchType: team.matchType,
      selectedTeamId: null,
      registeredTeams: [],
    );
    final posNames = MatchFormatSetupHelper.generatePositions(baseLen);
    final players = ref.read(playerListProvider).value ?? [];

    MatchFormatTeamDetailDialog.show(
      context: context,
      team: team,
      posNames: posNames,
      themeColors: _themeColors,
      players: players,
      onTeamUpdated: (_) => setState(() {}),
    );
  }

  bool get _isCurrentMatchAdvanced {
    if (_state.manualRoundTypeOverride != null) {
      return _state.manualRoundTypeOverride == 'advanced';
    }
    final tourney = ref
        .read(tournamentProvider(widget.tournamentId))
        .valueOrNull;
    return MatchFormatRuleSyncHelper.isAdvancedMatchName(
      note: _noteController.text,
      categoryName: _category,
      tournament: tourney,
    );
  }

  void _onNoteChanged() {
    final cur = _noteController.text;
    if (cur == _lastCheckedNote || _state.manualRoundTypeOverride != null) {
      return;
    }

    _lastCheckedNote = cur;

    final tourney = ref
        .read(tournamentProvider(widget.tournamentId))
        .valueOrNull;
    if (tourney != null) {
      final ruleSet = tourney.categoryRules[_category];
      if (ruleSet != null && ruleSet.useAdvancedRule) {
        final isAdv = MatchFormatRuleSyncHelper.isAdvancedMatchName(
          note: cur,
          categoryName: _category,
          tournament: tourney,
        );
        _applyRule(isAdv ? ruleSet.advancedRule : ruleSet.normalRule);
      }
    }
  }

  void _loadCategoryRules() {
    final tourney = ref
        .read(tournamentProvider(widget.tournamentId))
        .valueOrNull;
    if (tourney != null) {
      final ruleSet = tourney.categoryRules[_category];
      if (ruleSet != null) {
        final targetScene = MatchFormatRuleSyncHelper.determineInitialScene(
          ruleSet: ruleSet,
          currentScene: _state.selectedRuleScene,
          isAdvanced: _isCurrentMatchAdvanced,
        );
        _applyCategoryRuleScene(targetScene, ruleSet);
      }
    }
  }

  void _applyCategoryRuleScene(String scene, CategoryRuleSet ruleSet) {
    setState(() {
      _state.selectedRuleScene = scene;
      final isRen = scene == 'renseikai' || scene == 'moushiawase';
      final targetRule = MatchFormatRuleSyncHelper.getRuleForScene(
        scene: scene,
        ruleSet: ruleSet,
      );
      _state.isRenseikai = isRen;
      if (isRen) _state.renseikaiType = targetRule.renseikaiType;
      _applyRule(targetRule);
    });
  }

  void _applyRule(MatchRule rule) {
    setState(() {
      _state.applyMatchRule(
        rule,
        overallTimeController: _overallTimeController,
        winPointController: _winPointController,
        lossPointController: _lossPointController,
        drawPointController: _drawPointController,
      );
    });
  }

  void _setManualRoundType(String type) {
    setState(() {
      _state.manualRoundTypeOverride = type;
      ref.read(tournamentProvider(widget.tournamentId)).whenData((tourney) {
        if (tourney != null && tourney.categoryRules.containsKey(_category)) {
          final ruleSet = tourney.categoryRules[_category]!;
          _applyRule(
            type == 'advanced' ? ruleSet.advancedRule : ruleSet.normalRule,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          title: '対戦フォーマット設定',
          backgroundColor:
              ref.watch(settingsProvider.select((s) => s.enableLiquidGlass))
              ? AppKendoColors.transparent
              : _themeColors.cardBackground,
          foregroundColor: _themeColors.textColor,
          actions: const [
            ManualHelpButton(manualPath: 'docs/manuals/operator/settings.md'),
            SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isKeyboardOpen
                  ? const SizedBox.shrink()
                  : MatchFormatDynamicHeader(
                      currentPage: _currentPage,
                      themeColors: _themeColors,
                    ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  MatchFormatCategoryStep(
                    tournamentId: widget.tournamentId,
                    category: _category,
                    selectedMajorCategory: _state.selectedMajorCategory,
                    selectedMinorCategory: _state.selectedMinorCategory,
                    selectedTeamId: _state.selectedTeamId,
                    majorCategories: MatchFormatSetupHelper.majorCategories,
                    getMinorCategories:
                        MatchFormatSetupHelper.getMinorCategories,
                    onCategoryChanged: (major, minor) {
                      setState(() {
                        _state.selectedMajorCategory = major;
                        _state.selectedMinorCategory = minor;
                        _state.selectedTeamId = null;
                        _state.manualRoundTypeOverride = null;
                        _loadCategoryRules();
                      });
                    },
                    onTeamSelected: (team) {
                      setState(() {
                        _state.selectedTeamId = team.id;
                        _state.matchType = team.matchType;
                      });
                    },
                    onAdjustOrder: (team) =>
                        _showTeamDetailDialog(context, team),
                    onNavigateToTeamRegistration: () => context.push(
                      '/team-registration/${widget.tournamentId}',
                    ),
                    themeColors: _themeColors,
                    isDark: isDark,
                    buildSectionTitle: (t) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: AppFontSize.subhead,
                          fontWeight: AppFontWeight.bold,
                          color: _themeColors.primaryAccent,
                        ),
                      ),
                    ),
                  ),
                  MatchFormatRuleStep(
                    tournamentId: widget.tournamentId,
                    category: _category,
                    selectedRuleScene: _state.selectedRuleScene,
                    isCurrentMatchAdvanced: _isCurrentMatchAdvanced,
                    hasExtension: _state.hasExtension,
                    extTime: _state.extTime,
                    extCount: _state.extCount,
                    matchTime: _state.matchTime,
                    isRunningTime: _state.isRunningTime,
                    isRenseikai: _state.isRenseikai,
                    renseikaiType: _state.renseikaiType,
                    matchType: _state.matchType,
                    isIpponShobu: _state.isIpponShobu,
                    ipponLimit: _state.ipponLimit,
                    hansokuLimit: _state.hansokuLimit,
                    hasHantei: _state.hasHantei,
                    kachinukiUnlimitedType: _state.kachinukiUnlimitedType,
                    hasLeagueDaihyo: _state.hasLeagueDaihyo,
                    isDaihyoIpponShobu: _state.isDaihyoIpponShobu,
                    daihyoMatchTime: _state.daihyoMatchTime,
                    daihyoHasExtension: _state.daihyoHasExtension,
                    daihyoEnchoCount: _state.daihyoEnchoCount,
                    daihyoEnchoTime: _state.daihyoEnchoTime,
                    daihyoHasHantei: _state.daihyoHasHantei,
                    winPoint: double.tryParse(_winPointController.text) ?? 0,
                    lossPoint: double.tryParse(_lossPointController.text) ?? 0,
                    drawPoint: double.tryParse(_drawPointController.text) ?? 0,
                    overallTimeMinutes:
                        int.tryParse(_overallTimeController.text) ?? 30,
                    courtController: _courtController,
                    noteController: _noteController,
                    themeColors: _themeColors,
                    onRuleSceneSelected: (scene, ruleSet) =>
                        _applyCategoryRuleScene(scene, ruleSet),
                    onSetManualRoundType: (type) => _setManualRoundType(type),
                    onHeadingPresetToggled: (heading) =>
                        _toggleHeadingPreset(heading),
                    onClearCourt: () =>
                        setState(() => _courtController.clear()),
                    buildTextFieldDecoration:
                        ({
                          required String labelText,
                          String? hintText,
                          Widget? prefixIcon,
                          String? suffixText,
                        }) => MatchFormatSetupHelper.buildTextFieldDecoration(
                          themeColors: _themeColors,
                          labelText: labelText,
                          hintText: hintText,
                          prefixIcon: prefixIcon,
                          suffixText: suffixText,
                        ),

                    buildSectionHeader: (title, accent) =>
                        MatchFormatSectionHeader(
                          title: title,
                          accentColor: accent,
                        ),
                    formatMinutesText: CategoryRuleMatchHelper.formatMinutes,
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isKeyboardOpen
                  ? const SizedBox.shrink()
                  : MatchFormatStickyBottomAction(
                      currentPage: _currentPage,
                      isLastPage: _currentPage == 1,
                      themeColors: _themeColors,
                      onPrevious: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      onNextOrComplete: () {
                        if (_currentPage != 1) {
                          if (_currentPage == 0 &&
                              _state.selectedTeamId == null) {
                            AppSnackBar.show(context, '出場する自チームを選択してください');
                            return;
                          }
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _commitMatchFormatSetup();
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _commitMatchFormatSetup() {
    final registeredTeams =
        ref.read(registeredTeamsProvider(widget.tournamentId)).value ?? [];

    MatchFormatSaveHelper.commitAndSaveRule(
      ref: ref,
      courtText: _courtController.text.trim(),
      userNote: _noteController.text.trim(),
      registeredTeams: registeredTeams,
      selectedTeamId: _state.selectedTeamId,
      matchType: _state.matchType,
      category: _category,
      matchTime: _state.matchTime,
      isRunningTime: _state.isRunningTime,
      isRenseikai: _state.isRenseikai,
      hasExtension: _state.hasExtension,
      hasHantei: _state.hasHantei,
      extCount: _state.extCount,
      extTime: _state.extTime,
      kachinukiUnlimitedType: _state.kachinukiUnlimitedType,
      hasLeagueDaihyo: _state.hasLeagueDaihyo,
      renseikaiType: _state.renseikaiType,
      isDaihyoIpponShobu: _state.isDaihyoIpponShobu,
      winPointText: _winPointController.text,
      lossPointText: _lossPointController.text,
      drawPointText: _drawPointController.text,
      overallTimeText: _overallTimeController.text,
      selectedRuleScene: _state.selectedRuleScene,
    );

    context.push('/order-setup/${widget.tournamentId}');
  }
}
