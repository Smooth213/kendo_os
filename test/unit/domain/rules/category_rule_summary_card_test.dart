import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_summary_card.dart';

void main() {
  group('CategoryRuleSummaryCard.fmtMins - 時間フォーマット', () {
    test('0分 → 「時間制限なし」を返す', () {
      expect(CategoryRuleSummaryCard.fmtMins(0), '時間制限なし');
    });

    test('負の値 → 「時間制限なし」を返す', () {
      expect(CategoryRuleSummaryCard.fmtMins(-1), '時間制限なし');
    });

    test('整数の分 → 「N分」を返す', () {
      expect(CategoryRuleSummaryCard.fmtMins(3), '3分');
      expect(CategoryRuleSummaryCard.fmtMins(5), '5分');
      expect(CategoryRuleSummaryCard.fmtMins(10), '10分');
    });

    test('0.5分 → 「0分30秒」を返す', () {
      expect(CategoryRuleSummaryCard.fmtMins(0.5), '0分30秒');
    });

    test('2.5分 → 「2分30秒」を返す', () {
      expect(CategoryRuleSummaryCard.fmtMins(2.5), '2分30秒');
    });

    test('3.75分 → 「3分45秒」を返す', () {
      expect(CategoryRuleSummaryCard.fmtMins(3.75), '3分45秒');
    });
  });
}
