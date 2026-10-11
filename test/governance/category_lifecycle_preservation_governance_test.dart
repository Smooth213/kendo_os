import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_share_data.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_parser.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart';

void main() {
  group('[Governance] 大会部門ライフサイクル非破壊永続化保証規約', () {
    test('全大分類および小分類の組み合わせから生成される部門名がresolveCategoryで100パーセント非破壊で保持されること', () {
      final allMajors = [
        ...TeamRegistrationCategoryStep.mainMajorCategories,
        ...TeamRegistrationCategoryStep.extraMajorCategories,
      ];

      for (final major in allMajors) {
        final minors = TeamRegistrationCategoryStep.getMinorCategories(major);
        for (final minor in minors) {
          final formattedCat =
              TeamRegistrationCategoryParser.formatCategoryName(
                majorCategory: major,
                minorCategory: minor,
              );

          final team = ParsedTeamOrder(
            teamName: '検証チーム',
            category: formattedCat,
            matchType: '個人戦',
            members: const [ParsedTeamMember(position: '選手', name: '選手名')],
          );

          final resolved = TournamentTeamAutoRegisterService.resolveCategory(
            team,
          );

          expect(
            resolved,
            equals(formattedCat),
            reason:
                '$major × $minor ($formattedCat) が resolveCategory で別名へ縮退・書き換えされずに保持されること',
          );
        }
      }

      // カスタム部門名（その他）の完全維持検証
      const customNames = ['東西対抗オープンの部', '小中学生混成錬成の部', '一般親善の部'];
      for (final customCat in customNames) {
        final team = ParsedTeamOrder(
          teamName: 'カスタム検証チーム',
          category: customCat,
          matchType: '団体戦（5人制）',
          members: const [ParsedTeamMember(position: '先鋒', name: '選手A')],
        );
        final resolved = TournamentTeamAutoRegisterService.resolveCategory(
          team,
        );
        expect(
          resolved,
          equals(customCat),
          reason: 'カスタム部門名 ($customCat) が強制上書きされず正確に維持されること',
        );
      }
    });

    test('全4箇所の登録編集コンポーネントにおいてCategorySelectionBottomSheetが永続統合されていること', () {
      final uiFiles = [
        'lib/features/tournament/presentation/operate/components/create_tournament/create_tournament_import_teams_card.dart',
        'lib/features/tournament/presentation/components/share_import/share_import_edit_sheets.dart',
        'lib/features/tournament/presentation/operate/components/team_registration/team_registration_confirm_step.dart',
        'lib/features/tournament/presentation/operate/components/team_registration/team_edit_basic_fields.dart',
      ];

      for (final filePath in uiFiles) {
        final file = File(filePath);
        expect(file.existsSync(), isTrue, reason: '必須ファイルが存在しません: $filePath');
        final content = file.readAsStringSync();
        expect(
          content.contains('CategorySelectionBottomSheet'),
          isTrue,
          reason:
              '$filePath に CategorySelectionBottomSheet の呼び出しが欠落しており選択肢縮退のリスクがあります',
        );
      }
    });

    test('テキストパースから抽出された短縮カテゴリ文字列が正式部門名へ安全に解決されること', () {
      final legacyKeywords = {
        '中学生': '中学生の部',
        '高校生': '高校生の部',
        '小学生': '小学生の部',
        '小学生低学年': '小学生低学年の部',
        '小学生高学年': '小学生高学年の部',
        '一般': '一般の部',
      };

      legacyKeywords.forEach((keyword, expectedOfficialName) {
        final team = ParsedTeamOrder(
          teamName: 'キーワード所属選手',
          category: keyword,
          matchType: '個人戦',
          members: const [ParsedTeamMember(position: '選手', name: '選手X')],
        );

        final resolved = TournamentTeamAutoRegisterService.resolveCategory(
          team,
        );
        expect(
          resolved,
          equals(expectedOfficialName),
          reason: '$keyword から $expectedOfficialName への正規化が安全に実行されること',
        );
      });
    });
  });
}
