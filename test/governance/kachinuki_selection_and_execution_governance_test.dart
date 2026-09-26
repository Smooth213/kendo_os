import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/match_domain_service.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_share_data.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/tournament_share_import_cards.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_header_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_form_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_summary_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_import_teams_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_match_generator.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_edit_basic_fields.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
  const allCandidateTypes =
      TournamentTeamAutoRegisterService.candidateMatchTypes;

  Widget wrapWithScaffold(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('🥋 【勝ち抜き戦（5人制 / 3人制）】選択・適応・実行 総合保証テスト', () {
    // =========================================================================
    // 柱1: 【選択保証 (Selection Guarantee)】
    // =========================================================================
    group('第1柱: 全UI画面における選択保証', () {
      testWidgets(
        '1-1. [新規チーム登録] TeamRegistrationCategoryStep で「勝ち抜き戦（5人制）」「勝ち抜き戦（3人制）」が選択できること',
        (tester) async {
          String selectedType = '団体戦（5人制）';

          await tester.pumpWidget(
            wrapWithScaffold(
              TeamRegistrationCategoryStep(
                selectedMajorCategory: '小学生',
                selectedMinorCategory: '高学年',
                selectedCategory: '小学生高学年の部',
                matchType: selectedType,
                showExtraMajorCategories: false,
                showExtraMatchTypes: false,
                themeColors: themeColors,
                onMajorCategoryChanged: (_) {},
                onMinorCategoryChanged: (_) {},
                onMatchTypeChanged: (type) => selectedType = type,
                onToggleExtraMajorCategories: () {},
                onToggleExtraMatchTypes: () {},
              ),
            ),
          );

          // メインチップとして両形式が表示されていること
          expect(find.text('勝ち抜き戦（5人制）'), findsOneWidget);
          expect(find.text('勝ち抜き戦（3人制）'), findsOneWidget);

          // 3人制をタップして選択
          await tester.tap(find.text('勝ち抜き戦（3人制）'));
          await tester.pump();
          expect(selectedType, equals('勝ち抜き戦（3人制）'));

          // 5人制をタップして選択
          await tester.tap(find.text('勝ち抜き戦（5人制）'));
          await tester.pump();
          expect(selectedType, equals('勝ち抜き戦（5人制）'));
        },
      );

      testWidgets(
        '1-2. [チーム編集] TeamEditBasicFields で「勝ち抜き戦（5人制）」「勝ち抜き戦（3人制）」が描画され選択切り替えできること',
        (tester) async {
          final controller = TextEditingController(text: 'テスト道場');
          String selectedType = '個人戦';

          await tester.pumpWidget(
            wrapWithScaffold(
              TeamEditBasicFields(
                teamNameController: controller,
                selectedCategory: '小学生',
                matchType: selectedType,
                candidateCategories: const ['小学生'],
                matchTypes: allCandidateTypes,
                themeColors: themeColors,
                borderColor: Colors.grey,
                onCategoryChanged: (_) {},
                onMatchTypeChanged: (type) => selectedType = type,
              ),
            ),
          );

          // チップが存在すること
          expect(find.text('勝ち抜き戦（5人制）'), findsOneWidget);
          expect(find.text('勝ち抜き戦（3人制）'), findsOneWidget);

          // 3人制を選択
          await tester.tap(find.text('勝ち抜き戦（3人制）'));
          await tester.pump();
          expect(selectedType, equals('勝ち抜き戦（3人制）'));

          // 5人制を選択
          await tester.tap(find.text('勝ち抜き戦（5人制）'));
          await tester.pump();
          expect(selectedType, equals('勝ち抜き戦（5人制）'));
        },
      );

      testWidgets(
        '1-3. [共有インポート] ShareImportTeamSection のボトムシートで新形式が選択反映されること',
        (tester) async {
          const team = ParsedTeamOrder(
            teamName: '道上剣友会',
            category: '小学生の部',
            members: [
              ParsedTeamMember(position: '先鋒', name: '選手A'),
              ParsedTeamMember(position: '中堅', name: '選手B'),
              ParsedTeamMember(position: '大将', name: '選手C'),
            ],
          );

          String? updatedType;

          await tester.pumpWidget(
            wrapWithScaffold(
              ShareImportTeamSection(
                team: team,
                accentColor: Colors.blue,
                textColor: Colors.black,
                subTextColor: Colors.grey,
                onMatchTypeUpdated: (type) => updatedType = type,
              ),
            ),
          );

          // 初期チップをタップしてボトムシートを開く
          await tester.tap(find.text('団体戦（3人制）'));
          await tester.pumpAndSettle();

          // ボトムシート内に両新形式が存在すること
          expect(find.text('勝ち抜き戦（5人制）'), findsWidgets);
          expect(find.text('勝ち抜き戦（3人制）'), findsWidgets);

          // 「勝ち抜き戦（3人制）」を選択
          await tester.tap(find.text('勝ち抜き戦（3人制）').last);
          await tester.pumpAndSettle();

          expect(updatedType, equals('勝ち抜き戦（3人制）'));
        },
      );

      testWidgets(
        '1-4. [大会作成] CreateTournamentImportTeamsCard のボトムシートで新形式が選択反映されること',
        (tester) async {
          const teams = [
            ParsedTeamOrder(
              teamName: '秋季勝ち抜きチーム',
              category: '中学生の部',
              members: [
                ParsedTeamMember(position: '先鋒', name: '選手1'),
                ParsedTeamMember(position: '中堅', name: '選手2'),
                ParsedTeamMember(position: '大将', name: '選手3'),
              ],
            ),
          ];

          List<ParsedTeamOrder>? resultTeams;

          await tester.pumpWidget(
            wrapWithScaffold(
              CreateTournamentImportTeamsCard(
                teams: teams,
                isEnabled: true,
                onToggle: (_) {},
                roster: const [],
                onTeamsUpdated: (updated) => resultTeams = updated,
              ),
            ),
          );

          // 自動判定されたチップ（勝ち抜き戦（3人制））をタップ
          expect(find.text('勝ち抜き戦（3人制）'), findsOneWidget);
          await tester.tap(find.text('勝ち抜き戦（3人制）'));
          await tester.pumpAndSettle();

          // 「勝ち抜き戦（5人制）」を選択
          await tester.tap(find.text('勝ち抜き戦（5人制）').last);
          await tester.pumpAndSettle();

          expect(resultTeams, isNotNull);
          expect(resultTeams!.first.matchType, equals('勝ち抜き戦（5人制）'));
        },
      );

      testWidgets(
        '1-5. [部門別ルール編集] CategoryRuleEditorHeaderCard のドロップダウンで新形式を選択できること',
        (tester) async {
          String currentMatchType = '団体戦';
          final subCtrl = TextEditingController();
          final commCtrl = TextEditingController();

          await tester.pumpWidget(
            wrapWithScaffold(
              CategoryRuleEditorHeaderCard(
                category: '中学生の部',
                matchType: currentMatchType,
                allCategoryRules: const {},
                textColor: Colors.black,
                subtitleController: subCtrl,
                commentController: commCtrl,
                isMultiScene: false,
                useAdvancedRule: false,
                onSubtitleChanged: (_) {},
                onCommentChanged: (_) {},
                onMatchTypeChanged: (type) => currentMatchType = type,
                onMultiSceneChanged: (_) {},
                onUseAdvancedRuleChanged: (_) {},
              ),
            ),
          );

          // ドロップダウンを開く
          await tester.tap(find.byType(DropdownButtonFormField<String>));
          await tester.pumpAndSettle();

          // 勝ち抜き戦（5人制）と勝ち抜き戦（3人制）が存在すること
          expect(find.text('勝ち抜き戦（5人制）').last, findsOneWidget);
          expect(find.text('勝ち抜き戦（3人制）').last, findsOneWidget);

          // 勝ち抜き戦（3人制）を選択
          await tester.tap(find.text('勝ち抜き戦（3人制）').last);
          await tester.pumpAndSettle();

          expect(currentMatchType, equals('勝ち抜き戦（3人制）'));
        },
      );
    });

    // =========================================================================
    // 柱2: 【適応保証 (Adaptation Guarantee)】
    // =========================================================================
    group('第2柱: スロット・ルール設定の適応保証', () {
      test('2-1. [スロット適応] 3人制と5人制で基準スロット定義および自動生成が正しく適応されること', () {
        final slots3 = TournamentTeamAutoRegisterService.getBaseSlots(
          '勝ち抜き戦（3人制）',
        );
        expect(slots3, equals(['先鋒', '中堅', '大将']));

        final slots5 = TournamentTeamAutoRegisterService.getBaseSlots(
          '勝ち抜き戦（5人制）',
        );
        expect(slots5, equals(['先鋒', '次鋒', '中堅', '副将', '大将']));

        // 名簿照合によるスロット配置
        final List<PlayerModel> roster = [
          PlayerModel(
            id: 'p1',
            lastName: '山田',
            firstName: '太郎',
            lastNameKana: 'やまだ',
            firstNameKana: 'たろう',
            grade: 4,
          ),
          PlayerModel(
            id: 'p2',
            lastName: '佐藤',
            firstName: '次郎',
            lastNameKana: 'さとう',
            firstNameKana: 'じろう',
            grade: 5,
          ),
          PlayerModel(
            id: 'p3',
            lastName: '鈴木',
            firstName: '三郎',
            lastNameKana: 'すずき',
            firstNameKana: 'さぶろう',
            grade: 6,
          ),
        ];

        const team = ParsedTeamOrder(
          teamName: '道場選抜',
          members: [
            ParsedTeamMember(position: '先鋒', name: '山田太郎'),
            ParsedTeamMember(position: '中堅', name: '佐藤'),
            ParsedTeamMember(position: '大将', name: '鈴木'),
          ],
        );

        final playerNames3 = TournamentTeamAutoRegisterService.buildPlayerNames(
          team: team,
          matchType: '勝ち抜き戦（3人制）',
          roster: roster,
        );
        expect(playerNames3.length, equals(3));
        expect(playerNames3, equals(['山田 太郎', '佐藤 次郎', '鈴木 三郎']));
      });

      test(
        '2-2. [ルール生成適応] CategoryRuleMatchHelper が新形式を isKachinuki: true として適応すること',
        () {
          // 3人制勝ち抜き戦のルール生成
          final rule3 = CategoryRuleMatchHelper.buildMatchRule(
            category: '小学生の部',
            matchType: '勝ち抜き戦（3人制）',
            matchTime: 3.0,
            isRunningTime: false,
            isIpponShobu: false,
            ipponLimit: 2,
            hansokuLimit: 2,
            hasHantei: false,
            hasExtension: true,
            isEnchoUnlimited: true,
            enchoTime: 3.0,
            enchoCount: 0,
            kachinukiUnlimitedType: '大将対大将',
            hasRepresentativeMatch: false,
            isDaihyoIpponShobu: true,
            winPoint: 0,
            lossPoint: 0,
            drawPoint: 0,
            isRenseikai: false,
            renseikaiType: '一試合制',
            overallTime: 30,
            daihyoMatchTime: 0,
            daihyoHasExtension: true,
            daihyoEnchoTime: 3.0,
            daihyoEnchoCount: -2,
            daihyoHasHantei: false,
          );

          expect(rule3.isKachinuki, isTrue);
          expect(rule3.isEnchoUnlimited, isTrue);
          expect(rule3.kachinukiUnlimitedType, equals('大将対大将'));

          // 5人制勝ち抜き戦のルール生成
          final rule5 = CategoryRuleMatchHelper.buildMatchRule(
            category: '中学生の部',
            matchType: '勝ち抜き戦（5人制）',
            matchTime: 4.0,
            isRunningTime: false,
            isIpponShobu: false,
            ipponLimit: 2,
            hansokuLimit: 2,
            hasHantei: false,
            hasExtension: true,
            isEnchoUnlimited: true,
            enchoTime: 3.0,
            enchoCount: 0,
            kachinukiUnlimitedType: '完全無制限',
            hasRepresentativeMatch: false,
            isDaihyoIpponShobu: true,
            winPoint: 0,
            lossPoint: 0,
            drawPoint: 0,
            isRenseikai: false,
            renseikaiType: '一試合制',
            overallTime: 30,
            daihyoMatchTime: 0,
            daihyoHasExtension: true,
            daihyoEnchoTime: 3.0,
            daihyoEnchoCount: -2,
            daihyoHasHantei: false,
          );

          expect(rule5.isKachinuki, isTrue);
          expect(rule5.kachinukiUnlimitedType, equals('完全無制限'));
        },
      );

      testWidgets(
        '2-3. [フォーム適応] CategoryRuleFormSection で新形式選択時に勝ち抜き戦専用設定が描画されること',
        (tester) async {
          await tester.pumpWidget(
            wrapWithScaffold(
              SingleChildScrollView(
                child: CategoryRuleFormSection(
                  title: '本戦ルール',
                  isNormal: true,
                  themeColors: themeColors,
                  matchType: '勝ち抜き戦（3人制）',
                  isRenseikai: false,
                  categoryKey: 'elem_high',
                  matchTime: 3.0,
                  isRunningTime: false,
                  isIpponShobu: false,
                  ipponLimit: 2,
                  hansokuLimit: 2,
                  hasHantei: false,
                  hasExtension: true,
                  isEnchoUnlimited: true,
                  enchoTime: 3.0,
                  enchoCount: 0,
                  renseikaiType: '一試合制',
                  overallTime: 30,
                  kachinukiUnlimitedType: '大将対大将',
                  hasLeagueDaihyo: false,
                  isDaihyoIpponShobu: true,
                  winPoint: 0.0,
                  lossPoint: 0.0,
                  drawPoint: 0.0,
                  daihyoMatchTime: 0.0,
                  daihyoHasExtension: true,
                  daihyoEnchoTime: 3.0,
                  daihyoEnchoCount: -2,
                  daihyoHasHantei: false,
                  formatMinutes: (m) => '${m.toInt()}分',
                  onMatchTimeChanged: (_) {},
                  onIsRunningTimeChanged: (_) {},
                  onIsIpponShobuChanged: (_) {},
                  onIpponLimitChanged: (_) {},
                  onHansokuLimitChanged: (_) {},
                  onHasHanteiChanged: (_) {},
                  onHasExtensionChanged: (_) {},
                  onIsEnchoUnlimitedChanged: (_) {},
                  onEnchoTimeChanged: (_) {},
                  onEnchoCountChanged: (_) {},
                  onRenseikaiTypeChanged: (_) {},
                  onOverallTimeChanged: (_) {},
                  onKachinukiUnlimitedTypeChanged: (_) {},
                  onHasLeagueDaihyoChanged: (_) {},
                  onIsDaihyoIpponShobuChanged: (_) {},
                  onDaihyoMatchTimeChanged: (_) {},
                  onDaihyoHasExtensionChanged: (_) {},
                  onDaihyoEnchoTimeChanged: (_) {},
                  onDaihyoEnchoCountChanged: (_) {},
                  onDaihyoHasHanteiChanged: (_) {},
                  onWinPointChanged: (_) {},
                  onLossPointChanged: (_) {},
                  onDrawPointChanged: (_) {},
                  onKeywordsChanged: (_) {},
                ),
              ),
            ),
          );

          // 勝ち抜き戦設定カード（大将引き分け設定等）が表示されていること
          expect(find.textContaining('大将'), findsWidgets);
        },
      );

      testWidgets(
        '2-4. [サマリー適応] CategoryRuleSummaryCard に「勝ち抜き戦（3人制）」および「勝ち抜き戦（5人制）」が明記されること',
        (tester) async {
          const rule = MatchRule(
            isKachinuki: true,
            matchTimeMinutes: 3.0,
            kachinukiUnlimitedType: '大将対大将',
          );

          await tester.pumpWidget(
            wrapWithScaffold(
              const CategoryRuleSummaryCard(
                title: '中学生の部',
                matchType: '勝ち抜き戦（3人制）',
                rule: rule,
                accentColor: Colors.indigo,
                isDark: false,
              ),
            ),
          );

          // サマリーカード内に形式名が正確に表示されること
          expect(find.text('勝ち抜き戦（3人制）'), findsOneWidget);
          expect(find.text('勝ち抜き戦設定'), findsOneWidget);
        },
      );
    });

    // =========================================================================
    // 柱3: 【実行保証 (Execution Guarantee)】
    // =========================================================================
    group('第3柱: 試合生成〜勝者残留・敗者交代・決着の実行保証', () {
      final domainService = MatchDomainService();

      test('3-1. 【3人制勝ち抜き戦】初期試合生成から大将戦決着までの完全ライフサイクル実行保証', () {
        const rule = MatchRule(
          isKachinuki: true,
          matchTimeMinutes: 3.0,
          positions: ['先鋒', '中堅', '大将'],
          teamName: '紅組',
          category: '小学生の部',
          kachinukiUnlimitedType: '大将対大将',
        );

        // 1. 初期試合生成
        final initialMatches = OrderSetupMatchGenerator.generateMatches(
          rule: rule,
          opponentTeamInput: '白組',
          selectedPlayers: {0: '紅先鋒', 1: '紅中堅', 2: '紅大将'},
          opponentPlayers: {0: '白先鋒', 1: '白中堅', 2: '白大将'},
          leagueTeamOrders: {},
          leagueParticipants: [],
          tournamentId: 'tour_kachinuki_3',
          isOwnTeamRed: true,
          isStartNow: true,
          positions: ['先鋒', '中堅', '大将'],
          matchType: '勝ち抜き戦（3人制）',
          baseOrder: 1.0,
        );

        expect(initialMatches.length, equals(1));
        final bout1 = initialMatches.first;
        expect(bout1.isKachinuki, isTrue);
        expect(bout1.redName, equals('紅組 : 紅先鋒'));
        expect(bout1.whiteName, equals('白組 : 白先鋒'));
        expect(bout1.redRemaining, equals(['紅組 : 紅中堅', '紅組 : 紅大将']));
        expect(bout1.whiteRemaining, equals(['白組 : 白中堅', '白組 : 白大将']));

        // 2. 第1戦: 紅先鋒 2 - 0 白先鋒（紅先鋒残留、白中堅出場）
        final bout1Finished = bout1.copyWith(redScore: 2, whiteScore: 0);
        final bout2 = domainService.generateNextKachinukiMatch(
          bout1Finished,
          rule,
        );
        expect(bout2, isNotNull);
        expect(bout2!.redName, equals('紅組 : 紅先鋒'));
        expect(bout2.whiteName, equals('白組 : 白中堅'));
        expect(bout2.redRemaining, equals(['紅組 : 紅中堅', '紅組 : 紅大将']));
        expect(bout2.whiteRemaining, equals(['白組 : 白大将']));

        // 3. 第2戦: 紅先鋒 0 - 0 白中堅（引き分け ➔ 両者退場）
        final bout2Finished = bout2.copyWith(redScore: 0, whiteScore: 0);
        final bout3 = domainService.generateNextKachinukiMatch(
          bout2Finished,
          rule,
        );
        expect(bout3, isNotNull);
        expect(bout3!.redName, equals('紅組 : 紅中堅'));
        expect(bout3.whiteName, equals('白組 : 白大将'));
        expect(bout3.redRemaining, equals(['紅組 : 紅大将']));
        expect(bout3.whiteRemaining, isEmpty); // 白は控えゼロ（大将）

        // 4. 第3戦: 紅中堅 0 - 1 白大将（白大将勝利 ➔ 白大将残留、紅大将出場）
        final bout3Finished = bout3.copyWith(redScore: 0, whiteScore: 1);
        final bout4 = domainService.generateNextKachinukiMatch(
          bout3Finished,
          rule,
        );
        expect(bout4, isNotNull);
        expect(bout4!.redName, equals('紅組 : 紅大将'));
        expect(bout4.whiteName, equals('白組 : 白大将'));
        expect(bout4.redRemaining, isEmpty);
        expect(bout4.whiteRemaining, isEmpty);

        // 5. 第4戦（大将同士）: 紅大将 1 - 0 白大将（紅組勝利 ➔ 大会決着）
        final bout4Finished = bout4.copyWith(redScore: 1, whiteScore: 0);
        final bout5 = domainService.generateNextKachinukiMatch(
          bout4Finished,
          rule,
        );
        // 白組全滅のため null が返却され試合終了となる
        expect(bout5, isNull);
      });

      test('3-2. 【5人制勝ち抜き戦】5人抜き完全勝利シナリオの実行保証', () {
        const rule = MatchRule(
          isKachinuki: true,
          matchTimeMinutes: 3.0,
          positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
          teamName: '東軍',
          category: '一般の部',
          kachinukiUnlimitedType: '大将対大将',
        );

        // 1. 初期試合生成（5名 vs 5名）
        final initialMatches = OrderSetupMatchGenerator.generateMatches(
          rule: rule,
          opponentTeamInput: '西軍',
          selectedPlayers: {0: '東先鋒', 1: '東次鋒', 2: '東中堅', 3: '東副将', 4: '東大将'},
          opponentPlayers: {0: '西先鋒', 1: '西次鋒', 2: '西中堅', 3: '西副将', 4: '西大将'},
          leagueTeamOrders: {},
          leagueParticipants: [],
          tournamentId: 'tour_kachinuki_5',
          isOwnTeamRed: true,
          isStartNow: true,
          positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
          matchType: '勝ち抜き戦（5人制）',
          baseOrder: 1.0,
        );

        expect(initialMatches.length, equals(1));
        var currentBout = initialMatches.first;
        expect(currentBout.redRemaining.length, equals(4)); // 次鋒・中堅・副将・大将
        expect(currentBout.whiteRemaining.length, equals(4));

        final expectedOpponents = [
          '西軍 : 西次鋒',
          '西軍 : 西中堅',
          '西軍 : 西副将',
          '西軍 : 西大将',
        ];

        // 東先鋒が西軍の残り4人を次々と撃破（5人抜き達成）
        for (int i = 0; i < 4; i++) {
          final finished = currentBout.copyWith(redScore: 2, whiteScore: 0);
          final nextBout = domainService.generateNextKachinukiMatch(
            finished,
            rule,
          );
          expect(nextBout, isNotNull, reason: '第${i + 2}戦が生成されること');
          expect(nextBout!.redName, equals('東軍 : 東先鋒'), reason: '東先鋒が残留すること');
          expect(
            nextBout.whiteName,
            equals(expectedOpponents[i]),
            reason: '次の西軍選手が出場すること',
          );
          expect(
            nextBout.redRemaining.length,
            equals(4),
            reason: '東軍の控えは減らないこと',
          );
          expect(
            nextBout.whiteRemaining.length,
            equals(3 - i),
            reason: '西軍の控えが1人ずつ減ること',
          );
          currentBout = nextBout;
        }

        // 最後の西大将を撃破
        final finalFinished = currentBout.copyWith(redScore: 1, whiteScore: 0);
        final afterFinal = domainService.generateNextKachinukiMatch(
          finalFinished,
          rule,
        );
        expect(afterFinal, isNull, reason: '西軍5名全員敗退のため試合終了（null）となること');
      });
    });
  });
}
