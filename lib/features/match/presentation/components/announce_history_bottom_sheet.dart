import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/match/domain/announce_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

/// 🌟 既読にしたアナウンスIDのローカル状態を管理・永続化するプロバイダー
final readAnnouncementsProvider =
    StateNotifierProvider<ReadAnnouncementsNotifier, List<String>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return ReadAnnouncementsNotifier(prefs);
    });

class ReadAnnouncementsNotifier extends StateNotifier<List<String>> {
  final SharedPreferences _prefs;
  static const _key = 'kendo_os_read_announcements';

  ReadAnnouncementsNotifier(this._prefs)
    : super(_prefs.getStringList(_key) ?? []);

  Future<void> markAsRead(String id) async {
    if (!state.contains(id)) {
      final updated = [...state, id];
      state = updated;
      await _prefs.setStringList(_key, updated);
    }
  }

  Future<void> markAllAsRead(List<String> ids) async {
    final List<String> updated = List.from(state);
    bool changed = false;
    for (final id in ids) {
      if (!updated.contains(id)) {
        updated.add(id);
        changed = true;
      }
    }
    if (changed) {
      state = updated;
      await _prefs.setStringList(_key, updated);
    }
  }
}

class AnnounceHistoryBottomSheet extends ConsumerStatefulWidget {
  final String tournamentId;
  final bool isStaffRoom;

  const AnnounceHistoryBottomSheet({
    super.key,
    required this.tournamentId,
    required this.isStaffRoom,
  });

  static void show(
    BuildContext context,
    String tournamentId,
    bool isStaffRoom,
  ) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AnnounceHistoryBottomSheet(
        tournamentId: tournamentId,
        isStaffRoom: isStaffRoom,
      ),
    );
  }

  @override
  ConsumerState<AnnounceHistoryBottomSheet> createState() =>
      _AnnounceHistoryBottomSheetState();
}

class _AnnounceHistoryBottomSheetState
    extends ConsumerState<AnnounceHistoryBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🛡️ Safe Firestore Instance (prevents crashes in tests)
    FirebaseFirestore firestore;
    try {
      firestore = ref.read(firestoreProvider);
    } catch (_) {
      firestore = FirebaseFirestore.instance;
    }

    // 🛡️ 送り分けクエリ：一般閲覧者（isStaffRoom == false）なら staff 限定通知を完全に排除して安全防衛
    Query query = firestore
        .collection('announcements')
        .where('tournamentId', isEqualTo: widget.tournamentId)
        .orderBy('timestamp', descending: true);

    if (!widget.isStaffRoom) {
      query = query.where('target', isEqualTo: 'all');
    }

    final readIds = ref.watch(readAnnouncementsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white, // 90%のクリーンな白ベース
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final allIds = docs.map((d) => d.id).toList();
          final unreadIds = allIds
              .where((id) => !readIds.contains(id))
              .toList();

          return Column(
            children: [
              // ボトムシートの引手（インジケータ）
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: isDark ? Colors.white : const Color(0xFF2C3E50),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.isStaffRoom ? '新着通知一覧 (スタッフ専用)' : '新着通知一覧',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: AppFontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF2C3E50),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 🌟 未読があれば「すべて既読にする」ボタンを表示
                    if (unreadIds.isNotEmpty)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: const Color(0xFFFF69B4),
                        ),
                        onPressed: () {
                          ref
                              .read(readAnnouncementsProvider.notifier)
                              .markAllAsRead(unreadIds);
                        },
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text(
                          'すべて既読',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(child: _buildList(context, snapshot, readIds)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    AsyncSnapshot<QuerySnapshot> snapshot,
    List<String> readIds,
  ) {
    if (snapshot.hasError) {
      return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
      return const Center(
        child: Text('新しい通知はありません', style: TextStyle(color: Colors.grey)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: snapshot.data!.docs.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final doc = snapshot.data!.docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final announce = AnnounceModel.fromJson({...data, 'id': doc.id});

        // ローカル既読キャッシュ（SharedPreferences）にあれば既読とみなす
        final bool isRead = readIds.contains(announce.id);
        final bool isStaffOnly = data['target'] == 'staff';

        return InkWell(
          onTap: () {
            if (!isRead) {
              ref
                  .read(readAnnouncementsProvider.notifier)
                  .markAsRead(announce.id);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
              borderRadius: AppRadius.medium,
              border: Border.all(
                color: !isRead
                    ? const Color(0xFFFF69B4).withValues(
                        alpha: 0.4,
                      ) // 未読時はサクラピンクの淡い輪郭
                    : (isDark ? const Color(0xFF38383A) : Colors.grey.shade200),
                width: 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🌟 サクラピンク差し色ハック：未読の通知の左端にだけ「●ドット」を鮮やかに点火
                if (!isRead)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF69B4), // サクラピンク
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isStaffOnly ? '【スタッフ限定】' : announce.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: !isRead
                                    ? FontWeight.w900
                                    : AppFontWeight.bold,
                                color: isStaffOnly
                                    ? Colors.deepOrange
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(announce.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        announce.body,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 🌟 未読のアナウンスがある場合にサクラピンクのバッジ（赤丸）を右上へ点火するベルアイコンボタン
class NotificationBellButton extends ConsumerWidget {
  final String tournamentId;
  final bool isStaffRoom;
  final Color? color;

  const NotificationBellButton({
    super.key,
    required this.tournamentId,
    required this.isStaffRoom,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🛡️ Safe Firestore Instance (prevents crashes in tests where Firebase is not initialized)
    FirebaseFirestore? firestore;
    try {
      firestore = ref.read(firestoreProvider);
    } catch (_) {
      try {
        firestore = FirebaseFirestore.instance;
      } catch (_) {
        firestore = null;
      }
    }

    final Widget bellIcon = IconButton(
      icon: Icon(
        Icons.notifications_outlined,
        color:
            color ??
            (Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.indigo.shade900),
      ),
      tooltip: '通知履歴',
      onPressed: () =>
          AnnounceHistoryBottomSheet.show(context, tournamentId, isStaffRoom),
    );

    if (firestore == null) {
      return bellIcon;
    }

    Query query = firestore
        .collection('announcements')
        .where('tournamentId', isEqualTo: tournamentId);

    if (!isStaffRoom) {
      query = query.where('target', isEqualTo: 'all');
    }

    final readIds = ref.watch(readAnnouncementsProvider);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return bellIcon;

        // 🌟 既読リストに含まれないお知らせがあるかをローカルで判定
        final bool hasUnread = snapshot.data!.docs.any(
          (doc) => !readIds.contains(doc.id),
        );

        return Stack(
          alignment: Alignment.center,
          children: [
            bellIcon,
            if (hasUnread)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF69B4), // 🌟 差し色：サクラピンクの未読赤丸
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
