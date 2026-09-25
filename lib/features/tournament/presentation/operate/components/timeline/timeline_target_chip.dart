import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/presentation/components/announce_popup_manager.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

/// タイムラインアナウンス対象選択チップ
class TimelineTargetChip extends StatelessWidget {
  final Key? chipKey;
  final String label;
  final IconData icon;
  final Color activeColor;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const TimelineTargetChip({
    super.key,
    this.chipKey,
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        key: chipKey,
        onTap: onTap,
        borderRadius: AppRadius.small,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: isDark ? 0.25 : 0.15)
                : AppKendoColors.transparent,
            borderRadius: AppRadius.small,
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark
                        ? AppKendoColors.pureWhite.withValues(alpha: 0.1)
                        : AppKendoColors.pureBlack.withValues(alpha: 0.12)),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? activeColor : AppKendoColors.grey,
                ),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: isSelected
                        ? AppFontWeight.bold
                        : AppFontWeight.regular,
                    color: isSelected
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
    );
  }
}

/// アナウンスおよびコメント送信処理ヘルパー
class TimelineAnnounceSender {
  static Future<void> send({
    required BuildContext parentContext,
    required WidgetRef ref,
    required String tournamentId,
    required String category,
    required String groupName,
    required String? matchGroupId,
    required double order,
    required String title,
    required String body,
    required String target,
  }) async {
    final String commentText = title.isNotEmpty
        ? (body.isNotEmpty ? '$title\n$body' : title)
        : body;

    try {
      if (target != 'none') {
        FirebaseFirestore firestore;
        try {
          firestore = ref.read(firestoreProvider);
        } catch (_) {
          firestore = FirebaseFirestore.instance;
        }

        final String finalTitle = title.isNotEmpty ? title : '大会本部からのお知らせ';
        final String announceId = firestore
            .collection('announcements')
            .doc()
            .id;

        registerMySentAnnounceId(announceId);

        await firestore.collection('announcements').doc(announceId).set({
          'id': announceId,
          'tournamentId': tournamentId,
          'title': finalTitle,
          'body': body.isNotEmpty ? body : finalTitle,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'emergency',
          'target': target,
          'isRead': false,
          'createdBy': () {
            try {
              return FirebaseAuth.instance.currentUser?.uid;
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

      if (parentContext.mounted) {
        if (target == 'none') {
          AppSnackBar.showSuccess(parentContext, 'タイムラインにコメントを追加しました（通知なし）');
        } else if (target == 'staff') {
          AppSnackBar.showSuccess(parentContext, 'スタッフ限定業務連絡を発信しました');
        } else {
          AppSnackBar.showSuccess(parentContext, '全員向け緊急アナウンスを一斉配信しました');
        }
      }
    } catch (e) {
      debugPrint('🚨 [AnnounceDialog] 送信エラー: $e');
      if (parentContext.mounted) {
        AppSnackBar.showError(parentContext, '処理に失敗しました: ${e.toString()}');
      }
    }
  }
}
