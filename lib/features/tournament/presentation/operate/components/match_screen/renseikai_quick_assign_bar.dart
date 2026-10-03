import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_data_helper.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// ⚔️ 錬成会（4人編成等の空欄枠用）クイック選手アサインバー
/// 相手の5人目に対して自チーム選手をワンタップで選んで試合を継続可能にする
class RenseikaiQuickAssignBar extends StatelessWidget {
  final MatchModel match;
  final MatchRule rule;
  final List<MatchModel> teamMatches;
  final bool isDark;
  final WidgetRef ref;
  final Future<void> Function(MatchModel updatedMatch)? onAssignPlayer;

  const RenseikaiQuickAssignBar({
    super.key,
    required this.match,
    required this.rule,
    required this.teamMatches,
    required this.isDark,
    required this.ref,
    this.onAssignPlayer,
  });

  @override
  Widget build(BuildContext context) {
    if (!rule.isRenseikai || !rule.skipEmptyRoster) {
      return const SizedBox.shrink();
    }

    final redPlayer = MatchEditDataHelper.extractPlayerName(match.redName);
    final whitePlayer = MatchEditDataHelper.extractPlayerName(match.whiteName);

    final bool isRedEmpty = _isNamePlaceholder(redPlayer);
    final bool isWhiteEmpty = _isNamePlaceholder(whitePlayer);

    // どちらのサイドも未定でない場合でも、錬成会で4人編成の場合は控えめな変更UIを提供
    final targetSide = isRedEmpty
        ? 'red'
        : (isWhiteEmpty
              ? 'white'
              : (rule.teamName.isNotEmpty &&
                        match.redName.startsWith(rule.teamName)
                    ? 'red'
                    : 'white'));

    // teamMatches から登録されている選手名を抽出
    final Set<String> candidatePlayers = {};
    for (final m in teamMatches) {
      final p1 = MatchEditDataHelper.extractPlayerName(m.redName);
      final p2 = MatchEditDataHelper.extractPlayerName(m.whiteName);
      if (!_isNamePlaceholder(p1)) candidatePlayers.add(p1);
      if (!_isNamePlaceholder(p2)) candidatePlayers.add(p2);
    }

    if (candidatePlayers.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentTargetName = targetSide == 'red' ? redPlayer : whitePlayer;
    final currentTargetTeam = targetSide == 'red'
        ? MatchEditDataHelper.extractTeamName(match.redName, '', true)
        : MatchEditDataHelper.extractTeamName(match.whiteName, '', true);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: (isRedEmpty || isWhiteEmpty)
              ? AppKendoColors.orange
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: (isRedEmpty || isWhiteEmpty) ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            (isRedEmpty || isWhiteEmpty)
                ? Icons.person_add_alt_1_rounded
                : Icons.swap_horiz_rounded,
            size: 16,
            color: (isRedEmpty || isWhiteEmpty)
                ? AppKendoColors.orange
                : context.appColors.subTextColor,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            (isRedEmpty || isWhiteEmpty) ? '出場選手を選択:' : '選手切替:',
            style: TextStyle(
              fontSize: AppFontSize.nano,
              fontWeight: AppFontWeight.bold,
              color: (isRedEmpty || isWhiteEmpty)
                  ? AppKendoColors.orange
                  : context.appColors.subTextColor,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final pName in candidatePlayers)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: AppChoiceChip(
                        selected: currentTargetName == pName,
                        label: Text(pName),
                        onSelected: (selected) async {
                          if (selected) {
                            HapticFeedback.mediumImpact();
                            final newFullName = currentTargetTeam.isNotEmpty
                                ? '$currentTargetTeam : $pName'
                                : pName;
                            final updatedMatch = targetSide == 'red'
                                ? match.copyWith(redName: newFullName)
                                : match.copyWith(whiteName: newFullName);
                            if (onAssignPlayer != null) {
                              await onAssignPlayer!(updatedMatch);
                            } else {
                              await ref
                                  .read(matchApplicationServiceProvider)
                                  .saveMatch(updatedMatch);
                            }
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isNamePlaceholder(String name) {
    final t = name.trim();
    return t.isEmpty ||
        t == '未定' ||
        t == '選手' ||
        t == '欠員' ||
        t.contains('未定') ||
        t.contains('要選択');
  }
}
