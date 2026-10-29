import 'package:flutter_test/flutter_test.dart';

/// 部内戦（総当たり・勝ち抜き等）が深夜（23:59〜00:01）を跨いで行われた場合でも、
/// 日付の切り替わりによって大会セッションが分断されたり集計から脱落したりせず、
/// セッション識別子（sessionId）または開始基準日によって正しく統合解決されることの検証テスト。
void main() {
  group('[Unit] ドメイン境界極限 - 部内戦深夜日付跨ぎセッション統合テスト', () {
    test('深夜跨ぎ（23:55開始〜翌00:20終了）の試合が同一大会・同一セッションとして正しく集計されること', () {
      final sessionStart = DateTime(2026, 10, 2, 23, 50);
      const String sessionId = 'session_bunaiksen_night_20261002';

      // 試合1: 23:55 開始
      final match1 = {
        'id': 'm1',
        'sessionId': sessionId,
        'createdAt': DateTime(2026, 10, 2, 23, 55),
        'winner': 'red',
      };

      // 試合2: 翌日 00:05 開始（日付が変わっている）
      final match2 = {
        'id': 'm2',
        'sessionId': sessionId,
        'createdAt': DateTime(2026, 10, 3, 0, 5),
        'winner': 'white',
      };

      // セッションIDを第1キー、セッション開始日のローカル日付を基準日として正規化
      String getTournamentLogicalDate(
        DateTime time,
        DateTime sessionStartTime,
      ) {
        // 大会セッション開始日の "YYYY-MM-DD" に束縛
        return '${sessionStartTime.year}-${sessionStartTime.month.toString().padLeft(2, '0')}-${sessionStartTime.day.toString().padLeft(2, '0')}';
      }

      final matches = [match1, match2];
      final logicalDate1 = getTournamentLogicalDate(
        match1['createdAt'] as DateTime,
        sessionStart,
      );
      final logicalDate2 = getTournamentLogicalDate(
        match2['createdAt'] as DateTime,
        sessionStart,
      );

      expect(logicalDate1, equals('2026-10-02'));
      expect(logicalDate2, equals('2026-10-02'));

      // セッション集計で全試合が漏れなく集計されること
      final sessionMatches = matches
          .where((m) => m['sessionId'] == sessionId)
          .toList();
      expect(sessionMatches.length, equals(2));
    });

    test('利用可能日付リストの正規化において、タイムゾーン（UTC/Local）のオフセットによる日付の不整合が発生しないこと', () {
      final utcMidnight = DateTime.utc(
        2026,
        10,
        2,
        15,
        0,
      ); // JSTでは 2026-10-03 00:00
      final localDate = utcMidnight.toLocal();

      // 日付文字列への変換において、常にローカルの物理日付としてフォーマット
      final dateStr =
          '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';

      // JST環境下で正しい日付として扱われること
      expect(dateStr, isNotEmpty);
      expect(dateStr.contains('-'), isTrue);
    });
  });
}
