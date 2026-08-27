import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/presentation/components/announce_popup_manager.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// タイムライン用 公式アナウンス・コメントの一斉発信ダイアログ
class TimelineUnifiedAnnounceDialog {
  static void show(
    BuildContext context,
    WidgetRef ref,
    String tournamentId,
    String category,
    String groupName,
    double order, {
    String? matchGroupId,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isBunaiksen = tournamentId.startsWith('bunaiksen_');
    final themeColors = AppThemeColors.ofMode(
      isDark: isDark,
      mode: isBunaiksen ? 'bunaiksen' : 'normal',
    );
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String selectedTarget = 'all';

    showAppDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AppDialog(
              backgroundColor: isDark
                  ? const Color(0xFF1C1C1E)
                  : context.appColors.inputBackground,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
              titleWidget: Row(
                children: [
                  const Icon(Icons.add_alert, color: Color(0xFFFF69B4)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '公式アナウンス・コメントの一斉発信',
                      style: TextStyle(
                        fontSize: AppFontSize.subhead,
                        fontWeight: AppFontWeight.bold,
                        color: context.appColors.textColor,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      controller: titleController,
                      style: TextStyle(color: context.appColors.textColor),
                      decoration: const InputDecoration(
                        labelText: 'タイトル（例：【緊急】会場変更）',
                        hintText: '空欄の場合は自動で見出しになります',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: bodyController,
                      maxLines: 3,
                      style: TextStyle(color: context.appColors.textColor),
                      decoration: const InputDecoration(
                        labelText: 'アナウンス本文内容',
                        hintText: '例：3会場へ移動になりました。選手は速やかに移動してください。',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF242426)
                            : const Color(0xFFF2F2F7),
                        borderRadius: AppRadius.medium,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              key: const Key('timeline_target_all_chip'),
                              onTap: () {
                                setDialogState(() => selectedTarget = 'all');
                              },
                              borderRadius: AppRadius.small,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                  horizontal: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedTarget == 'all'
                                      ? const Color(0xFFFF69B4).withValues(
                                          alpha: isDark ? 0.25 : 0.15,
                                        )
                                      : AppKendoColors.transparent,
                                  borderRadius: AppRadius.small,
                                  border: Border.all(
                                    color: selectedTarget == 'all'
                                        ? const Color(0xFFFF69B4)
                                        : (isDark
                                              ? AppKendoColors.pureWhite
                                                    .withValues(alpha: 0.1)
                                              : AppKendoColors.pureBlack
                                                    .withValues(alpha: 0.12)),
                                    width: selectedTarget == 'all' ? 1.5 : 1.0,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.campaign,
                                        size: 15,
                                        color: selectedTarget == 'all'
                                            ? const Color(0xFFFF69B4)
                                            : AppKendoColors.grey,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '全員に通知',
                                        style: TextStyle(
                                          fontSize: AppFontSize.small,
                                          fontWeight: selectedTarget == 'all'
                                              ? AppFontWeight.bold
                                              : AppFontWeight.regular,
                                          color: selectedTarget == 'all'
                                              ? (isDark
                                                    ? AppKendoColors.pureWhite
                                                    : AppKendoColors.pureBlack)
                                              : AppKendoColors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: InkWell(
                              key: const Key('timeline_target_staff_chip'),
                              onTap: () {
                                setDialogState(() => selectedTarget = 'staff');
                              },
                              borderRadius: AppRadius.small,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                  horizontal: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedTarget == 'staff'
                                      ? AppKendoColors.deepOrange.withValues(
                                          alpha: isDark ? 0.25 : 0.15,
                                        )
                                      : AppKendoColors.transparent,
                                  borderRadius: AppRadius.small,
                                  border: Border.all(
                                    color: selectedTarget == 'staff'
                                        ? AppKendoColors.deepOrange
                                        : (isDark
                                              ? AppKendoColors.pureWhite
                                                    .withValues(alpha: 0.1)
                                              : AppKendoColors.pureBlack
                                                    .withValues(alpha: 0.12)),
                                    width: selectedTarget == 'staff'
                                        ? 1.5
                                        : 1.0,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        size: 14,
                                        color: selectedTarget == 'staff'
                                            ? AppKendoColors.deepOrange
                                            : AppKendoColors.grey,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'スタッフ限定',
                                        style: TextStyle(
                                          fontSize: AppFontSize.small,
                                          fontWeight: selectedTarget == 'staff'
                                              ? AppFontWeight.bold
                                              : AppFontWeight.regular,
                                          color: selectedTarget == 'staff'
                                              ? (isDark
                                                    ? AppKendoColors.pureWhite
                                                    : AppKendoColors.pureBlack)
                                              : AppKendoColors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: InkWell(
                              key: const Key('timeline_target_none_chip'),
                              onTap: () {
                                setDialogState(() => selectedTarget = 'none');
                              },
                              borderRadius: AppRadius.small,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                  horizontal: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedTarget == 'none'
                                      ? AppKendoColors.blue.withValues(
                                          alpha: isDark ? 0.25 : 0.15,
                                        )
                                      : AppKendoColors.transparent,
                                  borderRadius: AppRadius.small,
                                  border: Border.all(
                                    color: selectedTarget == 'none'
                                        ? AppKendoColors.blue
                                        : (isDark
                                              ? AppKendoColors.pureWhite
                                                    .withValues(alpha: 0.1)
                                              : AppKendoColors.pureBlack
                                                    .withValues(alpha: 0.12)),
                                    width: selectedTarget == 'none' ? 1.5 : 1.0,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.notifications_off_outlined,
                                        size: 14,
                                        color: selectedTarget == 'none'
                                            ? AppKendoColors.blue
                                            : AppKendoColors.grey,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '通知なし',
                                        style: TextStyle(
                                          fontSize: AppFontSize.small,
                                          fontWeight: selectedTarget == 'none'
                                              ? AppFontWeight.bold
                                              : AppFontWeight.regular,
                                          color: selectedTarget == 'none'
                                              ? (isDark
                                                    ? AppKendoColors.pureWhite
                                                    : AppKendoColors.pureBlack)
                                              : AppKendoColors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(color: AppKendoColors.grey),
                  ),
                ),
                ElevatedButton.icon(
                  key: const Key('timeline_submit_announce_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColors.primaryAccent,
                    foregroundColor: AppKendoColors.pureWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.small,
                    ),
                  ),
                  onPressed: () {
                    final String title = titleController.text.trim();
                    final String body = bodyController.text.trim();
                    if (body.isEmpty && title.isEmpty) return;

                    final String commentText = title.isNotEmpty
                        ? (body.isNotEmpty ? '$title\n$body' : title)
                        : body;

                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }

                    Future(() async {
                      try {
                        if (selectedTarget != 'none') {
                          FirebaseFirestore firestore;
                          try {
                            firestore = ref.read(firestoreProvider);
                          } catch (_) {
                            firestore = FirebaseFirestore.instance;
                          }

                          final String finalTitle = title.isNotEmpty
                              ? title
                              : '大会本部からのお知らせ';

                          final String announceId = firestore
                              .collection('announcements')
                              .doc()
                              .id;

                          registerMySentAnnounceId(announceId);

                          await firestore
                              .collection('announcements')
                              .doc(announceId)
                              .set({
                                'id': announceId,
                                'tournamentId': tournamentId,
                                'title': finalTitle,
                                'body': body.isNotEmpty ? body : finalTitle,
                                'timestamp': FieldValue.serverTimestamp(),
                                'type': 'emergency',
                                'target': selectedTarget,
                                'isRead': false,
                                'createdBy': () {
                                  try {
                                    return FirebaseAuth
                                        .instance
                                        .currentUser
                                        ?.uid;
                                  } catch (_) {
                                    return null;
                                  }
                                }(),
                              });
                        }

                        // タイムラインコメント保存
                        await ref
                            .read(commentCommandProvider)
                            .addComment(
                              tournamentId: tournamentId,
                              category: category,
                              groupName: groupName,
                              matchGroupId: matchGroupId,
                              text: commentText,
                              order: order,
                            );

                        if (context.mounted) {
                          if (selectedTarget == 'none') {
                            AppSnackBar.showSuccess(
                              context,
                              'タイムラインにコメントを追加しました（通知なし）',
                            );
                          } else if (selectedTarget == 'staff') {
                            AppSnackBar.showSuccess(
                              context,
                              'スタッフ限定業務連絡を発信しました',
                            );
                          } else {
                            AppSnackBar.showSuccess(
                              context,
                              '全員向け緊急アナウンスを一斉配信しました',
                            );
                          }
                        }
                      } catch (e) {
                        debugPrint('🚨 [AnnounceDialog] 送信エラー: $e');
                        if (context.mounted) {
                          AppSnackBar.showError(
                            context,
                            '処理に失敗しました: ${e.toString()}',
                          );
                        }
                      }
                    });
                  },
                  icon: Icon(
                    selectedTarget == 'none'
                        ? Icons.chat_bubble_outline
                        : Icons.campaign,
                    size: 18,
                  ),
                  label: Text(
                    selectedTarget == 'none' ? 'コメントを保存' : '一斉発信して保存',
                    style: const TextStyle(fontWeight: AppFontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
