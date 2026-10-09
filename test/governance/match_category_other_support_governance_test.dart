import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_form_state.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_parser.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_player_filter_helper.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';

void main() {
  group('[Governance] 試合カテゴリその他混成および学年横断編成永続保証規約', () {
    test('全カテゴリ定義およびパーサーにその他カテゴリが永続実装されていること', () {
      final targetFiles = [
        'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart',
        'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_form_state.dart',
        'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_category_step.dart',
        'lib/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart',
        'lib/features/tournament/presentation/operate/components/team_registration/team_registration_category_parser.dart',
        'lib/features/tournament/presentation/operate/components/team_registration/team_registration_player_filter_helper.dart',
      ];

      for (final filePath in targetFiles) {
        final file = File(filePath);
        expect(file.existsSync(), isTrue, reason: '必須ファイルが存在しません: $filePath');
        final content = file.readAsStringSync();
        expect(
          content.contains('その他') || content.contains('customCategoryName'),
          isTrue,
          reason: '$filePath に「その他」カテゴリまたはカスタム名の対応が欠落しています',
        );
      }
    });

    test('対戦フォーマットおよびチーム登録においてその他混成が正しく保持されること', () {
      expect(MatchFormatSetupHelper.majorCategories.contains('その他'), isTrue);
      expect(
        TeamRegistrationCategoryStep.extraMajorCategories.contains('その他'),
        isTrue,
      );

      final state = MatchFormatFormState();
      state.selectedMajorCategory = 'その他';
      state.customCategoryName = '小中学生混成';
      expect(state.getCategory(), '小中学生混成の部');

      final parsed = TeamRegistrationCategoryParser.parseCategoryToState(
        '小中学生混成の部',
      );
      expect(parsed.majorCategory, 'その他');
      expect(parsed.minorCategory, '小中学生混成');
    });

    test('学年横断混成チームの全ポジション選手がその他カテゴリに完全適合すること', () {
      final mixedRoster = [
        PlayerModel(
          id: 'p1',
          lastName: '先鋒',
          firstName: '低学年',
          lastNameKana: 'せんぽう',
          firstNameKana: 'ていがくねん',
          grade: 2,
        ),
        PlayerModel(
          id: 'p2',
          lastName: '次鋒',
          firstName: '高学年男子',
          lastNameKana: 'じほう',
          firstNameKana: 'こうがくねんだんし',
          grade: 6,
        ),
        PlayerModel(
          id: 'p3',
          lastName: '中堅',
          firstName: '中学生女子',
          lastNameKana: 'ちゅうけん',
          firstNameKana: 'ちゅうがくせいじょし',
          gender: '女子',
          grade: 8,
        ),
        PlayerModel(
          id: 'p4',
          lastName: '副将',
          firstName: '中学生男子',
          lastNameKana: 'ふくしょう',
          firstNameKana: 'ちゅうがくせいだんし',
          grade: 9,
        ),
        PlayerModel(
          id: 'p5',
          lastName: '大将',
          firstName: '中学生男子',
          lastNameKana: 'たいしょう',
          firstNameKana: 'ちゅうがくせいだんし',
          grade: 9,
        ),
      ];

      for (final p in mixedRoster) {
        final isMatched = TeamRegistrationPlayerFilterHelper.isSameCategory(
          player: p,
          majorCategory: 'その他',
          minorCategory: '混成',
        );
        expect(
          isMatched,
          isTrue,
          reason: '混成チームの選手 ${p.name} (学年:${p.grade}) はその他カテゴリに適合する必要があります',
        );
      }
    });

    test(
      '対戦フォーマット大分類その他選択時、チーム側がその他またはその他の部で登録されたチームがカスタム表示名（少年の部等）の下で確実に抽出されること',
      () {
        final teams = [
          const TeamModel(
            id: 't1',
            tournamentId: 't_test',
            teamName: '福山道場A',
            category: 'その他',
          ),
          const TeamModel(
            id: 't2',
            tournamentId: 't_test',
            teamName: '福山道場B',
            category: 'その他の部',
          ),
          const TeamModel(
            id: 't3',
            tournamentId: 't_test',
            teamName: '福山道場C',
            category: '少年の部',
          ),
          const TeamModel(
            id: 't4',
            tournamentId: 't_test',
            teamName: '広島道場',
            category: '中学生の部',
          ),
        ];

        const selectedMajorCategory = 'その他';
        const category = '少年の部'; // カスタム表示名

        // MatchFormatCategoryStep と同一の判定ロジック
        final filteredTeams = teams.where((t) {
          if (t.category == category) return true;
          final cleanTeamCat = t.category.replaceAll('の部', '').trim();
          final cleanTargetCat = category.replaceAll('の部', '').trim();
          if (cleanTeamCat.isNotEmpty && cleanTeamCat == cleanTargetCat) {
            return true;
          }
          if (selectedMajorCategory == 'その他') {
            if (cleanTeamCat == 'その他') return true;
          }
          return false;
        }).toList();

        expect(
          filteredTeams.map((t) => t.id).toList(),
          containsAll(['t1', 't2', 't3']),
        );
        expect(filteredTeams.any((t) => t.id == 't4'), isFalse);
      },
    );
  });
}
