import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
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
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';

final noteHistoryProvider = StateProvider<List<String>>((ref) {
  return ['1回戦', '2回戦', '準決勝', '決勝', '第1試合', '第2コート'];
});

// ★ 選手一覧を取得するProviderを追加
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
  late String _matchType;
  late bool _hasExtension;
  late bool _hasHantei;
  late double _matchTime;
  late bool _isRunningTime;
  late bool _isRenseikai;
  String? _selectedTeamId;

  late String _kachinukiUnlimitedType;
  late bool _hasLeagueDaihyo;
  late String _renseikaiType;
  final _overallTimeController = TextEditingController(text: '30');
  late bool _isDaihyoIpponShobu;

  // 代表戦詳細
  late double _daihyoMatchTime;
  late bool _daihyoHasExtension;
  late double _daihyoEnchoTime;
  late int _daihyoEnchoCount;
  late bool _daihyoHasHantei;

  // 勝負方式・反則
  late bool _isIpponShobu;
  late int _ipponLimit;
  late int _hansokuLimit;

  // ★ リーグ戦拡張：勝ち点入力用のコントローラー
  final _winPointController = TextEditingController(text: '0');
  final _lossPointController = TextEditingController(text: '0');
  final _drawPointController = TextEditingController(text: '0');

  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ★ 追加：2段階選択用の状態変数
  late String _selectedMajorCategory;
  late String _selectedMinorCategory;
  String _selectedRuleScene =
      'honsen'; // 'renseikai', 'honsen', 'moushiawase', 'advanced'

  // ★ 追加：チーム登録画面と共通！最終的なカテゴリ名を生成
  String get _category {
    if (_selectedMajorCategory == '初心者') return '初心者の部';
    if (_selectedMajorCategory == '幼年') return '幼年の部';
    if (_selectedMinorCategory == '全体') return '$_selectedMajorCategoryの部';
    if (_selectedMajorCategory == '大学・一般') return '$_selectedMinorCategoryの部';
    return '$_selectedMajorCategory$_selectedMinorCategoryの部';
  }

  void _parseCategoryToState(String categoryName) {
    final (major, minor) = MatchFormatSetupHelper.parseCategoryToState(
      categoryName,
    );
    _selectedMajorCategory = major;
    _selectedMinorCategory = minor;
  }

  @override
  void initState() {
    super.initState();
    final lastSettings = ref.read(lastUsedSettingsProvider);
    _matchType = lastSettings['matchType'];

    // 前回のカテゴリ設定を2段階UIの状態に復元
    _parseCategoryToState(lastSettings['category'] ?? '小学生低学年の部');

    _matchTime = lastSettings['matchTime'];
    _isRunningTime = lastSettings['isRunningTime'];
    _hasExtension = lastSettings['hasExtension'];
    _hasHantei = lastSettings['hasHantei'];
    _isRenseikai = lastSettings['isRenseikai'] ?? false;

    _kachinukiUnlimitedType = lastSettings['kachinukiUnlimitedType'] ?? '大将対大将';
    _hasLeagueDaihyo = lastSettings['hasLeagueDaihyo'] ?? false;
    _renseikaiType = lastSettings['renseikaiType'] ?? '一試合制';
    _isDaihyoIpponShobu = lastSettings['isDaihyoIpponShobu'] ?? true;

    // 代表戦詳細
    _daihyoMatchTime =
        (lastSettings['daihyoMatchTime'] as num?)?.toDouble() ?? 0.0;
    _daihyoHasExtension = lastSettings['daihyoHasExtension'] ?? true;
    _daihyoEnchoTime =
        (lastSettings['daihyoEnchoTime'] as num?)?.toDouble() ?? 3.0;
    _daihyoEnchoCount = lastSettings['daihyoEnchoCount'] ?? -2;
    _daihyoHasHantei = lastSettings['daihyoHasHantei'] ?? false;

    // 勝負方式・反則
    _isIpponShobu = lastSettings['isIpponShobu'] ?? false;
    _ipponLimit = lastSettings['ipponLimit'] ?? 2;
    _hansokuLimit = lastSettings['hansokuLimit'] ?? 2;

    // ★ 勝ち点の初期値を復元
    _winPointController.text = (lastSettings['winPoint'] ?? 0).toString();
    _lossPointController.text = (lastSettings['lossPoint'] ?? 0).toString();
    _drawPointController.text = (lastSettings['drawPoint'] ?? 0).toString();

    // Note変更監視
    _noteController.addListener(_onNoteChanged);

    // 初期のカテゴリールール読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoryRules();
    });
  }

  final _noteController = TextEditingController();
  final _courtController = TextEditingController();

  void _toggleHeadingPreset(String preset) {
    final current = _courtController.text.trim();
    if (current.isEmpty) {
      setState(() {
        _courtController.text = preset;
      });
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
    setState(() {
      _courtController.text = items.join(', ');
    });
  }

  int _extCount = -2;
  double _extTime = -2.0;

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

  void _showTeamDetailDialog(BuildContext context, TeamModel team) {
    final baseLen = MatchFormatSetupHelper.calculateTeamSize(
      matchType: team.matchType,
      selectedTeamId: null,
      registeredTeams: [],
    );
    final List<String> posNames = MatchFormatSetupHelper.generatePositions(
      baseLen,
    );
    final players = ref.read(playerListProvider).value ?? [];

    MatchFormatTeamDetailDialog.show(
      context: context,
      team: team,
      posNames: posNames,
      themeColors: _themeColors,
      players: players,
      onTeamUpdated: (updatedTeam) {
        setState(() {});
      },
    );
  }

  InputDecoration _buildTextFieldDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    String? suffixText,
  }) {
    return MatchFormatSetupHelper.buildTextFieldDecoration(
      themeColors: _themeColors,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixText: suffixText,
    );
  }

  Widget _buildDynamicHeader() {
    return MatchFormatDynamicHeader(
      currentPage: _currentPage,
      themeColors: _themeColors,
    );
  }

  Widget _buildSectionHeader(String title, Color accentColor) {
    return MatchFormatSectionHeader(title: title, accentColor: accentColor);
  }

  // ==========================================
  // 部門別ルールの自動読み込み & 連動ロジック
  // ==========================================
  String? _manualRoundTypeOverride;
  String _lastCheckedNote = '';

  bool get _isCurrentMatchAdvanced {
    if (_manualRoundTypeOverride != null) {
      return _manualRoundTypeOverride == 'advanced';
    }
    return _isAdvancedMatchName(_noteController.text);
  }

  bool _isAdvancedMatchName(String note) {
    final categoryName = _category;
    final asyncTourney = ref.read(tournamentProvider(widget.tournamentId));
    List<String>? customKeywords;
    asyncTourney.whenData((tournament) {
      if (tournament != null) {
        final ruleSet = tournament.categoryRules[categoryName];
        if (ruleSet != null && ruleSet.advancedKeywords.isNotEmpty) {
          customKeywords = ruleSet.advancedKeywords;
        }
      }
    });

    return CategoryRuleMatchHelper.isAdvancedMatchName(
      note,
      customKeywords: customKeywords,
    );
  }

  void _onNoteChanged() {
    final currentNote = _noteController.text;
    if (currentNote == _lastCheckedNote) return;
    _lastCheckedNote = currentNote;

    if (_manualRoundTypeOverride != null) return;

    final categoryName = _category;
    final asyncTourney = ref.read(tournamentProvider(widget.tournamentId));
    asyncTourney.whenData((tournament) {
      if (tournament != null) {
        final categoryRules = tournament.categoryRules;
        if (categoryRules.containsKey(categoryName)) {
          final ruleSet = categoryRules[categoryName]!;
          if (ruleSet.useAdvancedRule) {
            final isAdvanced = _isAdvancedMatchName(currentNote);
            final targetRule = isAdvanced
                ? ruleSet.advancedRule
                : ruleSet.normalRule;
            _applyMatchRuleToState(targetRule);
          }
        }
      }
    });
  }

  void _loadCategoryRules() {
    final categoryName = _category;
    final asyncTourney = ref.read(tournamentProvider(widget.tournamentId));
    asyncTourney.whenData((tournament) {
      if (tournament != null) {
        final ruleSet = tournament.categoryRules[categoryName];
        if (ruleSet != null) {
          String targetScene = _selectedRuleScene;
          if (!ruleSet.useHonsenRule && targetScene == 'honsen') {
            targetScene = ruleSet.useRenseikaiRule
                ? 'renseikai'
                : (ruleSet.useMoushiawaseRule ? 'moushiawase' : 'honsen');
          }
          if (targetScene == 'honsen' &&
              _isCurrentMatchAdvanced &&
              ruleSet.useAdvancedRule) {
            targetScene = 'advanced';
          }
          _applyCategoryRuleScene(targetScene, ruleSet);
        }
      }
    });
  }

  void _applyCategoryRuleScene(String scene, CategoryRuleSet ruleSet) {
    setState(() {
      _selectedRuleScene = scene;
      final isRen = scene == 'renseikai' || scene == 'moushiawase';
      final targetRule = scene == 'renseikai'
          ? ruleSet.renseikaiRule
          : (scene == 'moushiawase'
                ? ruleSet.moushiawaseRule
                : (scene == 'advanced'
                      ? ruleSet.advancedRule
                      : ruleSet.normalRule));
      _isRenseikai = isRen;
      if (isRen) _renseikaiType = targetRule.renseikaiType;
      _applyMatchRuleToState(targetRule);
    });
  }

  void _applyMatchRuleToState(MatchRule rule) {
    setState(() {
      _matchTime = rule.matchTimeMinutes;
      _isRunningTime = rule.isRunningTime;
      _hasExtension = rule.enchoCount > 0 || rule.isEnchoUnlimited;
      _extCount = rule.isEnchoUnlimited ? -2 : rule.enchoCount;
      _extTime = rule.enchoTimeMinutes;
      _hasHantei = rule.hasHantei;
      _isRenseikai = rule.isRenseikai;
      _renseikaiType = rule.renseikaiType;
      _overallTimeController.text = rule.overallTimeMinutes.toString();
      _winPointController.text = rule.winPoint.toString();
      _lossPointController.text = rule.lossPoint.toString();
      _drawPointController.text = rule.drawPoint.toString();
      _kachinukiUnlimitedType = rule.kachinukiUnlimitedType;
      _hasLeagueDaihyo = rule.hasLeagueDaihyo;
      _isDaihyoIpponShobu = rule.isDaihyoIpponShobu;
      _daihyoMatchTime = rule.daihyoMatchTimeMinutes;
      _daihyoHasExtension = rule.daihyoHasExtension;
      _daihyoEnchoTime = rule.daihyoEnchoTimeMinutes;
      _daihyoEnchoCount = rule.daihyoEnchoCount;
      _daihyoHasHantei = rule.daihyoHasHantei;
      _isIpponShobu = rule.isIpponShobu;
      _ipponLimit = rule.ipponLimit;
      _hansokuLimit = rule.hansokuLimit;
    });
  }

  void _setManualRoundType(String type) {
    setState(() {
      _manualRoundTypeOverride = type;
      final categoryName = _category;
      final asyncTourney = ref.read(tournamentProvider(widget.tournamentId));
      asyncTourney.whenData((tournament) {
        if (tournament != null) {
          final categoryRules = tournament.categoryRules;
          if (categoryRules.containsKey(categoryName)) {
            final ruleSet = categoryRules[categoryName]!;
            final isAdvanced = type == 'advanced';
            final targetRule = isAdvanced
                ? ruleSet.advancedRule
                : ruleSet.normalRule;
            _applyMatchRuleToState(targetRule);
          }
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
    // ★ Phase 8-3: キーボードが開いているかを検知
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
            // ★ キーボードが開いた時はヘッダーをスッと隠す
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              // ★ 修正: 不要な Column と _buildImmersiveAppBar を削り、直接ヘッダーを描画する
              child: isKeyboardOpen
                  ? const SizedBox.shrink()
                  : _buildDynamicHeader(),
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
                    selectedMajorCategory: _selectedMajorCategory,
                    selectedMinorCategory: _selectedMinorCategory,
                    selectedTeamId: _selectedTeamId,
                    majorCategories: MatchFormatSetupHelper.majorCategories,
                    getMinorCategories:
                        MatchFormatSetupHelper.getMinorCategories,
                    onCategoryChanged: (major, minor) {
                      setState(() {
                        _selectedMajorCategory = major;
                        _selectedMinorCategory = minor;
                        _selectedTeamId = null;
                        _manualRoundTypeOverride = null;
                        _loadCategoryRules();
                      });
                    },
                    onTeamSelected: (team) {
                      setState(() {
                        _selectedTeamId = team.id;
                        _matchType = team.matchType;
                      });
                    },
                    onAdjustOrder: (team) =>
                        _showTeamDetailDialog(context, team),
                    onNavigateToTeamRegistration: () => context.push(
                      '/team-registration/${widget.tournamentId}',
                    ),
                    themeColors: _themeColors,
                    isDark: isDark,
                    buildSectionTitle: _buildSectionTitle,
                  ),
                  MatchFormatRuleStep(
                    tournamentId: widget.tournamentId,
                    category: _category,
                    selectedRuleScene: _selectedRuleScene,
                    isCurrentMatchAdvanced: _isCurrentMatchAdvanced,
                    hasExtension: _hasExtension,
                    extTime: _extTime,
                    extCount: _extCount,
                    matchTime: _matchTime,
                    isRunningTime: _isRunningTime,
                    isRenseikai: _isRenseikai,
                    renseikaiType: _renseikaiType,
                    matchType: _matchType,
                    isIpponShobu: _isIpponShobu,
                    ipponLimit: _ipponLimit,
                    hansokuLimit: _hansokuLimit,
                    hasHantei: _hasHantei,
                    kachinukiUnlimitedType: _kachinukiUnlimitedType,
                    hasLeagueDaihyo: _hasLeagueDaihyo,
                    isDaihyoIpponShobu: _isDaihyoIpponShobu,
                    daihyoMatchTime: _daihyoMatchTime,
                    daihyoHasExtension: _daihyoHasExtension,
                    daihyoEnchoCount: _daihyoEnchoCount,
                    daihyoEnchoTime: _daihyoEnchoTime,
                    daihyoHasHantei: _daihyoHasHantei,
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
                    buildTextFieldDecoration: _buildTextFieldDecoration,
                    buildSectionHeader: _buildSectionHeader,
                    formatMinutesText: CategoryRuleMatchHelper.formatMinutes,
                  ),
                ],
              ),
            ),
            // ★ キーボードが開いた時は下のボタンも隠す
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
                          if (_currentPage == 0 && _selectedTeamId == null) {
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
    final courtText = _courtController.text.trim();
    final userNote = _noteController.text.trim();
    final noteCombined = courtText.isNotEmpty
        ? (userNote.isNotEmpty ? '$courtText\n$userNote' : courtText)
        : userNote;

    if (userNote.isNotEmpty) {
      final words = userNote.split(' ');
      final currentHistory = ref.read(noteHistoryProvider);
      final updatedHistory = {
        ...words,
        ...currentHistory,
      }.toList().take(10).toList();
      ref.read(noteHistoryProvider.notifier).state = updatedHistory;
    }

    final registeredTeams =
        ref.read(registeredTeamsProvider(widget.tournamentId)).value ?? [];

    List<String> selectedBaseOrder = [];
    String teamNamePrefix = '';
    if (_selectedTeamId != null) {
      for (var t in registeredTeams) {
        if (t.id == _selectedTeamId) {
          selectedBaseOrder = t.playerNames;
          teamNamePrefix = t.teamName;
          break;
        }
      }
    }

    final teamSize = MatchFormatSetupHelper.calculateTeamSize(
      matchType: _matchType,
      selectedTeamId: _selectedTeamId,
      registeredTeams: registeredTeams,
    );

    final isLeague = _matchType.contains('リーグ');
    final isKachinuki = _matchType == '勝ち抜き戦';
    final generatedPositions = MatchFormatSetupHelper.generatePositions(
      teamSize,
    );

    final double winPt = double.tryParse(_winPointController.text) ?? 0;
    final double lossPt = double.tryParse(_lossPointController.text) ?? 0;
    final double drawPt = double.tryParse(_drawPointController.text) ?? 0;
    final bool finalIsRunningTime = _isRenseikai ? _isRunningTime : false;

    ref.read(lastUsedSettingsProvider.notifier).state = {
      'matchType': _matchType,
      'category': _category,
      'matchTime': _matchTime,
      'isRunningTime': finalIsRunningTime,
      'hasExtension': _hasExtension,
      'hasHantei': _hasHantei,
      'extensionCount': _extCount,
      'extensionTimeMinutes': _extTime,
      'isRenseikai': _isRenseikai,
      'kachinukiUnlimitedType': _kachinukiUnlimitedType,
      'hasLeagueDaihyo': _hasLeagueDaihyo,
      'renseikaiType': _renseikaiType,
      'isDaihyoIpponShobu': _isDaihyoIpponShobu,
      'winPoint': winPt,
      'lossPoint': lossPt,
      'drawPoint': drawPt,
    };

    final rule = MatchFormatSetupHelper.createMatchRule(
      positions: generatedPositions,
      matchTime: _matchTime,
      isRunningTime: finalIsRunningTime,
      isLeague: isLeague,
      category: _category,
      noteCombined: noteCombined,
      isRenseikai: _isRenseikai,
      baseOrder: selectedBaseOrder,
      teamName: teamNamePrefix,
      isKachinuki: isKachinuki,
      kachinukiUnlimitedType: _kachinukiUnlimitedType,
      hasLeagueDaihyo: _hasLeagueDaihyo,
      renseikaiType: _renseikaiType,
      overallTimeMinutes: int.tryParse(_overallTimeController.text) ?? 30,
      isDaihyoIpponShobu: _isDaihyoIpponShobu,
      hasExtension: _hasExtension,
      extTime: _extTime,
      extCount: _extCount,
      hasHantei: _hasHantei,
      winPoint: winPt,
      lossPoint: lossPt,
      drawPoint: drawPt,
      selectedRuleScene: _selectedRuleScene,
    );

    ref.read(matchRuleProvider.notifier).updateRule(rule);
    context.push('/order-setup/${widget.tournamentId}');
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
}
