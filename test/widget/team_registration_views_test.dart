import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_page_two_view.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_page_three_view.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_providers.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] TeamRegistrationPageTwoView & PageThreeView 表示統合テスト', () {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

    testWidgets('TeamRegistrationPageTwoView が適切にオーダーフォームをレンダリングすること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = TextEditingController(text: '赤心館');
      final focusNode = FocusNode();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customTeamNamesProvider.overrideWith(
              (ref) => Stream.value(['赤心館', '白龍館']),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: TeamRegistrationPageTwoView(
                playerCount: 5,
                posNames: const ['先鋒', '次鋒', '中堅', '副将', '大将'],
                players: [
                  PlayerModel(
                    id: 'p1',
                    lastName: '山田',
                    firstName: '太郎',
                    lastNameKana: 'ヤマダ',
                    firstNameKana: 'タロウ',
                    grade: 1,
                    organization: '赤心館',
                  ),
                ],
                teamNameController: controller,
                teamNameFocusNode: focusNode,
                tempSelectedPlayers: const {0: '山田 太郎'},
                substituteCount: 0,
                matchType: '団体戦（5人制）',
                themeColors: themeColors,
                onSelectPlayer: (_) async {},
                onAddSubstitute: () {},
                onAddPlayerSlot: () {},
                onRemoveSubstitute: (_) {},
                onRemovePlayerSlot: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('チーム名とオーダーを\n入力してください'), findsOneWidget);
      expect(find.text('山田 太郎'), findsOneWidget);
      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('補欠を追加 (0/4)'), findsOneWidget);
    });

    testWidgets('TeamRegistrationPageThreeView が登録確認カードと登録済みチームをレンダリングすること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeFirestore = FakeFirebaseFirestore();
      final repo = TeamRepository(
        dojoId: 'test_dojo',
        firestore: fakeFirestore,
      );

      const sampleTeams = <TeamModel>[
        TeamModel(
          id: 't1',
          tournamentId: 'tour_1',
          teamName: '赤心館A',
          category: '一般の部',
          playerNames: ['山田', '佐藤', '田中', '鈴木', '高橋'],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [teamRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: TeamRegistrationPageThreeView(
                registeredTeamsAsync: const AsyncValue.data(sampleTeams),
                playerCount: 5,
                selectedCategory: '一般の部',
                teamName: '赤心館B',
                matchType: '団体戦（5人制）',
                tempSelectedPlayers: const {
                  0: '選手1',
                  1: '選手2',
                  2: '選手3',
                  3: '選手4',
                  4: '選手5',
                },
                themeColors: themeColors,
                onAddNewTeam: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('赤心館B'), findsWidgets);
      expect(find.textContaining('登録済みチーム'), findsOneWidget);
      expect(find.text('赤心館A'), findsOneWidget);
      expect(find.text('新規追加'), findsOneWidget);
    });
  });
}
