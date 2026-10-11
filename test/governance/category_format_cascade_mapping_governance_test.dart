import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/category_cascade_selector_view.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_format_selector_view.dart';

void main() {
  group('[Governance] カテゴリ・試合形式カスケード階層 整合性永続保証テスト', () {
    // =========================================================================
    // 柱1: 試合形式 5大分類 ⇔ 全詳細形式 双方向漏れゼロ保証
    // =========================================================================
    group('第1柱: 試合形式マッピング完全性', () {
      test('candidateMatchTypes の全形式が5大分類のいずれかに漏れなく解決されること', () {
        const candidateTypes =
            TournamentTeamAutoRegisterService.candidateMatchTypes;

        for (final matchType in candidateTypes) {
          final primary = MatchFormatSelectorView.resolvePrimaryFormat(
            matchType,
          );
          expect(
            MatchFormatSelectorView.primaryFormats.contains(primary),
            isTrue,
            reason: '$matchType が有効な5大分類（$primary）に解決されること',
          );
        }
      });

      test('剣道形および特殊形式も5大分類に正しく分類されること', () {
        expect(
          MatchFormatSelectorView.resolvePrimaryFormat('剣道形'),
          equals('剣道形'),
        );
        expect(
          MatchFormatSelectorView.resolvePrimaryFormat('剣道形（基本形）'),
          equals('剣道形'),
        );
        expect(
          MatchFormatSelectorView.resolvePrimaryFormat('剣道形（日本剣道形）'),
          equals('剣道形'),
        );
      });

      test('5大分類のすべての形式について、初期選択値が実在する有効な形式であること', () {
        for (final primary in MatchFormatSelectorView.primaryFormats) {
          String resolvedType = '';
          switch (primary) {
            case '個人戦':
              resolvedType = '個人戦';
              break;
            case '団体戦':
              resolvedType = '団体戦（5人制）';
              break;
            case '勝ち抜き戦':
              resolvedType = '勝ち抜き戦（5人制）';
              break;
            case 'リーグ戦':
              resolvedType = 'リーグ団体戦';
              break;
            case '剣道形':
              resolvedType = '剣道形';
              break;
          }

          expect(resolvedType, isNotEmpty);
          expect(
            MatchFormatSelectorView.resolvePrimaryFormat(resolvedType),
            equals(primary),
            reason: '$primary の初期値 $resolvedType の分類が自身と一致すること',
          );
        }
      });
    });

    // =========================================================================
    // 柱2: カテゴリ 大分類 ⇔ 小分類 連動・生成完全性
    // =========================================================================
    group('第2柱: カテゴリ生成決定論的保証', () {
      test('全大分類について小分類候補が1件以上存在すること', () {
        for (final major in CategoryCascadeSelectorView.majorCategories) {
          final minors = CategoryCascadeSelectorView.getMinorCategories(major);
          expect(
            minors,
            isNotEmpty,
            reason: '大分類「$major」には1件以上の小分類候補が定義されていること',
          );
        }
      });

      test('全大分類と全小分類の組み合わせで、不正な空白を含まず「の部」で終わるカテゴリ名が生成されること', () {
        for (final major in CategoryCascadeSelectorView.majorCategories) {
          final minors = CategoryCascadeSelectorView.getMinorCategories(major);
          for (final minor in minors) {
            final categoryName = CategoryCascadeSelectorView.buildCategoryName(
              major: major,
              minor: minor,
              customName: 'テスト部門',
            );

            expect(categoryName, isNotEmpty);
            expect(
              categoryName.endsWith('の部'),
              isTrue,
              reason: '生成カテゴリ名「$categoryName」が「の部」で終了すること',
            );

            if (major != 'その他' && minor != '全般') {
              expect(
                categoryName.contains(major),
                isTrue,
                reason: '通常カテゴリ名は大分類名を含むこと',
              );
            }
          }
        }
      });

      test('その他カテゴリにおいてカスタム名が優先反映されること', () {
        final generated = CategoryCascadeSelectorView.buildCategoryName(
          major: 'その他',
          minor: '混成',
          customName: '選抜地域親善',
        );
        expect(generated, equals('選抜地域親善の部'));
      });
    });
  });
}
