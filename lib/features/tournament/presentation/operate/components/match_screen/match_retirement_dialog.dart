import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 🥋 途中棄権（負傷・事故等による不戦勝・相手2本付与）入力ダイアログ
class MatchRetirementDialog extends ConsumerStatefulWidget {
  final MatchModel match;
  final String? currentUserId;
  final bool isDark;

  const MatchRetirementDialog({
    super.key,
    required this.match,
    required this.currentUserId,
    required this.isDark,
  });

  static Future<void> show(
    BuildContext context, {
    required MatchModel match,
    required String? currentUserId,
    required bool isDark,
  }) {
    return showAppDialog(
      context: context,
      builder: (ctx) => MatchRetirementDialog(
        match: match,
        currentUserId: currentUserId,
        isDark: isDark,
      ),
    );
  }

  @override
  ConsumerState<MatchRetirementDialog> createState() =>
      _MatchRetirementDialogState();
}

class _MatchRetirementDialogState extends ConsumerState<MatchRetirementDialog> {
  Side? _selectedRetiredSide;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final rName = match.redName.isNotEmpty ? match.redName : '赤';
    final wName = match.whiteName.isNotEmpty ? match.whiteName : '白';

    return AppDialog(
      title: '途中棄権の記録',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '試合中に負傷または体調不良等で継続できなくなった選手を選択してください。',
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                color: context.appColors.textColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF9FAFB),
                borderRadius: AppRadius.medium,
                border: Border.all(color: context.appColors.separatorColor),
              ),
              child: Column(
                children: [
                  _buildSideTile(
                    side: Side.red,
                    playerName: rName,
                    teamColor: AppKendoColors.hansokuRed,
                    sideLabel: '赤 側が棄権',
                  ),
                  const Divider(height: AppSpacing.sm),
                  _buildSideTile(
                    side: Side.white,
                    playerName: wName,
                    teamColor: AppKendoColors.pureWhite,
                    sideLabel: '白 側が棄権',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.appColors.warningColor.withValues(alpha: 0.12),
                borderRadius: AppRadius.small,
                border: Border.all(
                  color: context.appColors.warningColor.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: context.appColors.warningColor,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '全日本剣道連盟ルールに基づき、相手側に不戦勝（2本）が付与され、試合が終了します。',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.semiBold,
                        color: widget.isDark
                            ? AppKendoColors.pureWhite
                            : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _selectedRetiredSide == null || _isSubmitting
              ? null
              : () async {
                  setState(() => _isSubmitting = true);
                  try {
                    await ref
                        .read(matchCommandProvider)
                        .recordRetirement(
                          match: widget.match,
                          retiredSide: _selectedRetiredSide!,
                          userId: widget.currentUserId,
                        );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      setState(() => _isSubmitting = false);
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appColors.errorColor,
            foregroundColor: AppKendoColors.pureWhite,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppKendoColors.pureWhite,
                  ),
                )
              : const Text(
                  '棄権を確定して終了',
                  style: TextStyle(fontWeight: AppFontWeight.bold),
                ),
        ),
      ],
    );
  }

  Widget _buildSideTile({
    required Side side,
    required String playerName,
    required Color teamColor,
    required String sideLabel,
  }) {
    final isSelected = _selectedRetiredSide == side;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRetiredSide = side;
        });
      },
      borderRadius: AppRadius.small,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? context.appColors.errorColor.withValues(alpha: 0.15)
              : AppKendoColors.transparent,
          borderRadius: AppRadius.small,
          border: Border.all(
            color: isSelected
                ? context.appColors.errorColor
                : AppKendoColors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: teamColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppKendoColors.grey, width: 0.5),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sideLabel,
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                      color: side == Side.red
                          ? AppKendoColors.hansokuRed
                          : (widget.isDark
                                ? AppKendoColors.pureWhite
                                : const Color(0xFF333333)),
                    ),
                  ),
                  Text(
                    playerName,
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      fontWeight: AppFontWeight.bold,
                      color: context.appColors.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? context.appColors.errorColor
                  : context.appColors.separatorColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
