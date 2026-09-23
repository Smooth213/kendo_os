import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_date_parser.dart';

void main() {
  group('TournamentDateParser Tests', () {
    test('令和表記の日時が西暦に正しく変換されること', () {
      final date = TournamentDateParser.extractDate('日時: 令和8年9月20日(日)');
      expect(date, isNotNull);
      expect(date!.year, equals(2026));
      expect(date.month, equals(9));
      expect(date.day, equals(20));
    });

    test('西暦表記の日時が正しくパースされること', () {
      final date = TournamentDateParser.extractDate('開催日：2026年11月3日（祝）');
      expect(date, isNotNull);
      expect(date!.year, equals(2026));
      expect(date.month, equals(11));
      expect(date.day, equals(3));
    });

    test('スラッシュ区切りの日付がパースされること', () {
      final date = TournamentDateParser.extractDate('2026/10/15 9:00開始');
      expect(date, isNotNull);
      expect(date!.year, equals(2026));
      expect(date.month, equals(10));
      expect(date.day, equals(15));
    });

    test('全角数字が半角数字に正規化されること', () {
      final normalized = TournamentDateParser.normalizeNumbers('令和８年１２月２５日');
      expect(normalized, equals('令和8年12月25日'));
    });
  });
}
