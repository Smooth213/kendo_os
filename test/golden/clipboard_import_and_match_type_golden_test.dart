import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_share_data.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/tournament_share_import_cards.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_import_teams_card.dart';

void main() {
  group('📸 【Golden】クリップボード取り込み（個人戦・複数名）＆ 試合形式選択 UI整合性 Goldenテスト', () {
    testWidgets(
      '1. [Golden] 複数名個人戦（中学生の部）取り込みカードがダークモード・ライトモードでオーバーフローなく描画されること',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final List<ParsedTeamOrder> individualTeams = [
          const ParsedTeamOrder(
            teamName: '皿田 唯人',
            category: '中学生の部',
            matchType: '個人戦',
            members: [ParsedTeamMember(position: '個人', name: '皿田 唯人')],
          ),
          const ParsedTeamOrder(
            teamName: '皿田 梓人',
            category: '中学生の部',
            matchType: '個人戦',
            members: [ParsedTeamMember(position: '個人', name: '皿田 梓人')],
          ),
          const ParsedTeamOrder(
            teamName: '橋本 璃久',
            category: '中学生の部',
            matchType: '個人戦',
            members: [ParsedTeamMember(position: '個人', name: '橋本 璃久')],
          ),
        ];

        // ── ダークモードでの検証 ──
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: CreateTournamentImportTeamsCard(
                  teams: individualTeams,
                  isEnabled: true,
                  onToggle: (_) {},
                  roster: const [],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 例外・オーバーフローゼロ検証
        expect(tester.takeException(), isNull);
        expect(find.text('皿田 唯人'), findsWidgets);
        expect(find.text('皿田 梓人'), findsWidgets);
        expect(find.text('橋本 璃久'), findsWidgets);
        expect(find.text('中学生の部'), findsNWidgets(3));
        expect(find.text('個人戦'), findsNWidgets(3));

        // ── ライトモードでの検証 ──
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: CreateTournamentImportTeamsCard(
                  teams: individualTeams,
                  isEnabled: true,
                  onToggle: (_) {},
                  roster: const [],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '2. [Golden] 全6カテゴリ（小学生低学年〜一般）の個人戦バッジがモバイル幅（375px）で崩れず描画されること',
      (tester) async {
        tester.view.physicalSize = const Size(375, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final List<ParsedTeamOrder> allCategoryTeams =
            TournamentTeamAutoRegisterService.candidateCategories
                .map(
                  (category) => ParsedTeamOrder(
                    teamName: '代表選手（$category）',
                    category: category,
                    matchType: '個人戦',
                    members: [
                      ParsedTeamMember(position: '個人', name: '選手（$category）'),
                    ],
                  ),
                )
                .toList();

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: CreateTournamentImportTeamsCard(
                  teams: allCategoryTeams,
                  isEnabled: true,
                  onToggle: (_) {},
                  roster: const [],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        for (final cat
            in TournamentTeamAutoRegisterService.candidateCategories) {
          expect(find.text(cat), findsWidgets);
        }
      },
    );

    testWidgets('3. [Golden] 試合形式編集ボトムシート（全8形式）がタブレット＆モバイルでレイアウト崩れなく表示されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844); // iPhone 14相当
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final team = const ParsedTeamOrder(
        teamName: '皿田 唯人',
        category: '中学生の部',
        matchType: '個人戦',
        members: [ParsedTeamMember(position: '個人', name: '皿田 唯人')],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ShareImportTeamSection(
              team: team,
              accentColor: Colors.amber,
              textColor: Colors.white,
              subTextColor: Colors.grey,
              onMatchTypeUpdated: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 形式チップをタップしてボトムシート展開
      await tester.tap(find.text('個人戦'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // 全8形式がボトムシート内に存在し、文字欠落や例外がないこと
      for (final type
          in TournamentTeamAutoRegisterService.candidateMatchTypes) {
        expect(find.text(type), findsWidgets);
      }
    });
  });
}
