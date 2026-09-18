import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_share_data.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/edit_parsed_member_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/tournament_share_import_cards.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_import_teams_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/registered_team_card.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  final List<PlayerModel> sampleRoster = [
    PlayerModel(
      id: 'p_01',
      organizationId: 'org_01',
      lastName: '皿田',
      firstName: '脩人',
      lastNameKana: 'さらだ',
      firstNameKana: 'しゅうと',
      grade: 3,
    ),
    PlayerModel(
      id: 'p_02',
      organizationId: 'org_01',
      lastName: '塚本',
      firstName: '大道',
      lastNameKana: 'つかもと',
      firstNameKana: 'ひろみち',
      grade: 4,
    ),
    PlayerModel(
      id: 'p_03',
      organizationId: 'org_01',
      lastName: '久安',
      firstName: '智也',
      lastNameKana: 'ひさやす',
      firstNameKana: 'ともや',
      grade: 4,
    ),
    PlayerModel(
      id: 'p_04',
      organizationId: 'org_01',
      lastName: '恵木',
      firstName: '春陽',
      lastNameKana: 'えぎ',
      firstNameKana: 'はるひ',
      grade: 8,
    ),
    PlayerModel(
      id: 'p_05',
      organizationId: 'org_01',
      lastName: '平山',
      firstName: '空',
      lastNameKana: 'ひらやま',
      firstNameKana: 'そら',
      grade: 9,
    ),
  ];

  final sampleTeamOrder = ParsedTeamOrder(
    teamName: '低学年A',
    category: '小学生低学年の部',
    members: [
      const ParsedTeamMember(position: '先鋒', name: '皿田 脩人'),
      const ParsedTeamMember(position: '中堅', name: '塚本 大道'),
      const ParsedTeamMember(position: '大将', name: '久安 智也'),
    ],
  );

  final sampleTeamOrder2 = ParsedTeamOrder(
    teamName: '中学生男子',
    category: '中学生の部',
    members: [
      const ParsedTeamMember(position: '先鋒', name: '恵木 春陽'),
      const ParsedTeamMember(position: '大将', name: '平山 空'),
    ],
  );

  Widget buildTestHost({required Widget child}) {
    return ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  void setupDisplaySize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('🥋 大会情報・オーダー取り込み機能 総合テスト', () {
    testWidgets(
      '1. ShareImportTeamSection: チーム名・カテゴリ・オーダー選手が名簿情報と合致して描画されること',
      (tester) async {
        setupDisplaySize(tester);

        await tester.pumpWidget(
          buildTestHost(
            child: ShareImportTeamSection(
              team: sampleTeamOrder,
              accentColor: AppKendoColors.indigo,
              textColor: AppKendoColors.black,
              subTextColor: AppKendoColors.grey,
              roster: sampleRoster,
            ),
          ),
        );

        // チーム名とカテゴリ
        expect(find.text('低学年A'), findsOneWidget);
        expect(find.text('小学生低学年の部'), findsOneWidget);

        // 各ポジション名と選手名
        expect(find.text('先鋒'), findsOneWidget);
        expect(find.text('皿田 脩人'), findsOneWidget);
        expect(find.text('中堅'), findsOneWidget);
        expect(find.text('塚本 大道'), findsOneWidget);
        expect(find.text('大将'), findsOneWidget);
        expect(find.text('久安 智也'), findsOneWidget);

        // 名簿マッチングで取得された学年情報（小学3年、小学4年）
        expect(find.text('(小学3年)'), findsOneWidget);
        expect(find.text('(小学4年)'), findsNWidgets(2));
      },
    );

    testWidgets(
      '2. ShareImportTeamSection: チーム名およびカテゴリのタップで編集ボトムシートが起動し更新されること',
      (tester) async {
        setupDisplaySize(tester);

        String? updatedTeamName;
        String? updatedCategory;

        await tester.pumpWidget(
          buildTestHost(
            child: ShareImportTeamSection(
              team: sampleTeamOrder,
              accentColor: AppKendoColors.indigo,
              textColor: AppKendoColors.black,
              subTextColor: AppKendoColors.grey,
              roster: sampleRoster,
              onTeamNameUpdated: (val) => updatedTeamName = val,
              onCategoryUpdated: (val) => updatedCategory = val,
            ),
          ),
        );

        // チーム名タップ
        await tester.tap(find.text('低学年A'));
        await tester.pumpAndSettle();

        expect(find.text('チーム名の変更'), findsOneWidget);
        final field = find.widgetWithText(TextField, '低学年A');
        await tester.enterText(field, '低学年選抜');
        final saveBtn = find.text('変更を保存');
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        expect(updatedTeamName, equals('低学年選抜'));

        // カテゴリタップ
        await tester.tap(find.text('小学生低学年の部'));
        await tester.pumpAndSettle();

        expect(find.text('「低学年A」のカテゴリ（部門）'), findsOneWidget);
        // 「小学生高学年の部」を選択
        await tester.tap(find.text('小学生高学年の部'));
        await tester.pumpAndSettle();

        expect(updatedCategory, equals('小学生高学年の部'));
      },
    );

    testWidgets(
      '3. EditParsedMemberDialog: 選手編集ボトムシートでポジション変更・名簿選択・登録済みマークが表示されること',
      (tester) async {
        setupDisplaySize(tester);

        ParsedTeamMember? resultMember;

        await tester.pumpWidget(
          buildTestHost(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultMember = await EditParsedMemberDialog.show(
                    context,
                    member: const ParsedTeamMember(
                      position: '先鋒',
                      name: '謎の選手',
                    ),
                    roster: sampleRoster,
                    allTeams: [sampleTeamOrder, sampleTeamOrder2],
                    currentTeamName: '低学年A',
                    category: '小学生低学年の部',
                    useRootNavigator: false,
                  );
                },
                child: const Text('選手編集を開く'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('選手編集を開く'));
        await tester.pumpAndSettle();

        // ボトムシートが開く
        expect(find.text('選手の編集'), findsOneWidget);

        // ポジションチップの切り替え（「次鋒」へ）
        final positionChip = find.text('次鋒');
        expect(positionChip, findsOneWidget);
        await tester.tap(positionChip);
        await tester.pumpAndSettle();

        // 名簿サジェストリスト（EditParsedMemberRosterList）が存在すること
        expect(find.text('道場名簿から選択'), findsOneWidget);

        // 登録済みマーク「他枠に登録済」が表示されていること
        expect(find.text('他枠に登録済'), findsOneWidget);

        // 「皿田 脩人」を選択
        final playerTile = find.text('皿田 脩人').first;
        await tester.tap(playerTile);
        await tester.pumpAndSettle();

        // 外側のListViewをスクロールして保存ボタンを表示・タップ
        await tester.drag(find.text('役職・ポジション'), const Offset(0, -500));
        await tester.pumpAndSettle();

        final applyBtn = find.text('変更を適用');
        expect(applyBtn, findsOneWidget);
        await tester.tap(applyBtn);
        await tester.pumpAndSettle();

        expect(resultMember, isNotNull);
        expect(resultMember!.position, equals('次鋒'));
        expect(resultMember!.name, equals('皿田 脩人'));
      },
    );

    testWidgets(
      '4. CreateTournamentImportTeamsCard: 自動登録トグルとチームオーダー一覧の連携動作テスト',
      (tester) async {
        setupDisplaySize(tester);

        bool isAutoRegister = true;

        await tester.pumpWidget(
          buildTestHost(
            child: CreateTournamentImportTeamsCard(
              teams: [sampleTeamOrder, sampleTeamOrder2],
              isEnabled: isAutoRegister,
              onToggle: (val) => isAutoRegister = val,
              roster: sampleRoster,
              onTeamsUpdated: (_) {},
            ),
          ),
        );

        // カードのタイトル
        expect(find.text('オーダー自動一括登録 (2チーム)'), findsOneWidget);

        // 各チームが表示されていること
        expect(find.text('低学年A'), findsOneWidget);
        expect(find.text('中学生男子'), findsOneWidget);

        // スイッチをタップして切り替え
        final switchFinder = find.byType(Switch);
        expect(switchFinder, findsOneWidget);
        await tester.tap(switchFinder);
        await tester.pump();

        expect(isAutoRegister, isFalse);
      },
    );

    testWidgets('5. RegisteredTeamCard: 登録済みチームカードのオーダー描画と編集アクション発火テスト', (
      tester,
    ) async {
      setupDisplaySize(tester);

      final team = TeamModel(
        id: 'team_001',
        tournamentId: 't_001',
        teamName: '道上剣道A',
        category: '小学生高学年の部',
        matchType: '3人制（先鋒・中堅・大将）',
        playerNames: ['選手A', '選手B', '選手C'],
      );

      TeamModel? editedTeam;
      String? deletedId;

      await tester.pumpWidget(
        buildTestHost(
          child: RegisteredTeamCard(
            team: team,
            themeColors: AppThemeColors.ofMode(isDark: false, mode: 'normal'),
            onEditTeam: (t) => editedTeam = t,
            onDeleteTeam: (id) => deletedId = id,
            onChangeCategory: (_) {},
          ),
        ),
      );

      // チーム名・部門・試合形式
      expect(find.text('道上剣道A'), findsOneWidget);
      expect(find.text('小学生高学年の部'), findsOneWidget);
      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('選手A'), findsOneWidget);
      expect(find.text('中堅'), findsOneWidget);
      expect(find.text('選手B'), findsOneWidget);
      expect(find.text('大将'), findsOneWidget);
      expect(find.text('選手C'), findsOneWidget);

      // 編集ボタンタップ
      final editBtn = find.text('編集');
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pump();

      expect(editedTeam, equals(team));

      // 削除ボタンタップ
      final deleteBtn = find.byIcon(Icons.delete_outline);
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pump();

      expect(deletedId, equals('team_001'));
    });
  });
}
