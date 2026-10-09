import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_share_data.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_text_parser.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/tournament_share_import_cards.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_import_teams_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_edit_basic_fields.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
  const allCandidateTypes =
      TournamentTeamAutoRegisterService.candidateMatchTypes;

  group('[Governance] 第1条 ガバナンス監査 ⑤において 全試合形式（勝ち抜き戦・リーグ戦含む）編集選択＆完全整合性保証規約', () {
    // =========================================================================
    // [静的スキャン] 不完全な matchType ハードコードの禁止
    // =========================================================================
    test('静的スキャンに関して、 チーム編集・取り込み関連クラスで不完全な試合形式リストがハードコードされていないこと', () {
      final targetFiles = [
        'lib/features/tournament/presentation/operate/components/team_registration/team_edit_bottom_sheet.dart',
        'lib/features/tournament/presentation/components/share_import/share_import_edit_sheets.dart',
        'lib/features/tournament/presentation/operate/components/create_tournament/create_tournament_import_teams_card.dart',
      ];

      for (final path in targetFiles) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path が存在すること');

        final content = file.readAsStringSync();
        // 以前の4形式限定のハードコードリストが残っていないこと
        expect(
          content.contains("['団体戦（3人制）', '団体戦（5人制）', '団体戦（7人制）', '個人戦']"),
          isFalse,
          reason:
              '$path に4形式限定の旧ハードコードリストが残っています。candidateMatchTypes を参照してください。',
        );
        // candidateMatchTypes を使用していること
        expect(
          content.contains('candidateMatchTypes'),
          isTrue,
          reason:
              '$path は TournamentTeamAutoRegisterService.candidateMatchTypes を参照する必要があります。',
        );
      }

      // candidateMatchTypes から旧「勝ち抜き戦」単体が除去され全11形式であること
      expect(
        allCandidateTypes.contains('勝ち抜き戦'),
        isFalse,
        reason: 'candidateMatchTypes から単独の「勝ち抜き戦」が除去されていること',
      );
      expect(allCandidateTypes.length, equals(11));
      expect(
        TeamRegistrationCategoryStep.extraMatchTypes.contains('勝ち抜き戦'),
        isFalse,
      );
    });

    // =========================================================================
    // [UI監査] 共有インポートシート (ShareImportTeamSection) の試合形式編集検証
    // =========================================================================
    testWidgets(
      'UI監査に関して、 ShareImportTeamSection で全9形式がボトムシートに表示され、タップで選択更新されること',
      (tester) async {
        final team = const ParsedTeamOrder(
          teamName: '道上剣友会',
          category: '小学生の部',
          members: [
            ParsedTeamMember(position: '先鋒', name: '選手A'),
            ParsedTeamMember(position: '中堅', name: '選手B'),
            ParsedTeamMember(position: '大将', name: '選手C'),
          ],
        );

        String? updatedMatchType;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ShareImportTeamSection(
                team: team,
                accentColor: Colors.blue,
                textColor: Colors.black,
                subTextColor: Colors.grey,
                onMatchTypeUpdated: (type) => updatedMatchType = type,
              ),
            ),
          ),
        );

        // 初期自動判定形式「団体戦（3人制）」が表示されていること
        expect(find.text('団体戦（3人制）'), findsOneWidget);

        // 試合形式チップをタップしてボトムシートを開く
        await tester.tap(find.text('団体戦（3人制）'));
        await tester.pumpAndSettle();

        // ボトムシートに全候補形式が表示されていることを検証（元のチップとシート内の両方に存在し得るため 1つ以上）
        for (final type in allCandidateTypes) {
          expect(
            find.text(type),
            findsAtLeastNWidgets(1),
            reason: '選択肢に $type が存在すること',
          );
        }

        // 「勝ち抜き戦（5人制）」をタップして選択
        await tester.tap(find.text('勝ち抜き戦（5人制）').last);
        await tester.pumpAndSettle();

        // コールバック経由で形式が更新されたこと
        expect(updatedMatchType, equals('勝ち抜き戦（5人制）'));
      },
    );

    // =========================================================================
    // [UI監査] 大会作成プレビュー (CreateTournamentImportTeamsCard) の試合形式編集検証
    // =========================================================================
    testWidgets(
      'UI監査に関して、 CreateTournamentImportTeamsCard で全9形式が表示され、タップで更新されること',
      (tester) async {
        final teams = [
          const ParsedTeamOrder(
            teamName: '道上剣友会A',
            category: '中学生の部',
            members: [
              ParsedTeamMember(position: '先鋒', name: '選手1'),
              ParsedTeamMember(position: '次鋒', name: '選手2'),
              ParsedTeamMember(position: '中堅', name: '選手3'),
              ParsedTeamMember(position: '副将', name: '選手4'),
              ParsedTeamMember(position: '大将', name: '選手5'),
            ],
          ),
        ];

        List<ParsedTeamOrder>? resultTeams;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CreateTournamentImportTeamsCard(
                  teams: teams,
                  isEnabled: true,
                  onToggle: (_) {},
                  roster: const [],
                  onTeamsUpdated: (updated) => resultTeams = updated,
                ),
              ),
            ),
          ),
        );

        // 初期形式「団体戦（5人制）」のチップが表示されていること
        expect(find.text('団体戦（5人制）'), findsOneWidget);

        // チップをタップして編集ボトムシートを開く
        await tester.tap(find.text('団体戦（5人制）'));
        await tester.pumpAndSettle();

        // ボトムシートに全候補形式が表示されていることを検証（元のチップとシート内の両方に存在し得るため 1つ以上）
        for (final type in allCandidateTypes) {
          expect(
            find.text(type),
            findsAtLeastNWidgets(1),
            reason: '選択肢に $type が存在すること',
          );
        }

        // 「リーグ団体戦」を選択
        await tester.tap(find.text('リーグ団体戦').last);
        await tester.pumpAndSettle();

        // 更新されたチームの matchType が「リーグ団体戦」になっていること
        expect(resultTeams, isNotNull);
        expect(resultTeams!.first.matchType, equals('リーグ団体戦'));
      },
    );

    // =========================================================================
    // [UI監査] チーム編集基本フィールド (TeamEditBasicFields) の全形式表示と切り替え
    // =========================================================================
    testWidgets('UI監査に関して、 TeamEditBasicFields において全9形式が描画され、タップ切り替えが動作すること', (
      tester,
    ) async {
      final controller = TextEditingController(text: '道上剣友会B');
      String selectedType = '個人戦';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamEditBasicFields(
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
        ),
      );

      // 全9形式が描画されていること
      for (final type in allCandidateTypes) {
        expect(find.text(type), findsOneWidget, reason: 'フィールドに $type が存在すること');
      }

      // 「勝ち抜き戦（5人制）」をタップ
      await tester.tap(find.text('勝ち抜き戦（5人制）'));
      await tester.pump();
      expect(selectedType, equals('勝ち抜き戦（5人制）'));

      // 「リーグ個人戦」をタップ
      await tester.tap(find.text('リーグ個人戦'));
      await tester.pump();
      expect(selectedType, equals('リーグ個人戦'));
    });

    // =========================================================================
    // [UI監査] チーム新規登録ウィザード (TeamRegistrationCategoryStep) の全形式網羅検証
    // =========================================================================
    test(
      'UI監査に関して、 TeamRegistrationCategoryStep の main + extra で全11形式が完全に網羅されていること',
      () {
        final combined = [
          ...TeamRegistrationCategoryStep.mainMatchTypes,
          ...TeamRegistrationCategoryStep.extraMatchTypes,
        ];

        for (final type in allCandidateTypes) {
          expect(
            combined.contains(type),
            isTrue,
            reason: 'TeamRegistrationCategoryStep に $type が含まれていること',
          );
        }
      },
    );

    // =========================================================================
    // [ドメイン整合性監査] 全形式に対するスロット数と自動判定の整合性検証
    // =========================================================================
    test('ドメイン整合性に関して、 全11形式それぞれに対して基準スロットおよび自動判定が決定論的に動作すること', () {
      // 0. 旧形式の正規化検証
      expect(
        TournamentTeamAutoRegisterService.normalizeMatchType('勝ち抜き戦'),
        equals('勝ち抜き戦（5人制）'),
      );
      expect(
        TournamentTeamAutoRegisterService.normalizeMatchType('勝ち抜き戦（3人制）'),
        equals('勝ち抜き戦（3人制）'),
      );
      expect(
        TournamentTeamAutoRegisterService.normalizeMatchType('勝ち抜き戦（7人制）'),
        equals('勝ち抜き戦（7人制）'),
      );
      expect(
        TournamentTeamAutoRegisterService.normalizeMatchType('勝ち抜き戦（それ以上）'),
        equals('勝ち抜き戦（それ以上）'),
      );
      // 1. 各試合形式の基準スロット定義の検証
      expect(TournamentTeamAutoRegisterService.getBaseSlots('個人戦'), ['選手']);
      expect(TournamentTeamAutoRegisterService.getBaseSlots('リーグ個人戦'), ['選手']);
      expect(TournamentTeamAutoRegisterService.getBaseSlots('団体戦（3人制）'), [
        '先鋒',
        '中堅',
        '大将',
      ]);
      expect(TournamentTeamAutoRegisterService.getBaseSlots('団体戦（5人制）'), [
        '先鋒',
        '次鋒',
        '中堅',
        '副将',
        '大将',
      ]);
      expect(TournamentTeamAutoRegisterService.getBaseSlots('勝ち抜き戦（5人制）'), [
        '先鋒',
        '次鋒',
        '中堅',
        '副将',
        '大将',
      ]);
      expect(TournamentTeamAutoRegisterService.getBaseSlots('勝ち抜き戦（3人制）'), [
        '先鋒',
        '中堅',
        '大将',
      ]);
      expect(TournamentTeamAutoRegisterService.getBaseSlots('勝ち抜き戦（7人制）'), [
        '先鋒',
        '次鋒',
        '五将',
        '中堅',
        '三将',
        '副将',
        '大将',
      ]);
      expect(TournamentTeamAutoRegisterService.getBaseSlots('勝ち抜き戦（それ以上）', 8), [
        '先鋒',
        '次鋒',
        '六将',
        '五将',
        '四将',
        '三将',
        '副将',
        '大将',
      ]);
      expect(TournamentTeamAutoRegisterService.getBaseSlots('勝ち抜き戦'), [
        '先鋒',
        '次鋒',
        '中堅',
        '副将',
        '大将',
      ]);
      expect(TournamentTeamAutoRegisterService.getBaseSlots('リーグ団体戦'), [
        '先鋒',
        '次鋒',
        '中堅',
        '副将',
        '大将',
      ]);
      expect(TournamentTeamAutoRegisterService.getBaseSlots('団体戦（7人制）'), [
        '先鋒',
        '次鋒',
        '五将',
        '中堅',
        '三将',
        '副将',
        '大将',
      ]);
      expect(TournamentTeamAutoRegisterService.getBaseSlots('団体戦（それ以上）', 8), [
        '先鋒',
        '次鋒',
        '六将',
        '五将',
        '四将',
        '三将',
        '副将',
        '大将',
      ]);
      expect(TournamentTeamAutoRegisterService.getBaseSlots('団体戦（それ以上）', 9), [
        '先鋒',
        '次鋒',
        '七将',
        '六将',
        '中堅',
        '四将',
        '三将',
        '副将',
        '大将',
      ]);

      // 8人以上のメンバー構成時に「団体戦（それ以上）」が自動判定されること
      final eightMemberTeam = ParsedTeamOrder(
        teamName: '多人数テストチーム',
        members: List.generate(
          8,
          (i) => ParsedTeamMember(position: '', name: '選手$i'),
        ),
      );
      expect(
        TournamentTeamAutoRegisterService.determineMatchType(eightMemberTeam),
        equals('団体戦（それ以上）'),
      );

      // 勝ち抜き戦の多人数（7人制・それ以上）の自動判定
      final kachinukiSevenTeam = ParsedTeamOrder(
        teamName: '勝ち抜き7人制チーム',
        members: List.generate(
          7,
          (i) => ParsedTeamMember(position: '', name: '選手$i'),
        ),
      );
      expect(
        TournamentTeamAutoRegisterService.determineMatchType(
          kachinukiSevenTeam,
        ),
        equals('勝ち抜き戦（7人制）'),
      );

      final kachinukiMoreTeam = ParsedTeamOrder(
        teamName: '勝ち抜き多人数チーム',
        members: List.generate(
          8,
          (i) => ParsedTeamMember(position: '', name: '選手$i'),
        ),
      );
      expect(
        TournamentTeamAutoRegisterService.determineMatchType(kachinukiMoreTeam),
        equals('勝ち抜き戦（それ以上）'),
      );

      // 2. matchType が明示指定されたチームはそのまま最優先されること
      for (final type in allCandidateTypes) {
        final team = ParsedTeamOrder(
          teamName: 'テストチーム',
          matchType: type,
          members: const [ParsedTeamMember(position: '先鋒', name: '選手')],
        );
        expect(
          TournamentTeamAutoRegisterService.determineMatchType(team),
          equals(type),
          reason: '指定された $type がそのまま反映されること',
        );
      }
    });

    // =========================================================================
    // [個人戦永続保証] クリップボードインポートおよび自動登録プレビューで個人戦が確実に認識・展開されること
    // =========================================================================
    testWidgets('個人戦永続保証に関して、 個人戦テキストのインポートおよび自動登録プレビューで個人戦が確実に適応されること', (
      tester,
    ) async {
      const sample = '''
第1回 少年剣道個人選手権大会
日時: 2026年10月10日
場所: 武道館
【小学生低学年個人戦】
選手: 皿田 脩人
選手: 塚本 大道
''';

      // 1. テキスト解析が個人戦として各選手を抽出すること
      final parsed = TournamentTextParser.parse(sample);
      expect(parsed.teams.length, equals(2));
      for (final t in parsed.teams) {
        expect(t.matchType, equals('個人戦'));
        expect(
          TournamentTeamAutoRegisterService.determineMatchType(t),
          equals('個人戦'),
        );
      }

      // 2. 自動登録プレビューカードで全個人戦選手が「個人戦」バッジ付きで正しく描画されること
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreateTournamentImportTeamsCard(
              teams: parsed.teams,
              isEnabled: true,
              roster: const [],
              onToggle: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 「個人戦」バッジが画面上に2つ存在すること
      expect(find.text('個人戦'), findsNWidgets(2));
      expect(find.text('皿田 脩人'), findsAtLeastNWidgets(1));
      expect(find.text('塚本 大道'), findsAtLeastNWidgets(1));
    });

    // =========================================================================
    // [全カテゴリ判別保証] 個人戦を含む全カテゴリのインポート・自動判別・プレビュー保証
    // =========================================================================
    testWidgets(
      '全カテゴリ判別保証に関して、 クリップボードインポートおよび自動登録プレビューにおいて全カテゴリが正確に判別され描画されること',
      (tester) async {
        const allCategorySample = '''
第30回 全日本選抜剣道大会
日時: 2026年11月20日
会場: 日本武道館

個人戦
小学生低学年
皿田 脩人

小学生高学年
久安 智也

小学生
佐藤 健

中学生
皿田 唯人
皿田 梓人

高校生
鈴木 一郎

一般
高橋 翔
''';

        // 1. クリップボードインポート解析
        final parsed = TournamentTextParser.parse(allCategorySample);
        // 中学生に2人いるため、計7選手のエントリーとなること
        expect(parsed.teams.length, equals(7));

        for (final t in parsed.teams) {
          expect(t.matchType, equals('個人戦'));
          expect(
            TournamentTeamAutoRegisterService.determineMatchType(t),
            equals('個人戦'),
          );
        }

        // 全カテゴリが抽出されること
        final expectedCategories = [
          '小学生低学年の部',
          '小学生高学年の部',
          '小学生の部',
          '中学生の部',
          '高校生の部',
          '一般の部',
        ];
        final extractedCategories =
            TournamentTeamAutoRegisterService.extractCategories(parsed.teams);
        for (final exp in expectedCategories) {
          expect(
            extractedCategories.contains(exp),
            isTrue,
            reason: '$exp が大会抽出カテゴリに含まれること',
          );
        }

        // 2. 自動登録プレビューカードでの描画検証
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CreateTournamentImportTeamsCard(
                  teams: parsed.teams,
                  isEnabled: true,
                  roster: const [],
                  onToggle: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 全ての部門名バッジが画面上に描画されていること
        for (final catName in expectedCategories) {
          expect(
            find.text(catName),
            findsAtLeastNWidgets(1),
            reason: 'プレビュー上で $catName バッジが正しく描画されていること',
          );
        }

        // 全7名分の「個人戦」バッジが描画されていること
        expect(find.text('個人戦'), findsNWidgets(7));

        // 各選手名が描画されていること
        expect(find.text('皿田 脩人'), findsAtLeastNWidgets(1));
        expect(find.text('久安 智也'), findsAtLeastNWidgets(1));
        expect(find.text('佐藤 健'), findsAtLeastNWidgets(1));
        expect(find.text('皿田 唯人'), findsAtLeastNWidgets(1));
        expect(find.text('皿田 梓人'), findsAtLeastNWidgets(1));
        expect(find.text('鈴木 一郎'), findsAtLeastNWidgets(1));
        expect(find.text('高橋 翔'), findsAtLeastNWidgets(1));
      },
    );
  });
}
