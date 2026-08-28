import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart'
    show customTeamNamesProvider;
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 【Phase 1: ノンストップ連戦】自チーム設定を引き継ぎ、相手チーム名を入力して即時開始するシート
class QuickNextMatchSheet extends ConsumerStatefulWidget {
  final MatchModel currentMatch;
  final List<MatchModel> teamMatches;

  const QuickNextMatchSheet({
    super.key,
    required this.currentMatch,
    required this.teamMatches,
  });

  static Future<void> show(
    BuildContext context, {
    required MatchModel currentMatch,
    required List<MatchModel> teamMatches,
  }) {
    return showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppKendoColors.transparent,
      builder: (ctx) => QuickNextMatchSheet(
        currentMatch: currentMatch,
        teamMatches: teamMatches,
      ),
    );
  }

  @override
  ConsumerState<QuickNextMatchSheet> createState() =>
      _QuickNextMatchSheetState();
}

class _QuickNextMatchSheetState extends ConsumerState<QuickNextMatchSheet> {
  late final TextEditingController _opponentTeamCtrl;
  late final TextEditingController _groupNameCtrl;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _opponentTeamCtrl = TextEditingController();
    // ③ メモは空欄にし、グレーの入力補助（hintText）のみ表示
    _groupNameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _opponentTeamCtrl.dispose();
    _groupNameCtrl.dispose();
    super.dispose();
  }

  /// 自チーム名と自チームが赤側/白側どちらかを判定
  ({String teamName, bool isRedSide}) _resolveOwnTeam() {
    final current = widget.currentMatch;
    final ownTeamsAsync = ref.read(customTeamNamesProvider);
    final ownTeams = ownTeamsAsync.hasValue
        ? (ownTeamsAsync.value ?? [])
        : <String>[];
    final ruleTeam = current.rule?.teamName.trim();

    final rTeam = current.redName.contains(':')
        ? current.redName.split(':').first.trim()
        : current.redName.trim();
    final wTeam = current.whiteName.contains(':')
        ? current.whiteName.split(':').first.trim()
        : current.whiteName.trim();

    final isWhiteOwn =
        ownTeams.contains(wTeam) ||
        current.whiteName.contains('自チーム') ||
        (ruleTeam != null && ruleTeam.isNotEmpty && wTeam == ruleTeam);

    if (isWhiteOwn) {
      return (teamName: wTeam.isNotEmpty ? wTeam : '自チーム', isRedSide: false);
    }
    return (teamName: rTeam.isNotEmpty ? rTeam : '自チーム', isRedSide: true);
  }

  Future<void> _handleStartNextMatch() async {
    if (_isCreating) return;
    final opponentName = _opponentTeamCtrl.text.trim().isEmpty
        ? '相手チーム'
        : _opponentTeamCtrl.text.trim();
    final groupName = _groupNameCtrl.text.trim();

    setState(() => _isCreating = true);

    showAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final current = widget.currentMatch;
      final ownInfo = _resolveOwnTeam();
      final myTeamName = ownInfo.teamName;
      final isOwnRed = ownInfo.isRedSide;

      // 既存のポジション順（先鋒、次鋒、中堅、副将、大将）を抽出
      final List<MatchModel> sourceMatches = widget.teamMatches.isNotEmpty
          ? (List<MatchModel>.from(widget.teamMatches)
              ..sort((a, b) => a.order.compareTo(b.order)))
          : [current];

      final rule = current.rule ?? ref.read(matchRuleProvider);
      final newGroupId = const Uuid().v4();
      final displayGroupName = groupName.isNotEmpty
          ? '$groupName - $newGroupId'
          : '練習試合 - $newGroupId';
      String? firstMatchId;

      for (int i = 0; i < sourceMatches.length; i++) {
        final src = sourceMatches[i];
        final matchId = const Uuid().v4();
        if (i == 0) firstMatchId = matchId;

        // 自チーム側の選手名を正確に抽出
        final rawOwnName = isOwnRed ? src.redName : src.whiteName;
        final myPlayerName = rawOwnName.contains(':')
            ? rawOwnName.split(':').last.trim()
            : (src.matchType.isNotEmpty ? src.matchType : '選手');
        final oppPosition = src.matchType.isNotEmpty ? src.matchType : '選手';

        final newMatch = MatchModel(
          id: matchId,
          tournamentId: current.tournamentId,
          category: current.category,
          groupName: displayGroupName,
          matchType: src.matchType.isNotEmpty ? src.matchType : '先鋒',
          rule: rule,
          redName: '$myTeamName : $myPlayerName',
          whiteName: '$opponentName : $oppPosition',
          status: 'waiting',
          matchTimeMinutes: src.matchTimeMinutes > 0
              ? src.matchTimeMinutes
              : (rule?.matchTimeMinutes.toDouble() ?? 3.0),
          isRunningTime: src.isRunningTime,
          order: i.toDouble(),
          note: groupName.isNotEmpty ? groupName : current.note,
        );

        await ref.read(matchApplicationServiceProvider).saveMatch(newMatch);
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // loading pop
      Navigator.pop(context); // sheet pop

      if (firstMatchId != null && mounted) {
        context.pushReplacement('/match/$firstMatchId');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = context.appColors.cardBackground;
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;

    final ownInfo = _resolveOwnTeam();
    final myTeam = ownInfo.teamName;

    final positionCount = widget.teamMatches.isNotEmpty
        ? widget.teamMatches.length
        : 1;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xlargeValue),
          ),
        ),
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: subTextColor.withValues(alpha: 0.3),
                  borderRadius: AppRadius.compact,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppKendoColors.ipponGold.withValues(alpha: 0.15),
                    borderRadius: AppRadius.small,
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: AppKendoColors.ipponGold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '次の対戦へ連戦開始 (クイック対戦)',
                  style: TextStyle(
                    fontSize: AppFontSize.header,
                    fontWeight: AppFontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '「$myTeam」のオーダー($positionCount名)とルール設定を引き継ぎ、対戦相手を入力して即座に第1試合へ遷移します。',
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                color: subTextColor,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                children: [
                  Text(
                    '次の対戦相手チーム名',
                    style: TextStyle(
                      fontSize: AppFontSize.bodyMedium,
                      fontWeight: AppFontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppTextField(
                    controller: _opponentTeamCtrl,
                    hintText: '例: ○○道場、△△中学校',
                    autofocus: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '対戦グループ / メモ (任意)',
                    style: TextStyle(
                      fontSize: AppFontSize.bodyMedium,
                      fontWeight: AppFontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppTextField(
                    controller: _groupNameCtrl,
                    hintText: '例: 申し合わせ 第2試合 (空欄可)',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? context.appColors.primaryAccent.withValues(
                              alpha: 0.1,
                            )
                          : context.appColors.primaryAccent.withValues(
                              alpha: 0.05,
                            ),
                      borderRadius: AppRadius.medium,
                      border: Border.all(
                        color: context.appColors.primaryAccent.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: context.appColors.primaryAccent,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '引き継がれる設定',
                              style: TextStyle(
                                fontSize: AppFontSize.bodySmall,
                                fontWeight: AppFontWeight.bold,
                                color: context.appColors.primaryAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildInheritItem(
                          '自チーム名',
                          myTeam,
                          context,
                          highlight: true,
                        ),
                        _buildInheritItem(
                          'オーダー人数',
                          '$positionCount 名',
                          context,
                        ),
                        if (widget.currentMatch.rule != null) ...[
                          _buildInheritItem(
                            '試合時間',
                            '${widget.currentMatch.rule!.matchTimeMinutes} 分',
                            context,
                          ),
                          _buildInheritItem(
                            '延長ルール',
                            widget.currentMatch.rule!.isEnchoUnlimited
                                ? '無制限延長'
                                : (widget.currentMatch.rule!.enchoCount > 0
                                      ? '${widget.currentMatch.rule!.enchoTimeMinutes.toInt()}分 延長'
                                      : '延長なし'),
                            context,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _handleStartNextMatch,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'このオーダーで第1試合を開始',
                style: TextStyle(
                  fontSize: AppFontSize.bodyMedium,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppKendoColors.ipponGold,
                foregroundColor: AppKendoColors.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                elevation: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildInheritItem(
    String label,
    String value,
    BuildContext context, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppFontSize.caption,
              color: context.appColors.subTextColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
              color: highlight
                  ? const Color(0xFFD97706)
                  : context.appColors.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
