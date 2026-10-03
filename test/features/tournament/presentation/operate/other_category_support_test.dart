import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_category_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_form_state.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_parser.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_player_filter_helper.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Unit] 試合カテゴリその他（混成・自由入力）のロジック・パーサー検証', () {
    test('MatchFormatSetupHelperにその他カテゴリと小分類が含まれること', () {
      expect(MatchFormatSetupHelper.majorCategories.contains('その他'), isTrue);
      final minors = MatchFormatSetupHelper.getMinorCategories('その他');
      expect(minors.contains('混成'), isTrue);
      expect(minors.contains('混合'), isTrue);
      expect(minors.contains('自由'), isTrue);
      expect(minors.contains('全体'), isTrue);
    });

    test(
      'MatchFormatSetupHelperのparseCategoryToStateでその他・混成・カスタム名が正しく復元されること',
      () {
        expect(MatchFormatSetupHelper.parseCategoryToState('その他の部'), (
          'その他',
          '全体',
        ));
        expect(MatchFormatSetupHelper.parseCategoryToState('混成の部'), (
          'その他',
          '混成',
        ));
        expect(MatchFormatSetupHelper.parseCategoryToState('混合の部'), (
          'その他',
          '混合',
        ));
        expect(MatchFormatSetupHelper.parseCategoryToState('小中学生混成の部'), (
          'その他',
          '直接入力',
        ));
      },
    );

    test('MatchFormatFormStateでその他選択時およびカスタム名入力時に正しいカテゴリ名が生成されること', () {
      final state = MatchFormatFormState();
      state.selectedMajorCategory = 'その他';
      state.selectedMinorCategory = '混成';
      expect(state.getCategory(), '混成の部');

      state.customCategoryName = '小中学生混成';
      expect(state.getCategory(), '小中学生混成の部');

      state.customCategoryName = '地区対抗オープンの部';
      expect(state.getCategory(), '地区対抗オープンの部');
    });

    test('TeamRegistrationCategoryParserでその他およびカスタム名が正しくフォーマット・パースされること', () {
      expect(
        TeamRegistrationCategoryParser.formatCategoryName(
          majorCategory: 'その他',
          minorCategory: '混成',
        ),
        '混成の部',
      );
      expect(
        TeamRegistrationCategoryParser.formatCategoryName(
          majorCategory: 'その他',
          minorCategory: '全体',
        ),
        'その他の部',
      );

      final parsedCustom = TeamRegistrationCategoryParser.parseCategoryToState(
        '小中学生混成の部',
      );
      expect(parsedCustom.majorCategory, 'その他');
      expect(parsedCustom.minorCategory, '小中学生混成');
    });

    test('TeamRegistrationPlayerFilterHelperでその他カテゴリ時は全学年の選手が適合判定されること', () {
      final pLow = PlayerModel(
        id: '1',
        lastName: '低学年',
        firstName: '選手',
        lastNameKana: 'ていがくねん',
        firstNameKana: 'せんしゅ',
        grade: 2,
      );
      final pHigh = PlayerModel(
        id: '2',
        lastName: '高学年',
        firstName: '男子',
        lastNameKana: 'こうがくねん',
        firstNameKana: 'だんし',
        grade: 6,
      );
      final pJuniorF = PlayerModel(
        id: '3',
        lastName: '中学生',
        firstName: '女子',
        lastNameKana: 'ちゅうがくせい',
        firstNameKana: 'じょし',
        gender: '女子',
        grade: 8,
      );
      final pJuniorM = PlayerModel(
        id: '4',
        lastName: '中学生',
        firstName: '男子',
        lastNameKana: 'ちゅうがくせい',
        firstNameKana: 'だんし',
        grade: 9,
      );
      final pAdult = PlayerModel(
        id: '5',
        lastName: '一般',
        firstName: '選手',
        lastNameKana: 'いっぱん',
        firstNameKana: 'せんしゅ',
        grade: 14,
      );

      // 小学生カテゴリの場合は学年外の選手は false
      expect(
        TeamRegistrationPlayerFilterHelper.isSameCategory(
          player: pJuniorM,
          majorCategory: '小学生',
          minorCategory: '低学年',
        ),
        isFalse,
      );

      // 「その他」カテゴリの場合は全学年が true となること！
      for (final p in [pLow, pHigh, pJuniorF, pJuniorM, pAdult]) {
        expect(
          TeamRegistrationPlayerFilterHelper.isSameCategory(
            player: p,
            majorCategory: 'その他',
            minorCategory: '混成',
          ),
          isTrue,
          reason: '${p.name} (学年:${p.grade}) はその他カテゴリに適合する必要があります',
        );
      }
    });
  });

  group('試合カテゴリその他UI表示・入力検証', () {
    testWidgets('MatchFormatCategoryStepでその他選択時にカスタム部門名入力フィールドが表示されること', (
      tester,
    ) async {
      String? changedCustomName;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MatchFormatCategoryStep(
                tournamentId: 'test_t1',
                category: '小中学生混成の部',
                selectedMajorCategory: 'その他',
                selectedMinorCategory: '混成',
                customCategoryName: '小中学生混成',
                onCustomCategoryChanged: (val) => changedCustomName = val,
                selectedTeamId: null,
                majorCategories: MatchFormatSetupHelper.majorCategories,
                getMinorCategories: MatchFormatSetupHelper.getMinorCategories,
                onCategoryChanged: (maj, min) {},
                onTeamSelected: (_) {},
                onAdjustOrder: (_) {},
                onEditTeam: (_) {},
                onDeleteTeam: (_) {},
                onNavigateToTeamRegistration: () {},
                themeColors: AppThemeColors.ofMode(
                  isDark: false,
                  mode: 'normal',
                ),
                isDark: false,
                buildSectionTitle: (title) => Text(title),
              ),
            ),
          ),
        ),
      );

      // カスタム部門名入力欄が存在すること
      expect(find.text('カスタム部門名を入力（任意）'), findsOneWidget);
      expect(find.text('小中学生混成'), findsOneWidget);

      // 入力変更できること
      await tester.enterText(find.byType(TextFormField), 'オープン混成');
      expect(changedCustomName, 'オープン混成');
    });

    testWidgets('TeamRegistrationCategoryStepでその他選択時にカスタム部門名入力欄が表示されること', (
      tester,
    ) async {
      String? changedCustomName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamRegistrationCategoryStep(
              selectedMajorCategory: 'その他',
              selectedMinorCategory: '混成',
              selectedCategory: '小中学生混成の部',
              customCategoryName: '小中学生混成',
              onCustomCategoryChanged: (val) => changedCustomName = val,
              matchType: '団体戦（5人制）',
              showExtraMajorCategories: true,
              showExtraMatchTypes: false,
              themeColors: AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              onMajorCategoryChanged: (_) {},
              onMinorCategoryChanged: (_) {},
              onMatchTypeChanged: (_) {},
              onToggleExtraMajorCategories: () {},
              onToggleExtraMatchTypes: () {},
            ),
          ),
        ),
      );

      expect(find.text('カスタム部門名を入力（任意）'), findsOneWidget);
      expect(find.text('小中学生混成'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '東西対抗混成');
      expect(changedCustomName, '東西対抗混成');
    });
  });
}
