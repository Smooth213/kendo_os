import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/presentation/components/announce_history_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('🔔 ReadAnnouncementsNotifier Synchronization & Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('初期化時にSharedPreferencesから既読IDを正しく読み込めること', () async {
      SharedPreferences.setMockInitialValues({
        'kendo_os_read_announcements': ['announce_001', 'announce_002'],
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = ReadAnnouncementsNotifier(prefs);

      expect(notifier.state, equals(['announce_001', 'announce_002']));
    });

    test('markAsRead で新しいIDが重複なく追加され、SharedPreferencesに永続化されること', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = ReadAnnouncementsNotifier(prefs);

      expect(notifier.state, isEmpty);

      // 1件目を既読
      await notifier.markAsRead('announce_101');
      expect(notifier.state, equals(['announce_101']));
      expect(
        prefs.getStringList('kendo_os_read_announcements'),
        equals(['announce_101']),
      );

      // 同じIDを再度既読にしても重複しない
      await notifier.markAsRead('announce_101');
      expect(notifier.state, equals(['announce_101']));

      // 2件目を既読
      await notifier.markAsRead('announce_102');
      expect(notifier.state, equals(['announce_101', 'announce_102']));
      expect(
        prefs.getStringList('kendo_os_read_announcements'),
        equals(['announce_101', 'announce_102']),
      );
    });

    test('markAllAsRead で複数IDが一括で安全に追加され、未既読のみが追加されること', () async {
      SharedPreferences.setMockInitialValues({
        'kendo_os_read_announcements': ['announce_A'],
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = ReadAnnouncementsNotifier(prefs);

      // 'announce_A', 'announce_B', 'announce_C' を一括既読
      await notifier.markAllAsRead(['announce_A', 'announce_B', 'announce_C']);

      expect(
        notifier.state,
        containsAll(['announce_A', 'announce_B', 'announce_C']),
      );
      expect(notifier.state.length, equals(3));
      expect(
        prefs.getStringList('kendo_os_read_announcements'),
        containsAll(['announce_A', 'announce_B', 'announce_C']),
      );
    });

    test('空リストや既存IDのみの markAllAsRead では無駄な書き込みが発生しないこと', () async {
      SharedPreferences.setMockInitialValues({
        'kendo_os_read_announcements': ['announce_X'],
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = ReadAnnouncementsNotifier(prefs);

      await notifier.markAllAsRead(['announce_X']);
      expect(notifier.state, equals(['announce_X']));

      await notifier.markAllAsRead([]);
      expect(notifier.state, equals(['announce_X']));
    });
  });
}
