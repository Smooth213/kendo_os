import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_players_score_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_team_header_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_list.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_registration_screen.dart'
    show playerListProvider;
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart'
    show registeredTeamsProvider;
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  const tId = 'tourney_test_own_001';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildCardWithProviders({
    required MatchModel match,
    required List<TeamModel> teams,
    required List<PlayerModel> masterPlayers,
  }) {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'operate');

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        permissionProvider.overrideWithValue(
          const AppPermissions(
            role: UserRole.admin,
            isReadOnly: false,
            canManageTournament: true,
            canDeleteData: true,
            canCreateMatch: true,
          ),
        ),
        matchListProvider.overrideWith((ref) => [match]),
        matchListByTournamentProvider(
          tId,
        ).overrideWith((ref) => Stream.value([match])),
        customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
        registeredTeamsProvider(tId).overrideWith((ref) => Stream.value(teams)),
        playerListProvider.overrideWith((ref) => Stream.value(masterPlayers)),
      ],
      child: MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [themeColors]),
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 800,
            child: ListView(children: [MatchListTileCard(initialMatch: match)]),
          ),
        ),
      ),
    );
  }

  group('🥋 MatchListTileCard 自チーム・自選手表示保証テスト（UI描画色検証）', () {
    testWidgets(
      '1. 【合同チーム助っ人 vs 自道場選手】個人戦で他道場助っ人は通常色、自道場正規選手のみ自チーム色(0xFFD97706)となること',
      (WidgetTester tester) async {
        // 合同チーム「連合A」に自道場選手「皿田 脩人」と、手入力の他道場助っ人選手「他道場 助っ人」が所属
        final teams = [
          const TeamModel(
            id: 'team_joint_1',
            tournamentId: tId,
            teamName: '連合A',
            category: '団体戦',
            matchType: '団体戦（5人制）',
            playerNames: ['皿田 脩人', '他道場 助っ人'],
          ),
        ];

        // 道場名簿マスタには「皿田 脩人」のみが正規登録されている
        final masterPlayers = [
          PlayerModel(
            id: 'p1',
            lastName: '皿田',
            firstName: '脩人',
            lastNameKana: 'さらだ',
            firstNameKana: 'しゅうと',
            grade: 5,
          ),
        ];

        // 個人戦で「皿田 脩人」vs「他道場 助っ人」が対戦
        final match = const MatchModel(
          id: 'match_indiv_1',
          tournamentId: tId,
          matchType: '個人戦',
          category: '一般男子',
          redName: '皿田 脩人',
          whiteName: '他道場 助っ人',
          status: 'waiting',
        );

        await tester.pumpWidget(
          buildCardWithProviders(
            match: match,
            teams: teams,
            masterPlayers: masterPlayers,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // 赤選手（皿田 脩人）は自チーム強調色（0xFFD97706）かつ Black ウェイト
        final redPlayerWidget = tester.widget<Text>(
          find.descendant(
            of: find.byType(MatchPlayersScoreRow),
            matching: find.text('皿田 脩人'),
          ),
        );
        expect(redPlayerWidget.style?.color, const Color(0xFFD97706));
        expect(redPlayerWidget.style?.fontWeight, AppFontWeight.black);

        // 白選手（他道場 助っ人）は通常色であり、自チーム色(0xFFD97706)ではないこと！
        final whitePlayerWidget = tester.widget<Text>(
          find.descendant(
            of: find.byType(MatchPlayersScoreRow),
            matching: find.text('他道場 助っ人'),
          ),
        );
        expect(whitePlayerWidget.style?.color, isNot(const Color(0xFFD97706)));
        expect(whitePlayerWidget.style?.fontWeight, AppFontWeight.bold);

        // チーム名表示：赤側は解決された自チーム「連合A」、白側は紐付けされず「（個人エントリー）」
        expect(find.text('連合A'), findsOneWidget);
        expect(find.text('（個人エントリー）'), findsOneWidget);
      },
    );

    testWidgets('2. 【自道場正規選手同士の同門対決】両者とも自チーム色(0xFFD97706)で強調表示されること', (
      WidgetTester tester,
    ) async {
      final teams = [
        const TeamModel(
          id: 'team_dojo_1',
          tournamentId: tId,
          teamName: '小畠剣道教室',
          category: '団体戦',
          matchType: '団体戦（5人制）',
          playerNames: ['皿田 脩人', '久安 智也'],
        ),
      ];

      final masterPlayers = [
        PlayerModel(
          id: 'p1',
          lastName: '皿田',
          firstName: '脩人',
          lastNameKana: 'さらだ',
          firstNameKana: 'しゅうと',
          grade: 5,
        ),
        PlayerModel(
          id: 'p2',
          lastName: '久安',
          firstName: '智也',
          lastNameKana: 'ひさやす',
          firstNameKana: 'ともや',
          grade: 6,
        ),
      ];

      final match = const MatchModel(
        id: 'match_indiv_same_dojo',
        tournamentId: tId,
        matchType: '個人戦',
        category: '一般男子',
        redName: '皿田 脩人',
        whiteName: '久安 智也',
        status: 'waiting',
      );

      await tester.pumpWidget(
        buildCardWithProviders(
          match: match,
          teams: teams,
          masterPlayers: masterPlayers,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      final redText = tester.widget<Text>(
        find.descendant(
          of: find.byType(MatchPlayersScoreRow),
          matching: find.text('皿田 脩人'),
        ),
      );
      final whiteText = tester.widget<Text>(
        find.descendant(
          of: find.byType(MatchPlayersScoreRow),
          matching: find.text('久安 智也'),
        ),
      );

      // 同門対決のため、両者とも自チーム色
      expect(redText.style?.color, const Color(0xFFD97706));
      expect(whiteText.style?.color, const Color(0xFFD97706));
    });

    testWidgets('3. 【他道場選手同士の対戦】どちらも自チーム色(0xFFD97706)にならないこと', (
      WidgetTester tester,
    ) async {
      final teams = [
        const TeamModel(
          id: 'team_dojo_1',
          tournamentId: tId,
          teamName: '自道場',
          category: '団体戦',
          matchType: '団体戦（5人制）',
          playerNames: ['皿田 脩人'],
        ),
      ];

      final masterPlayers = [
        PlayerModel(
          id: 'p1',
          lastName: '皿田',
          firstName: '脩人',
          lastNameKana: 'さらだ',
          firstNameKana: 'しゅうと',
          grade: 5,
        ),
      ];

      final match = const MatchModel(
        id: 'match_indiv_other',
        tournamentId: tId,
        matchType: '個人戦',
        category: '一般男子',
        redName: '鈴木 一郎',
        whiteName: '高橋 健太',
        status: 'waiting',
      );

      await tester.pumpWidget(
        buildCardWithProviders(
          match: match,
          teams: teams,
          masterPlayers: masterPlayers,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      final redText = tester.widget<Text>(
        find.descendant(
          of: find.byType(MatchPlayersScoreRow),
          matching: find.text('鈴木 一郎'),
        ),
      );
      final whiteText = tester.widget<Text>(
        find.descendant(
          of: find.byType(MatchPlayersScoreRow),
          matching: find.text('高橋 健太'),
        ),
      );

      expect(redText.style?.color, isNot(const Color(0xFFD97706)));
      expect(whiteText.style?.color, isNot(const Color(0xFFD97706)));
    });

    testWidgets('4. 【団体戦】自チーム名が自チーム色(0xFFD97706)で強調表示されること', (
      WidgetTester tester,
    ) async {
      final teams = [
        const TeamModel(
          id: 'team_dojo_1',
          tournamentId: tId,
          teamName: '小畠剣道教室',
          category: '団体戦',
          matchType: '団体戦（5人制）',
          playerNames: ['皿田 脩人'],
        ),
      ];

      final masterPlayers = [
        PlayerModel(
          id: 'p1',
          lastName: '皿田',
          firstName: '脩人',
          lastNameKana: 'さらだ',
          firstNameKana: 'しゅうと',
          grade: 5,
        ),
      ];

      final match = const MatchModel(
        id: 'match_team_1',
        tournamentId: tId,
        matchType: '先鋒',
        category: '団体戦',
        redName: '小畠剣道教室',
        whiteName: '相手道場',
        status: 'waiting',
      );

      await tester.pumpWidget(
        buildCardWithProviders(
          match: match,
          teams: teams,
          masterPlayers: masterPlayers,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // 赤チーム（小畠剣道教室）は自チーム色
      final redTeamWidget = tester.widget<Text>(
        find.descendant(
          of: find.byType(MatchTeamHeaderRow),
          matching: find.text('小畠剣道教室'),
        ),
      );
      expect(redTeamWidget.style?.color, const Color(0xFFD97706));
      expect(redTeamWidget.style?.fontWeight, AppFontWeight.bold);

      // 白チーム（相手道場）は通常色
      final whiteTeamWidget = tester.widget<Text>(
        find.descendant(
          of: find.byType(MatchTeamHeaderRow),
          matching: find.text('相手道場'),
        ),
      );
      expect(whiteTeamWidget.style?.color, isNot(const Color(0xFFD97706)));
      expect(whiteTeamWidget.style?.fontWeight, AppFontWeight.medium);
    });

    testWidgets('5. 【個人戦登録選手】大会設定で個人戦として自チーム登録された選手が自チーム色となること', (
      WidgetTester tester,
    ) async {
      final teams = [
        const TeamModel(
          id: 'team_indiv_1',
          tournamentId: tId,
          teamName: '個人戦',
          category: '個人戦',
          matchType: '個人戦',
          playerNames: ['個人エントリー選手'],
        ),
      ];

      final match = const MatchModel(
        id: 'match_indiv_entry',
        tournamentId: tId,
        matchType: '個人戦',
        category: '一般男子',
        redName: '個人エントリー選手',
        whiteName: '相手選手',
        status: 'waiting',
      );

      await tester.pumpWidget(
        buildCardWithProviders(
          match: match,
          teams: teams,
          masterPlayers: const [],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      final redText = tester.widget<Text>(
        find.descendant(
          of: find.byType(MatchPlayersScoreRow),
          matching: find.text('個人エントリー選手'),
        ),
      );
      final whiteText = tester.widget<Text>(
        find.descendant(
          of: find.byType(MatchPlayersScoreRow),
          matching: find.text('相手選手'),
        ),
      );

      expect(redText.style?.color, const Color(0xFFD97706));
      expect(whiteText.style?.color, isNot(const Color(0xFFD97706)));
    });
  });
}
