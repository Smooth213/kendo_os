import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/announce_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/match/presentation/components/announce_history_bottom_sheet.dart';

// 🛡️ アクティブなストリームサブスクリプションを追跡（画面再構築時の重複購読を完全に防止）
final Map<String, StreamSubscription> _activeSubscriptions = {};

// 表示済みのポップアップID（同一IDの再表示を完全に防止）
final Set<String> _shownAnnounceIds = {};

// ポップアップダイアログ表示中フラグ（累積スタック・多重モーダルの発生を防止）
bool _isAnnounceDialogShowing = false;

/// 🛡️ テスト環境用の状態リセット関数
@visibleForTesting
void resetAnnouncePopupManager() {
  for (final sub in _activeSubscriptions.values) {
    sub.cancel();
  }
  _activeSubscriptions.clear();
  _shownAnnounceIds.clear();
  _isAnnounceDialogShowing = false;
}

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

    final key = '${tournamentId}_$isStaffRoom';
    if (_activeSubscriptions.containsKey(key)) {
      return; // 🛡️ 防衛線：既にこの画面種別でストリーム購読済みの場合は即時リターン（重複を回避）
    }

    final firestore = ref.read(firestoreProvider);

    final subscription = firestore
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

          // 🛡️ 防衛線：既にローカルで既読済みのアナウンスである場合はポップアップを表示しない
          final readIds = ref.read(readAnnouncementsProvider);
          if (announce.isRead || readIds.contains(announce.id)) return;

          // 過去30分以上前の古いアナウンスはポップアップ対象から除外する時間防壁
          final bool isRecent =
              DateTime.now().difference(announce.timestamp).inMinutes < 30;
          if (_shownAnnounceIds.contains(announce.id) || !isRecent) return;

          // 🛡️ 防衛線：既にポップアップ表示中であるか、画面がアンマウントされていれば表示をスキップ
          if (_isAnnounceDialogShowing || !context.mounted) return;

          _shownAnnounceIds.add(announce.id);
          _isAnnounceDialogShowing = true;

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
                    const Icon(
                      Icons.campaign,
                      color: Color(0xFFFF69B4), // 🌟 差し色：サクラピンク
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
                      onPressed: () {
                        // 🌟 既読にしたことを端末ローカルに保存（再度画面に入った際に表示させないため）
                        ref
                            .read(readAnnouncementsProvider.notifier)
                            .markAsRead(announce.id);
                        _isAnnounceDialogShowing = false;
                        Navigator.pop(ctx);
                      },
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

    _activeSubscriptions[key] = subscription;
  } catch (e) {
    debugPrint(
      '⚠️ [listenGlobalAnnouncements] Firestore connection skipped: $e',
    );
  }
}
