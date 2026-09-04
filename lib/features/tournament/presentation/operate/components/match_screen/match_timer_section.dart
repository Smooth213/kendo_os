import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/renseikai_master_timer_widget.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/timer_widget.dart';

/// 試合画面のタイマー表示セクション（通常タイマー / 錬成会マスタータイマー併用）
class MatchTimerSection extends StatelessWidget {
  final MatchModel match;
  final MatchRule rule;
  final bool isInputLocked;

  const MatchTimerSection({
    super.key,
    required this.match,
    required this.rule,
    required this.isInputLocked,
  });

  @override
  Widget build(BuildContext context) {
    final isRenseikaiTimeBased =
        rule.isRenseikai && rule.renseikaiType == '時間制';

    Widget content;
    if (isRenseikaiTimeBased) {
      content = Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 2,
          horizontal: AppSpacing.lg,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: TimerWidget(
                  matchId: match.id,
                  isInputLocked: isInputLocked,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: RenseikaiMasterTimerWidget(
                  groupName: match.groupName ?? '',
                  isInputLocked: isInputLocked,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      content = TimerWidget(matchId: match.id, isInputLocked: isInputLocked);
    }

    // 🎨 【Phase 3】RepaintBoundaryによるタイマー描画の完全分離
    return RepaintBoundary(child: content);
  }
}
