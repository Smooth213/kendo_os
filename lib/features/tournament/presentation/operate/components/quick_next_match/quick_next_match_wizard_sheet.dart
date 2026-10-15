import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_heading_format_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/quick_next_match/kata_pair_helper.dart';
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
  }) => showAppBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppKendoColors.transparent,
    builder: (ctx) => QuickNextMatchWizardSheet(
      baseMatch: baseMatch,
      teamMatches: teamMatches,
      isSameTeamContinue: isSameTeamContinue,
    ),
  );

  @override
  ConsumerState<QuickNextMatchWizardSheet> createState() =>
      _QuickNextMatchWizardSheetState();
}

class _QuickNextMatchWizardSheetState
    extends ConsumerState<QuickNextMatchWizardSheet> {
  late final PageController _pageController;
  late final TextEditingController _courtController;
  late final TextEditingController _privateNoteController;
  late final TextEditingController _opponentTeamController;
  late List<TextEditingController> _opponentPlayerControllers;

  int _currentPage = 0;
  bool _isOwnTeamRed = true;
  bool _isSubmitting = false;

  late String _ownTeamName;
  late List<String> _positions, _playerNames;
  late bool _isIndividual, _isRenseikai;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _courtController = TextEditingController();
    _privateNoteController = TextEditingController();
    _opponentTeamController = TextEditingController();
    _initMatchData();
  }

  void _initMatchData() {
    final base = widget.baseMatch;
    final rule = base.rule ?? ref.read(matchRuleProvider);
    final isKata = KataPairHelper.isKataMatch(base, rule);
    _isRenseikai =
        (rule?.isRenseikai == true) || base.matchType.contains('錬成会');

    final isGroupOrTeam =
        isKata ||
        (base.groupName?.isNotEmpty == true) ||
        (rule != null && rule.positions.length > 1) ||
        (widget.teamMatches.length > 1);

    _isIndividual =
        !isKata &&
        !isGroupOrTeam &&
        (!base.isKachinuki &&
            (base.matchType == 'individual' ||
                base.matchType == '選手' ||
                (!base.redName.contains(':') && widget.teamMatches.isEmpty)));

    // 自チーム判定
    final ownTeams =
        ref.read(customTeamNamesProvider).value ?? const <String>[];
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

    final shouldPreserveOpponent = widget.isSameTeamContinue;

    if (isWhiteOwn) {
      _ownTeamName = wTeam.isNotEmpty ? wTeam : '自チーム';
      _isOwnTeamRed = false;
      _opponentTeamController.text = shouldPreserveOpponent && rTeam != '自チーム'
          ? rTeam
          : '';
    } else {
      _ownTeamName = rTeam.isNotEmpty ? rTeam : '自チーム';
      _isOwnTeamRed = true;
      _opponentTeamController.text = shouldPreserveOpponent && wTeam != '自チーム'
          ? wTeam
          : '';
    }

    // ポジションと選手名の抽出
    final sortedMatches = widget.teamMatches.isNotEmpty
        ? (List<MatchModel>.from(widget.teamMatches)
            ..sort((a, b) => a.order.compareTo(b.order)))
        : <MatchModel>[base];

    _positions = <String>[];
    _playerNames = <String>[];
    _opponentPlayerControllers = <TextEditingController>[];

    if (isKata) {
      _positions = (rule != null && rule.positions.length >= 2)
          ? List<String>.from(rule.positions.take(2))
          : <String>['選手', '選手'];
      final rawOwn = _isOwnTeamRed ? base.redName : base.whiteName;
      final rawOpp = _isOwnTeamRed ? base.whiteName : base.redName;
      _playerNames = KataPairHelper.extractPairNames(rawOwn);
      final oppNames = KataPairHelper.extractOpponentPairNames(
        rawOpp,
        shouldPreserve: shouldPreserveOpponent,
      );
      _opponentPlayerControllers.addAll(
        oppNames.map((name) => TextEditingController(text: name)),
      );
    } else if (_isIndividual) {
      _positions = ['選手'];
      final rawOwn = _isOwnTeamRed ? base.redName : base.whiteName;
      final rawOpp = _isOwnTeamRed ? base.whiteName : base.redName;
      final pName = rawOwn.contains(':')
          ? rawOwn.split(':').last.trim()
          : rawOwn.trim();
      final oppName = shouldPreserveOpponent
          ? (rawOpp.contains(':')
                ? rawOpp.split(':').last.trim()
                : (rawOpp == '選手' ? '' : rawOpp.trim()))
          : '';
      _playerNames.add(pName.isEmpty ? '選手' : pName);
      _opponentPlayerControllers.add(TextEditingController(text: oppName));
    } else {
      if (widget.teamMatches.isNotEmpty) {
        for (final m in sortedMatches) {
          final pos = m.matchType.isNotEmpty ? m.matchType : '選手';
          _positions.add(pos);

          final rawOwn = _isOwnTeamRed ? m.redName : m.whiteName;
          final rawOpp = _isOwnTeamRed ? m.whiteName : m.redName;
          final pName = rawOwn.contains(':')
              ? rawOwn.split(':').last.trim()
              : rawOwn.trim();
          final oppName = shouldPreserveOpponent
              ? (rawOpp.contains(':') ? rawOpp.split(':').last.trim() : '')
              : '';
          _playerNames.add(pName.isEmpty ? '選手' : pName);
          _opponentPlayerControllers.add(TextEditingController(text: oppName));
        }
      } else {
        final defaultPositions =
            (rule != null &&
                rule.positions.isNotEmpty &&
                rule.positions.first != '選手')
            ? rule.positions
            : const ['先鋒', '次鋒', '中堅', '副将', '大将'];
        for (int i = 0; i < defaultPositions.length; i++) {
          final pos = defaultPositions[i];
          _positions.add(pos);
          final pName =
              (rule != null &&
                  rule.baseOrder.length > i &&
                  rule.baseOrder[i].isNotEmpty)
              ? rule.baseOrder[i]
              : '選手';
          _playerNames.add(pName);
          _opponentPlayerControllers.add(TextEditingController());
        }
      }
    }

    // 既存見出しと運営メモの引き継ぎ
    _courtController.text = MatchHeadingFormatHelper.extractPublicHeading(
      base.note,
    );
    _privateNoteController.text = MatchHeadingFormatHelper.extractPrivateNote(
      base.note,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _courtController.dispose();
    _privateNoteController.dispose();
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

  void _reorderPositions(int oldIndex, int newIndex) {
    setState(() {
      final pos = _positions.removeAt(oldIndex);
      _positions.insert(newIndex, pos);
      final pName = _playerNames.removeAt(oldIndex);
      _playerNames.insert(newIndex, pName);
      final ctrl = _opponentPlayerControllers.removeAt(oldIndex);
      _opponentPlayerControllers.insert(newIndex, ctrl);
    });
  }

  void _addExtraPosition() {
    setState(() {
      final newIndex = _positions.length + 1;
      _positions.add('追加枠$newIndex');
      _playerNames.add('選手');
      _opponentPlayerControllers.add(TextEditingController());
    });
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
      final privateNote = _privateNoteController.text.trim();
      final fullNote = [
        if (courtHeading.isNotEmpty) courtHeading,
        if (privateNote.isNotEmpty) privateNote,
      ].join('\n');

      final newGroupId = const Uuid().v4();
      final String groupName = _isIndividual
          ? (base.groupName ?? '')
          : (_isRenseikai
                ? '錬成会 - $newGroupId'
                : (courtHeading.isNotEmpty
                      ? '$courtHeading - $newGroupId'
                      : '対戦 - $newGroupId'));

      final isKata = KataPairHelper.isKataMatch(base, rule);
      final matchesToCreate = KataPairHelper.generateNextMatches(
        base: base,
        rule: rule,
        isKata: isKata,
        isIndividual: _isIndividual,
        isRenseikai: _isRenseikai,
        isOwnTeamRed: _isOwnTeamRed,
        ownTeamName: _ownTeamName,
        oppTeam: oppTeam,
        groupName: groupName,
        fullNote: fullNote,
        positions: _positions,
        playerNames: _playerNames,
        opponentPlayerControllers: _opponentPlayerControllers,
      );

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
                    noteController: _privateNoteController,
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
                    ownTeamName: _ownTeamName,
                    positions: _positions,
                    playerNames: _playerNames,
                    onPlayerNamesChanged: (val) =>
                        setState(() => _playerNames = val),
                    opponentPlayerControllers: _opponentPlayerControllers,
                    onReorder: _reorderPositions,
                    onAddExtraPosition: _addExtraPosition,
                    isRenseikai: _isRenseikai,
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

  Widget _buildStepDivider(int afterStep, AppThemeColors themeColors) =>
      Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        color: _currentPage > afterStep
            ? themeColors.primaryAccent
            : themeColors.separatorColor,
      );
}
