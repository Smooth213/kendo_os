import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/announce_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
  // ローカルで既読化した通知のIDをキャッシュ（UIの即時反映用防壁）
  final Set<String> _localReadIds = {};

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

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white, // 90%のクリーンな白ベース
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: isDark ? Colors.white : const Color(0xFF2C3E50),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isStaffRoom ? '新着通知一覧 (スタッフ専用)' : '新着通知一覧',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      '新しい通知はありません',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final announce = AnnounceModel.fromJson({
                      ...data,
                      'id': doc.id,
                    });

                    // Firestore上のフラグ、またはローカル既読キャッシュにあれば既読とみなす
                    final bool isRead =
                        announce.isRead || _localReadIds.contains(announce.id);
                    final bool isStaffOnly = data['target'] == 'staff';

                    return InkWell(
                      onTap: () {
                        if (!isRead) {
                          setState(() {
                            _localReadIds.add(announce.id);
                          });
                          // Firestore側へも既読フラグを安全に書き込み
                          firestore
                              .collection('announcements')
                              .doc(announce.id)
                              .update({'isRead': true});
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !isRead
                                ? const Color(0xFFFF69B4).withValues(
                                    alpha: 0.4,
                                  ) // 未読時はサクラピンクの淡い輪郭
                                : (isDark
                                      ? const Color(0xFF38383A)
                                      : Colors.grey.shade200),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🌟 サクラピンク差し色ハック：未読の通知の左端にだけ「●ドット」を鮮やかに点火
                            if (!isRead)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  right: 8,
                                ),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          isStaffOnly
                                              ? '【スタッフ限定】'
                                              : announce.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: !isRead
                                                ? FontWeight.w900
                                                : FontWeight.bold,
                                            color: isStaffOnly
                                                ? Colors.deepOrange
                                                : (isDark
                                                      ? Colors.white
                                                      : Colors.black87),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'HH:mm',
                                        ).format(announce.timestamp),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
