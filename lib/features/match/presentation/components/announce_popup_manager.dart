import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/features/match/domain/announce_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';

/// 🌟 各画面の最外殻でアナウンスのFirestoreを監視し、全員向け/スタッフ向けの送り分けを安全に制御する
void listenGlobalAnnouncements(
  BuildContext context,
  WidgetRef ref,
  String tournamentId, {
  required bool isStaffRoom,
}) {
  try {
    final settings = ref.read(settingsProvider);
    if (!settings.notifyOnEmergency) return;

    // ポップアップ表示済みのIDを重複ガード
    final Set<String> shownAnnounceIds = {};

    final firestore = ref.read(firestoreProvider);

    firestore
        .collection('announcements')
        .where('tournamentId', isEqualTo: tournamentId)
        .where('type', isEqualTo: 'emergency')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isEmpty) return;

          final doc = snapshot.docs.first;
          final data = doc.data();

          // 🌟 送り分けターゲットの抽出（デフォルトは全員向け 'all'）
          final String target = data['target'] as String? ?? 'all';

          // 🛡️ 防衛線：スタッフ限定通知（staff）であり、かつ現在の画面が観客席（isStaffRoom == false）なら完全スルー
          if (target == 'staff' && !isStaffRoom) {
            debugPrint(
              '🛡️ [PopupManager] スタッフ限定アナウンスを検知したため、観客席でのポップアップをスキップしました。',
            );
            return;
          }

          final announce = AnnounceModel.fromJson({...data, 'id': doc.id});

          // 過去30分以上前の古いアナウンスはポップアップ対象から除外する時間防壁
          final bool isRecent =
              DateTime.now().difference(announce.timestamp).inMinutes < 30;
          if (shownAnnounceIds.contains(announce.id) || !isRecent) return;

          shownAnnounceIds.add(announce.id);

          // 🌟 白ベース×サクラピンク差し色の格調高いダイアログ
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              final isDark = Theme.of(ctx).brightness == Brightness.dark;
              final bool isStaffOnlyNotice = target == 'staff';

              return AlertDialog(
                backgroundColor: isDark
                    ? const Color(0xFF1C1C1E)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(
                      isStaffOnlyNotice ? Icons.security : Icons.campaign,
                      color: const Color(0xFFFF69B4), // 🌟 差し色：サクラピンク
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isStaffOnlyNotice
                            ? '【スタッフ限定業務連絡】'
                            : (announce.title.isNotEmpty
                                  ? announce.title
                                  : '大会本部からのお知らせ'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isStaffOnlyNotice
                              ? Colors.deepOrange
                              : (isDark
                                    ? Colors.white
                                    : const Color(0xFF2C3E50)),
                        ),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  announce.body,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark
                        ? Colors.grey.shade300
                        : const Color(0xFF2C3E50),
                  ),
                ),
                actions: [
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF00796B,
                        ), // 引き締めTealグリーン
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        '内容を確認しました',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        });
  } catch (e) {
    debugPrint(
      '⚠️ [listenGlobalAnnouncements] Firestore connection skipped: $e',
    );
  }
}
