import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_parser.dart';

void main() {
  group('TeamRegistrationCategoryParser Tests', () {
    test('formatCategoryName formats categories correctly', () {
      expect(
        TeamRegistrationCategoryParser.formatCategoryName(
          majorCategory: '小学生',
          minorCategory: '高学年',
        ),
        '小学生高学年の部',
      );
      expect(
        TeamRegistrationCategoryParser.formatCategoryName(
          majorCategory: '初心者',
          minorCategory: '全体',
        ),
        '初心者の部',
      );
      expect(
        TeamRegistrationCategoryParser.formatCategoryName(
          majorCategory: '中学生',
          minorCategory: '全体',
        ),
        '中学生の部',
      );
      expect(
        TeamRegistrationCategoryParser.formatCategoryName(
          majorCategory: '大学・一般',
          minorCategory: '大学生',
        ),
        '大学生の部',
      );
    });

    test('parseCategoryToState parses saved category strings correctly', () {
      final res1 = TeamRegistrationCategoryParser.parseCategoryToState(
        '小学生高学年の部',
      );
      expect(res1.majorCategory, '小学生');
      expect(res1.minorCategory, '高学年');

      final res2 = TeamRegistrationCategoryParser.parseCategoryToState('初心者の部');
      expect(res2.majorCategory, '初心者');
      expect(res2.minorCategory, '全体');

      final res3 = TeamRegistrationCategoryParser.parseCategoryToState('一般の部');
      expect(res3.majorCategory, '大学・一般');
      expect(res3.minorCategory, '一般');
    });
  });
}
