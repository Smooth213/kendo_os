import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/features/match/domain/announce_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';

/// 🌟 各画面の最外殻でアナウンスのFirestoreを監視し、ポップアップを安全に制御する関数
void listenGlobalAnnouncements(
  BuildContext context,
  WidgetRef ref,
  String tournamentId,
) {
  try {
    final settings = ref.read(settingsProvider);
    // ユーザーの設定で「緊急通知ポップアップ」がOFFにされている場合は、ストリーム監視自体をスキップして防衛
    if (!settings.notifyOnEmergency) return;

    // すでにポップアップ表示済みのIDをセッション内で重複ガード
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
          final announce = AnnounceModel.fromJson({
            ...doc.data(),
            'id': doc.id,
          });

          // 🌟 重複表示の防止、および過去30分以上前の古いアナウンスはポップアップ対象から除外する時間防壁
          final bool isRecent =
              DateTime.now().difference(announce.timestamp).inMinutes < 30;
          if (shownAnnounceIds.contains(announce.id) || !isRecent) return;

          shownAnnounceIds.add(announce.id);

          // 🌟 A4縦型マニュアル・デザイン規約（白ベース×ピンク差し色）を100%継承した格調高いダイアログ
          showDialog(
            context: context,
            barrierDismissible: false, // 現場での見逃しを防ぐため、枠外タップでの離脱を厳禁化
            builder: (ctx) {
              final isDark = Theme.of(ctx).brightness == Brightness.dark;

              return AlertDialog(
                backgroundColor: isDark
                    ? const Color(0xFF1C1C1E)
                    : Colors.white, // 90%のクリーンな白ベース
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    const Icon(
                      Icons.campaign,
                      color: Color(0xFFFF69B4), // 🌟 差し色：サクラピンクで最重要アラートをハック
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        announce.title.isNotEmpty
                            ? announce.title
                            : '大会本部からのお知らせ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF2C3E50),
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
                        ), // 引き締め役のTealグリーン
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
