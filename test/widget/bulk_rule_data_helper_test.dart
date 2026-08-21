import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_data_helper.dart';

void main() {
  group('🛡️ BulkRuleDataHelper Unit Tests', () {
    test('1. BulkRuleDataHelper correctly resolves match types', () {
      final teamMatch = MatchModel(
        id: 'm1',
        matchType: '団体戦',
        redName: '青龍館: 山田',
        whiteName: '白虎館: 佐藤',
      );
      final indivMatch = MatchModel(
        id: 'm2',
        matchType: '個人戦',
        redName: '山田',
        whiteName: '佐藤',
      );
      final leagueMatch = MatchModel(
        id: 'm3',
        matchType: '個人戦',
        redName: '山田',
        whiteName: '佐藤',
        note: '予選リーグ戦 1組',
      );

      expect(BulkRuleDataHelper.getResolvedType(teamMatch), '団体戦');
      expect(BulkRuleDataHelper.getResolvedType(indivMatch), '個人戦');
      expect(BulkRuleDataHelper.getResolvedType(leagueMatch), 'リーグ個人戦');
    });

    test('2. BulkRuleDataHelper groups matches into units correctly', () {
      final matches = [
        MatchModel(
          id: 'm1',
          matchType: '団体戦',
          groupName: '1回戦 第1試合',
          category: '中学生の部',
          redName: '青龍館: 山田',
          whiteName: '白虎館: 佐藤',
        ),
        MatchModel(
          id: 'm2',
          matchType: '団体戦',
          groupName: '1回戦 第1試合',
          category: '中学生の部',
          redName: '青龍館: 鈴木',
          whiteName: '白虎館: 田中',
        ),
        MatchModel(
          id: 'm3',
          matchType: '個人戦',
          category: '一般の部',
          redName: '高橋',
          whiteName: '伊藤',
        ),
      ];

      final units = BulkRuleDataHelper.buildGroupUnits(matches);
      expect(units.length, 2);

      final teamUnit = units.firstWhere((u) => u.resolvedType == '団体戦');
      expect(teamUnit.matchIds.length, 2);
      expect(teamUnit.category, '中学生の部');

      final indivUnit = units.firstWhere((u) => u.resolvedType == '個人戦');
      expect(indivUnit.matchIds.length, 1);
      expect(indivUnit.category, '一般の部');
    });
  });
}
