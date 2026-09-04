import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/match/domain/announce_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';

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
  final bool isFullScreen;

  const AnnounceHistoryBottomSheet({
    super.key,
    required this.tournamentId,
    required this.isStaffRoom,
    this.isFullScreen = false,
  });

  static void show(
    BuildContext context,
    String tournamentId,
    bool isStaffRoom,
  ) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: AppKendoColors.transparent,
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
    final title = widget.isStaffRoom ? 'お知らせ (スタッフ専用)' : 'お知らせ一覧';

    final streamWidget = StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final allIds = docs.map((d) => d.id).toList();
        final unreadIds = allIds.where((id) => !readIds.contains(id)).toList();

        final markAllButton = unreadIds.isNotEmpty
            ? TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppKendoColors.pink,
                ),
                onPressed: () {
                  ref
                      .read(readAnnouncementsProvider.notifier)
                      .markAllAsRead(unreadIds);
                },
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text(
                  'すべて既読',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              )
            : null;

        if (widget.isFullScreen) {
          return Scaffold(
            backgroundColor: isDark
                ? const Color(0xFF1C1C1E)
                : context.appColors.cardBackground,
            appBar: AppHeader(
              title: title,
              actions: [
                ?markAllButton,
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
            body: _buildList(context, snapshot, readIds),
          );
        }

        return Column(
          children: [
            DockBottomSheetHeader(
              title: title,
              icon: Icons.notifications_active_outlined,
              iconColor: AppKendoColors.pink,
              extraActions: markAllButton != null ? [markAllButton] : null,
              onFullScreen: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => AnnounceHistoryBottomSheet(
                      tournamentId: widget.tournamentId,
                      isStaffRoom: widget.isStaffRoom,
                      isFullScreen: true,
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            Expanded(child: _buildList(context, snapshot, readIds)),
          ],
        );
      },
    );

    if (widget.isFullScreen) {
      return streamWidget;
    }

    return DockDraggableSheet(
      backgroundColor: isDark
          ? const Color(0xFF1C1C1E)
          : context.appColors.cardBackground,
      builder: (context, scrollController) => streamWidget,
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
        child: Text(
          '新しい通知はありません',
          style: TextStyle(color: AppKendoColors.grey),
        ),
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
            padding: const EdgeInsets.all(AppSpacing.modernValue),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
              borderRadius: AppRadius.medium,
              border: Border.all(
                color: !isRead
                    ? const Color(0xFFFF69B4).withValues(
                        alpha: 0.4,
                      ) // 未読時はサクラピンクの淡い輪郭
                    : (isDark
                          ? const Color(0xFF38383A)
                          : const Color(0x33000000)),
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
                      top: AppSpacing.xs,
                      right: AppSpacing.sm,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isStaffOnly ? '【スタッフ限定】' : announce.title,
                              style: TextStyle(
                                fontSize: AppFontSize.body,
                                fontWeight: !isRead
                                    ? AppFontWeight.black
                                    : AppFontWeight.bold,
                                color: isStaffOnly
                                    ? AppKendoColors.deepOrange
                                    : (isDark
                                          ? const Color(0xFFFFFFFF)
                                          : const Color(0xFF000000)),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(announce.timestamp),
                            style: const TextStyle(
                              fontSize: AppFontSize.caption,
                              color: AppKendoColors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        announce.body,
                        style: TextStyle(
                          fontSize: AppFontSize.bodySmall,
                          height: 1.4,
                          color: isDark
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xDE000000),
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
                ? AppKendoColors.pureWhite
                : context.appColors.primaryAccent),
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
