import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_heading_format_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/quick_next_match/steps/quick_next_court_heading_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/quick_next_match/steps/quick_next_opponent_and_color_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/quick_next_match/steps/quick_next_order_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart'
    show customTeamNamesProvider;
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:uuid/uuid.dart';

/// 🥋 統一次戦クイック追加ウィザードシート
class QuickNextMatchWizardSheet extends ConsumerStatefulWidget {
  final MatchModel baseMatch;
  final List<MatchModel> teamMatches;
  final bool isSameTeamContinue;

  const QuickNextMatchWizardSheet({
    super.key,
    required this.baseMatch,
    this.teamMatches = const [],
    this.isSameTeamContinue = false,
  });

  static Future<void> show(
    BuildContext context, {
    required MatchModel baseMatch,
    List<MatchModel> teamMatches = const [],
    bool isSameTeamContinue = false,
  }) {
    return showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppKendoColors.transparent,
      builder: (ctx) => QuickNextMatchWizardSheet(
        baseMatch: baseMatch,
        teamMatches: teamMatches,
        isSameTeamContinue: isSameTeamContinue,
      ),
    );
  }

  @override
  ConsumerState<QuickNextMatchWizardSheet> createState() =>
      _QuickNextMatchWizardSheetState();
}

class _QuickNextMatchWizardSheetState
    extends ConsumerState<QuickNextMatchWizardSheet> {
  late final PageController _pageController;
  late final TextEditingController _courtController;
  late final TextEditingController _opponentTeamController;
  late final List<TextEditingController> _opponentPlayerControllers;

  int _currentPage = 0;
  bool _isOwnTeamRed = true;
  bool _isSubmitting = false;

  late String _ownTeamName;
  late List<String> _positions;
  late List<String> _playerNames;
  late bool _isIndividual;
  late bool _isRenseikai;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _courtController = TextEditingController();
    _opponentTeamController = TextEditingController();

    _initMatchData();
  }

  void _initMatchData() {
    final base = widget.baseMatch;
    final rule = base.rule ?? ref.read(matchRuleProvider);
    _isRenseikai =
        (rule?.isRenseikai == true) || base.matchType.contains('錬成会');

    _isIndividual =
        !base.isKachinuki &&
        (base.matchType == 'individual' ||
            base.matchType == '選手' ||
            (!base.redName.contains(':') && widget.teamMatches.isEmpty));

    // 自チーム判定
    final ownTeamsAsync = ref.read(customTeamNamesProvider);
    final ownTeams = ownTeamsAsync.hasValue
        ? (ownTeamsAsync.value ?? <String>[])
        : <String>[];
    final ruleTeam = rule?.teamName.trim() ?? '';

    final rTeam = base.redName.contains(':')
        ? base.redName.split(':').first.trim()
        : base.redName.trim();
    final wTeam = base.whiteName.contains(':')
        ? base.whiteName.split(':').first.trim()
        : base.whiteName.trim();

    final isWhiteOwn =
        ownTeams.contains(wTeam) ||
        base.whiteName.contains('自チーム') ||
        (ruleTeam.isNotEmpty && wTeam == ruleTeam);

    if (isWhiteOwn) {
      _ownTeamName = wTeam.isNotEmpty ? wTeam : '自チーム';
      _isOwnTeamRed = false;
      _opponentTeamController.text = rTeam == '自チーム' ? '' : rTeam;
    } else {
      _ownTeamName = rTeam.isNotEmpty ? rTeam : '自チーム';
      _isOwnTeamRed = true;
      _opponentTeamController.text = wTeam == '自チーム' ? '' : wTeam;
    }

    // ポジションと選手名の抽出
    final sortedMatches = widget.teamMatches.isNotEmpty
        ? (List<MatchModel>.from(widget.teamMatches)
            ..sort((a, b) => a.order.compareTo(b.order)))
        : <MatchModel>[base];

    _positions = [];
    _playerNames = [];
    _opponentPlayerControllers = [];

    if (_isIndividual) {
      _positions = ['選手'];
      final rawOwn = _isOwnTeamRed ? base.redName : base.whiteName;
      final rawOpp = _isOwnTeamRed ? base.whiteName : base.redName;
      final pName = rawOwn.contains(':')
          ? rawOwn.split(':').last.trim()
          : rawOwn.trim();
      final oppName = rawOpp.contains(':')
          ? rawOpp.split(':').last.trim()
          : (rawOpp == '選手' ? '' : rawOpp.trim());
      _playerNames.add(pName.isEmpty ? '選手' : pName);
      _opponentPlayerControllers.add(TextEditingController(text: oppName));
    } else {
      for (final m in sortedMatches) {
        final pos = m.matchType.isNotEmpty ? m.matchType : '選手';
        _positions.add(pos);

        final rawOwn = _isOwnTeamRed ? m.redName : m.whiteName;
        final rawOpp = _isOwnTeamRed ? m.whiteName : m.redName;
        final pName = rawOwn.contains(':')
            ? rawOwn.split(':').last.trim()
            : rawOwn.trim();
        final oppName = rawOpp.contains(':')
            ? rawOpp.split(':').last.trim()
            : '';
        _playerNames.add(pName.isEmpty ? '選手' : pName);
        _opponentPlayerControllers.add(TextEditingController(text: oppName));
      }
    }

    // 既存見出しの引き継ぎ
    _courtController.text = MatchHeadingFormatHelper.extractPublicHeading(
      base.note,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _courtController.dispose();
    _opponentTeamController.dispose();
    for (final c in _opponentPlayerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleCommitNextMatch() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final base = widget.baseMatch;
      final rule = base.rule ?? ref.read(matchRuleProvider);
      final oppTeam = _opponentTeamController.text.trim().isEmpty
          ? '相手チーム'
          : _opponentTeamController.text.trim();
      final courtHeading = _courtController.text.trim();

      final newGroupId = const Uuid().v4();
      final String groupName = _isIndividual
          ? (base.groupName ?? '')
          : (_isRenseikai
                ? '錬成会 - $newGroupId'
                : (courtHeading.isNotEmpty
                      ? '$courtHeading - $newGroupId'
                      : '対戦 - $newGroupId'));

      final matchesToCreate = <MatchModel>[];
      final double baseOrder = base.order + 1.0;

      for (int i = 0; i < _positions.length; i++) {
        final pos = _positions[i];
        final myPlayer = i < _playerNames.length ? _playerNames[i] : '選手';
        final oppCtrl = i < _opponentPlayerControllers.length
            ? _opponentPlayerControllers[i]
            : null;
        final oppPlayer = (oppCtrl != null && oppCtrl.text.trim().isNotEmpty)
            ? oppCtrl.text.trim()
            : '選手';

        final String redStr;
        final String whiteStr;

        if (_isOwnTeamRed) {
          redStr = '$_ownTeamName : $myPlayer';
          whiteStr = '$oppTeam : $oppPlayer';
        } else {
          redStr = '$oppTeam : $oppPlayer';
          whiteStr = '$_ownTeamName : $myPlayer';
        }

        final matchId = const Uuid().v4();
        matchesToCreate.add(
          MatchModel(
            id: matchId,
            tournamentId: base.tournamentId,
            category: base.category,
            groupName: groupName,
            matchType: _isIndividual ? 'individual' : pos,
            rule: rule,
            redName: redStr,
            whiteName: whiteStr,
            status: 'pending',
            matchTimeMinutes: base.matchTimeMinutes,
            isRunningTime: base.isRunningTime,
            order: baseOrder + (i * 0.1),
            note: courtHeading.isNotEmpty ? courtHeading : base.note,
          ),
        );
      }

      final service = ref.read(matchApplicationServiceProvider);
      for (final m in matchesToCreate) {
        await service.saveMatch(m);
      }

      if (!mounted) return;
      Navigator.pop(context);

      AppSnackBar.show(context, '次戦を作成しました');
      if (matchesToCreate.isNotEmpty) {
        context.push('/match/${matchesToCreate.first.id}');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'エラーが発生しました: $e');
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'operate');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: themeColors.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xlargeValue),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: themeColors.subTextColor.withValues(alpha: 0.3),
                borderRadius: AppRadius.compact,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // ステップインジケーター（3ステップ）
            if (!widget.isSameTeamContinue) ...[
              _buildStepIndicator(themeColors),
              const SizedBox(height: AppSpacing.xs),
            ],
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  QuickNextOrderStep(
                    teamName: _ownTeamName,
                    isIndividual: _isIndividual,
                    isRenseikai: _isRenseikai,
                    positions: _positions,
                    playerNames: _playerNames,
                    onPlayerNamesChanged: (updated) =>
                        setState(() => _playerNames = updated),
                    onNext: _nextPage,
                    onQuickStartRenseikai:
                        widget.isSameTeamContinue || _isRenseikai
                        ? _handleCommitNextMatch
                        : null,
                  ),
                  QuickNextCourtHeadingStep(
                    courtController: _courtController,
                    onBack: _previousPage,
                    onNext: _nextPage,
                  ),
                  QuickNextOpponentAndColorStep(
                    tournamentId: widget.baseMatch.tournamentId ?? '',
                    isIndividual: _isIndividual,
                    isOwnTeamRed: _isOwnTeamRed,
                    onIsOwnTeamRedChanged: (val) =>
                        setState(() => _isOwnTeamRed = val),
                    opponentTeamController: _opponentTeamController,
                    positions: _positions,
                    opponentPlayerControllers: _opponentPlayerControllers,
                    onBack: _previousPage,
                    onConfirm: _handleCommitNextMatch,
                    isSubmitting: _isSubmitting,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(AppThemeColors themeColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          _buildStepCircle(0, '1. オーダー', themeColors),
          Expanded(child: _buildStepDivider(0, themeColors)),
          _buildStepCircle(1, '2. 試合詳細', themeColors),
          Expanded(child: _buildStepDivider(1, themeColors)),
          _buildStepCircle(2, '3. 相手・紅白', themeColors),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, AppThemeColors themeColors) {
    final isDone = _currentPage > step;
    final isCurrent = _currentPage == step;

    final Color circleBg = isDone || isCurrent
        ? themeColors.primaryAccent
        : themeColors.separatorColor;
    final Color textColor = isCurrent
        ? themeColors.primaryAccent
        : themeColors.subTextColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: circleBg,
          child: isDone
              ? const Icon(
                  Icons.check,
                  size: 14,
                  color: AppKendoColors.pureWhite,
                )
              : Text(
                  '${step + 1}',
                  style: const TextStyle(
                    fontSize: AppFontSize.badge,
                    fontWeight: AppFontWeight.bold,
                    color: AppKendoColors.pureWhite,
                  ),
                ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.caption,
            fontWeight: isCurrent ? AppFontWeight.bold : AppFontWeight.regular,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int afterStep, AppThemeColors themeColors) {
    final isPassed = _currentPage > afterStep;
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: isPassed ? themeColors.primaryAccent : themeColors.separatorColor,
    );
  }
}
