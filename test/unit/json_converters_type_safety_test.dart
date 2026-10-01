import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/infrastructure/persistence/converters/json_converters.dart';

void main() {
  group('[Unit] 型揺れ吸収ゼロクラッシュコンバータ単体テスト', () {
    test('TimestampConverterにおいて多様な入力型から安全にDateTimeへ復元されること', () {
      const converter = TimestampConverter();
      final fixedDate = DateTime(2026, 10, 1, 12, 0, 0);

      // Timestamp 型
      final fromTs = converter.fromJson(Timestamp.fromDate(fixedDate));
      expect(fromTs, fixedDate);

      // ISO8601 文字列型
      final fromStr = converter.fromJson(fixedDate.toIso8601String());
      expect(fromStr, fixedDate);

      // ミリ秒 int 型
      final fromMillis = converter.fromJson(fixedDate.millisecondsSinceEpoch);
      expect(fromMillis, fixedDate);

      // null や不正な値に対する安全フォールバック（例外を投げない）
      final fromNull = converter.fromJson(null);
      expect(fromNull, isA<DateTime>());

      final fromInvalid = converter.fromJson(true);
      expect(fromInvalid, isA<DateTime>());

      // toJson の出力型検証
      final jsonResult = converter.toJson(fixedDate);
      expect(jsonResult, isA<Timestamp>());
      expect((jsonResult as Timestamp).toDate(), fixedDate);
    });

    test('DoubleConverterにおいて整数小数文字列の型揺れを吸収し安全にパースされること', () {
      const converter = DoubleConverter();

      // int -> double
      expect(converter.fromJson(10), 10.0);

      // double -> double
      expect(converter.fromJson(12.5), 12.5);

      // String -> double
      expect(converter.fromJson('3.14'), 3.14);
      expect(converter.fromJson('invalid_string'), 0.0);

      // null / 不正型 -> 0.0
      expect(converter.fromJson(null), 0.0);
      expect(converter.fromJson([1, 2, 3]), 0.0);

      // toJson の値保持
      expect(converter.toJson(4.5), 4.5);
    });
  });
}
