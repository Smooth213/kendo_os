import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import '../providers/last_used_settings_provider.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart'; // ★ MatchRuleモデルを読み込む
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart'; // ファイル上部
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_category_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_dynamic_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_section_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_team_detail_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_sticky_bottom_action.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_step.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

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

  // ★ 追加：初期化時に文字列からUI状態を復元するロジック
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
    for (var major in ['小学生', '中学生', '高校生']) {
      if (cleanCat.startsWith(major)) {
        _selectedMajorCategory = major;
        final minor = cleanCat.substring(major.length);
        _selectedMinorCategory = minor.isEmpty ? '全体' : minor;
        return;
      }
    }
    _selectedMajorCategory = '小学生';
    _selectedMinorCategory = '低学年';
  }

  final List<String> _majorCategories = [
    '初心者',
    '幼年',
    '小学生',
    '中学生',
    '高校生',
    '大学・一般',
  ];

  List<String> _getMinorCategories(String major) {
    if (major == '初心者' || major == '幼年') {
      return ['全体', '男子', '女子'];
    }
    if (major == '小学生') {
      return [
        '全体',
        '低学年',
        '高学年',
        '1年',
        '2年',
        '3年',
        '4年',
        '5年',
        '6年',
        '男子',
        '女子',
      ];
    }
    if (major == '中学生' || major == '高校生') {
      return ['全体', '1年', '2年', '3年', '男子', '女子'];
    }
    if (major == '大学・一般') {
      return ['全体', '大学生', '一般', 'シニア', '男子', '女子'];
    }
    return ['全体'];
  }

  @override
  void initState() {
    super.initState();
    final lastSettings = ref.read(lastUsedSettingsProvider);
    _matchType = lastSettings['matchType'];

    // ★ 修正：前回のカテゴリ設定を2段階UIの状態に美しく復元
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

  String _formatMinutesText(double time) {
    if (time <= 0) return '0分';
    final mins = time.floor();
    final secs = ((time - mins) * 60).round();
    if (mins == 0) {
      return '$secs秒';
    }
    if (secs == 0) {
      return '$mins分';
    }
    return '$mins分$secs秒';
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

  void _showTeamDetailDialog(BuildContext context, TeamModel team) {
    int baseLen = 5;
    if (team.matchType.contains('3人制')) {
      baseLen = 3;
    } else if (team.matchType.contains('個人戦') ||
        team.matchType.contains('1人制')) {
      baseLen = 1;
    } else if (team.matchType.contains('7人制')) {
      baseLen = 7;
    }
    final List<String> posNames = _generatePositions(baseLen);
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

  List<String> _generatePositions(int size) {
    if (size <= 0) return [];
    if (size == 1) return ['選手'];
    if (size == 3) return ['先鋒', '中堅', '大将'];
    if (size == 5) return ['先鋒', '次鋒', '中堅', '副将', '大将'];

    List<String> positions = [];
    positions.add('先鋒');
    if (size >= 2) positions.add('次鋒');

    for (int i = 3; i <= size - 2; i++) {
      if (size % 2 != 0 && i == (size + 1) ~/ 2) {
        positions.add('中堅');
      } else {
        int k = size - i + 1;
        positions.add('$k将');
      }
    }

    if (size >= 4) positions.add('副将');
    if (size >= 3) positions.add('大将');

    return positions;
  }

  InputDecoration _buildTextFieldDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: _themeColors.subTextColor,
        fontSize: AppFontSize.bodySmall,
      ),
      hintText: hintText,
      hintStyle: TextStyle(
        color: _themeColors.hintColor,
        fontSize: AppFontSize.bodyMedium,
      ),
      suffixText: suffixText,
      suffixStyle: TextStyle(color: _themeColors.subTextColor),
      prefixIcon: prefixIcon,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      filled: true,
      fillColor: _themeColors.inputBackground,
      border: OutlineInputBorder(borderRadius: AppRadius.medium),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: _themeColors.separatorColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: _themeColors.primaryAccent, width: 2),
      ),
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
  // ★ 部門別ルールの自動読み込み & 連動ロジック
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
    final cleanNote = note.toLowerCase().trim();
    List<String> keywords = [
      '準決勝',
      '準決',
      'じゅんけつ',
      'ベスト4',
      'b4',
      'sf',
      'semifinal',
      '准決',
      '順決',
      '決勝',
      'けっしょう',
      'ファイナル',
      'final',
      '結勝',
      '決勝戦',
      '3位決定',
      '3決',
      '三決',
    ];

    final categoryName = _category;
    final asyncTourney = ref.read(tournamentProvider(widget.tournamentId));
    asyncTourney.whenData((tournament) {
      if (tournament != null) {
        final ruleSet = tournament.categoryRules[categoryName];
        if (ruleSet != null && ruleSet.advancedKeywords.isNotEmpty) {
          keywords = ruleSet.advancedKeywords
              .map((kw) => kw.toLowerCase().trim())
              .toList();
        }
      }
    });

    String testNote = cleanNote;
    final hasSemisKeyword = keywords.any(
      (kw) =>
          kw.contains('準決') ||
          kw.contains('準決勝') ||
          kw.contains('ベスト4') ||
          kw.contains('sf'),
    );
    if (!hasSemisKeyword) {
      testNote = testNote
          .replaceAll('準決勝', '')
          .replaceAll('準決', '')
          .replaceAll('准決', '')
          .replaceAll('順決', '')
          .replaceAll('じゅんけつ', '')
          .replaceAll('semifinal', '')
          .replaceAll('sf', '')
          .replaceAll('3位決定', '')
          .replaceAll('3決', '')
          .replaceAll('三決', '');
    }

    return keywords.any((kw) => kw.isNotEmpty && testNote.contains(kw));
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
        final categoryRules = tournament.categoryRules;
        if (categoryRules.containsKey(categoryName)) {
          final ruleSet = categoryRules[categoryName]!;
          if (!ruleSet.useHonsenRule && _selectedRuleScene == 'honsen') {
            if (ruleSet.useRenseikaiRule) {
              _selectedRuleScene = 'renseikai';
            } else if (ruleSet.useMoushiawaseRule) {
              _selectedRuleScene = 'moushiawase';
            }
          }
          if (_selectedRuleScene == 'renseikai') {
            _applyMatchRuleToState(ruleSet.renseikaiRule);
            _isRenseikai = true;
          } else if (_selectedRuleScene == 'moushiawase') {
            _applyMatchRuleToState(ruleSet.moushiawaseRule);
            _isRenseikai = true;
          } else if (_selectedRuleScene == 'advanced' &&
              ruleSet.useAdvancedRule) {
            _applyMatchRuleToState(ruleSet.advancedRule);
            _isRenseikai = false;
          } else {
            final isAdvanced =
                _isCurrentMatchAdvanced && ruleSet.useAdvancedRule;
            final targetRule = isAdvanced
                ? ruleSet.advancedRule
                : ruleSet.normalRule;
            _applyMatchRuleToState(targetRule);
            _isRenseikai = false;
          }
        }
      }
    });
  }

  void _applyCategoryRuleScene(String scene, CategoryRuleSet ruleSet) {
    setState(() {
      _selectedRuleScene = scene;
      MatchRule targetRule;
      if (scene == 'renseikai') {
        targetRule = ruleSet.renseikaiRule;
        _isRenseikai = true;
        _renseikaiType = ruleSet.renseikaiRule.renseikaiType;
      } else if (scene == 'moushiawase') {
        targetRule = ruleSet.moushiawaseRule;
        _isRenseikai = true;
        _renseikaiType = ruleSet.moushiawaseRule.renseikaiType;
      } else if (scene == 'advanced') {
        targetRule = ruleSet.advancedRule;
        _isRenseikai = false;
      } else {
        targetRule = ruleSet.normalRule;
        _isRenseikai = false;
      }
      _applyMatchRuleToState(targetRule);
    });
  }

  void _applyMatchRuleToState(MatchRule rule) {
    setState(() {
      _matchTime = rule.matchTimeMinutes;
      _isRunningTime = rule.isRunningTime;

      // 延長
      _hasExtension = rule.enchoCount > 0 || rule.isEnchoUnlimited;
      if (rule.isEnchoUnlimited) {
        _extCount = -2;
      } else {
        _extCount = rule.enchoCount;
      }

      // 延長時間
      _extTime = rule.enchoTimeMinutes;

      _hasHantei = rule.hasHantei;
      _isRenseikai = rule.isRenseikai;
      _renseikaiType = rule.renseikaiType;
      _overallTimeController.text = rule.overallTimeMinutes.toString();

      // 勝ち点
      _winPointController.text = rule.winPoint.toString();
      _lossPointController.text = rule.lossPoint.toString();
      _drawPointController.text = rule.drawPoint.toString();

      // 追加されたフィールドの読み込み
      _kachinukiUnlimitedType = rule.kachinukiUnlimitedType;
      _hasLeagueDaihyo = rule.hasLeagueDaihyo;
      _isDaihyoIpponShobu = rule.isDaihyoIpponShobu;

      // 代表戦詳細
      _daihyoMatchTime = rule.daihyoMatchTimeMinutes;
      _daihyoHasExtension = rule.daihyoHasExtension;
      _daihyoEnchoTime = rule.daihyoEnchoTimeMinutes;
      _daihyoEnchoCount = rule.daihyoEnchoCount;
      _daihyoHasHantei = rule.daihyoHasHantei;

      // 勝負方式・反則
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
                  _buildPage1Category(),
                  _buildPage2RuleSummaryAndDetails(),
                ],
              ),
            ),
            // ★ キーボードが開いた時は下のボタンも隠す
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isKeyboardOpen
                  ? const SizedBox.shrink()
                  : _buildStickyBottomAction(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1Category() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MatchFormatCategoryStep(
      tournamentId: widget.tournamentId,
      category: _category,
      selectedMajorCategory: _selectedMajorCategory,
      selectedMinorCategory: _selectedMinorCategory,
      selectedTeamId: _selectedTeamId,
      majorCategories: _majorCategories,
      getMinorCategories: _getMinorCategories,
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
      onAdjustOrder: (team) => _showTeamDetailDialog(context, team),
      onNavigateToTeamRegistration: () =>
          context.push('/team-registration/${widget.tournamentId}'),
      themeColors: _themeColors,
      isDark: isDark,
      buildSectionTitle: _buildSectionTitle,
    );
  }

  Widget _buildPage2RuleSummaryAndDetails() {
    return MatchFormatRuleStep(
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
      overallTimeMinutes: int.tryParse(_overallTimeController.text) ?? 30,
      courtController: _courtController,
      noteController: _noteController,
      themeColors: _themeColors,
      onRuleSceneSelected: (scene, ruleSet) =>
          _applyCategoryRuleScene(scene, ruleSet),
      onSetManualRoundType: (type) => _setManualRoundType(type),
      onHeadingPresetToggled: (heading) => _toggleHeadingPreset(heading),
      onClearCourt: () => setState(() => _courtController.clear()),
      buildTextFieldDecoration: _buildTextFieldDecoration,
      buildSectionHeader: _buildSectionHeader,
      formatMinutesText: _formatMinutesText,
    );
  }

  Widget _buildStickyBottomAction() {
    final isLastPage = _currentPage == 1;

    return MatchFormatStickyBottomAction(
      currentPage: _currentPage,
      isLastPage: isLastPage,
      themeColors: _themeColors,
      onPrevious: () => _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
      onNextOrComplete: () {
        if (!isLastPage) {
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

    List<String> selectedBaseOrder = [];
    String teamNamePrefix = '';
    if (_selectedTeamId != null) {
      final teams =
          ref.read(registeredTeamsProvider(widget.tournamentId)).value ?? [];
      for (var t in teams) {
        if (t.id == _selectedTeamId) {
          selectedBaseOrder = t.playerNames;
          teamNamePrefix = t.teamName;
          break;
        }
      }
    }

    int teamSize = 5;
    if (_matchType == '個人戦' ||
        _matchType == 'リーグ個人戦' ||
        _matchType.contains('1人制')) {
      teamSize = 1;
    } else if (_matchType.contains('3人制')) {
      teamSize = 3;
    } else if (_matchType.contains('7人制')) {
      teamSize = 7;
    } else if (_selectedTeamId != null) {
      final teams =
          ref.read(registeredTeamsProvider(widget.tournamentId)).value ?? [];
      TeamModel? selectedTeam;
      for (var t in teams) {
        if (t.id == _selectedTeamId) {
          selectedTeam = t;
          break;
        }
      }
      if (selectedTeam != null && selectedTeam.matchType.isNotEmpty) {
        if (selectedTeam.matchType.contains('3人制')) {
          teamSize = 3;
        } else if (selectedTeam.matchType.contains('7人制')) {
          teamSize = 7;
        } else if (selectedTeam.matchType.contains('1人制') ||
            selectedTeam.matchType.contains('個人戦')) {
          teamSize = 1;
        } else {
          teamSize = 5;
        }
      } else {
        teamSize = 5;
      }
    } else {
      teamSize = 5;
    }

    bool isLeague = _matchType.contains('リーグ');
    bool isKachinuki = _matchType == '勝ち抜き戦';

    final generatedPositions = _generatePositions(teamSize);

    final double finalTime = _matchTime;
    final double finalExtTime = _extTime;
    final int finalExtCount = _extCount;

    bool finalIsRunningTime = _isRenseikai ? _isRunningTime : false;

    final double winPt = double.tryParse(_winPointController.text) ?? 0;
    final double lossPt = double.tryParse(_lossPointController.text) ?? 0;
    final double drawPt = double.tryParse(_drawPointController.text) ?? 0;

    ref.read(lastUsedSettingsProvider.notifier).state = {
      'matchType': _matchType,
      'category': _category,
      'matchTime': finalTime,
      'isRunningTime': finalIsRunningTime,
      'hasExtension': _hasExtension,
      'hasHantei': _hasHantei,
      'extensionCount': finalExtCount,
      'extensionTimeMinutes': finalExtTime,
      'isRenseikai': _isRenseikai,
      'kachinukiUnlimitedType': _kachinukiUnlimitedType,
      'hasLeagueDaihyo': _hasLeagueDaihyo,
      'renseikaiType': _renseikaiType,
      'isDaihyoIpponShobu': _isDaihyoIpponShobu,
      'winPoint': winPt,
      'lossPoint': lossPt,
      'drawPoint': drawPt,
    };

    ref
        .read(matchRuleProvider.notifier)
        .updateRule(
          MatchRule(
            positions: generatedPositions,
            matchTimeMinutes: finalTime,
            isRunningTime: finalIsRunningTime,
            isLeague: isLeague,
            category: _category,
            note: noteCombined,
            isRenseikai: _isRenseikai,
            baseOrder: selectedBaseOrder,
            teamName: teamNamePrefix,
            isKachinuki: isKachinuki,
            kachinukiUnlimitedType: _kachinukiUnlimitedType,
            hasLeagueDaihyo: _hasLeagueDaihyo,
            renseikaiType: _renseikaiType,
            overallTimeMinutes: int.tryParse(_overallTimeController.text) ?? 30,
            isDaihyoIpponShobu: _isDaihyoIpponShobu,
            isEnchoUnlimited:
                _hasExtension && (finalExtTime == -2.0 || finalExtCount == -2),
            enchoTimeMinutes: _hasExtension
                ? (finalExtTime == -2.0 ? 0.0 : finalExtTime)
                : 0.0,
            enchoCount: _hasExtension
                ? (finalExtCount == -2 ? 99 : finalExtCount)
                : 0,
            hasHantei: _hasHantei,
            winPoint: winPt,
            lossPoint: lossPt,
            drawPoint: drawPt,
            matchScene: _selectedRuleScene,
          ),
        );

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
