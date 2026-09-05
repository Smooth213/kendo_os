import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_edit_comment_dialog.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// タイムライン内の内部見出し（コメント）ウィジェット
class TimelineInnerCommentWidget extends StatelessWidget {
  final MatchCommentModel comment;
  final AppPermissions permissions;
  final bool isDark;
  final WidgetRef ref;

  const TimelineInnerCommentWidget({
    super.key,
    required this.comment,
    required this.permissions,
    required this.isDark,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final commentWidget = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0x33000000),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.label_outline,
            color: isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000),
            size: 16,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              comment.text,
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                fontWeight: AppFontWeight.bold,
                color: isDark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xDE000000),
              ),
            ),
          ),
        ],
      ),
    );

    if (!permissions.canManageTournament) {
      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        child: commentWidget,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Slidable(
        key: ValueKey('slidable_inner_comment_${comment.id}'),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            CustomSlidableAction(
              onPressed: (ctx) =>
                  TimelineEditCommentDialog.show(context, ref, comment),
              backgroundColor: AppKendoColors.blueAccent,
              foregroundColor: AppKendoColors.pureWhite,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 16, color: AppKendoColors.pureWhite),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    '編集',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                      color: AppKendoColors.pureWhite,
                    ),
                  ),
                ],
              ),
            ),
            CustomSlidableAction(
              onPressed: (ctx) async {
                final confirm = await showAppDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AppDialog(
                    backgroundColor: isDark
                        ? const Color(0xFF1C1C1E)
                        : context.appColors.inputBackground,
                    titleWidget: Text(
                      '内部見出しの削除',
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        color: context.appColors.textColor,
                      ),
                    ),
                    content: Text(
                      'この見出しを削除しますか？\n(取り消せません)',
                      style: TextStyle(color: context.appColors.textColor),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: const Text(
                          'キャンセル',
                          style: TextStyle(color: AppKendoColors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: const Text(
                          '削除',
                          style: TextStyle(
                            color: AppKendoColors.red,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(commentCommandProvider)
                      .deleteComment(comment.id, comment.tournamentId ?? '');
                }
              },
              backgroundColor: AppKendoColors.redAccent,
              foregroundColor: AppKendoColors.pureWhite,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(AppRadius.smallValue),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete, size: 16, color: AppKendoColors.pureWhite),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    '削除',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                      color: AppKendoColors.pureWhite,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        child: commentWidget,
      ),
    );
  }
}
