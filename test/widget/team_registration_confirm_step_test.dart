import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_confirm_step.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  testWidgets('TeamRegistrationConfirmStep renders properly with empty list', (
    tester,
  ) async {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [themeColors]),
        home: Scaffold(
          body: TeamRegistrationConfirmStep(
            registeredTeamsAsync: const AsyncValue.data([]),
            playerCount: 5,
            selectedCategory: '小学生高学年の部',
            teamName: '赤心館A',
            matchType: '団体戦（5人制）',
            tempSelectedPlayers: const {0: '選手1', 1: '選手2'},
            themeColors: themeColors,
            onEditTeam: (_) {},
            onDeleteTeam: (_) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('登録内容の確認と\n登録済みの一覧です'), findsOneWidget);
    expect(find.text('小学生高学年の部 : 赤心館A'), findsOneWidget);
    expect(find.text('まだ登録されたチームはありません'), findsOneWidget);
  });

  testWidgets('TeamRegistrationConfirmStep renders properly with teams', (
    tester,
  ) async {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

    final teams = [
      TeamModel(
        id: 't1',
        tournamentId: 'tourney_1',
        category: '小学生高学年の部',
        teamName: '白龍会A',
        matchType: '団体戦（5人制）',
        playerNames: ['白1', '白2', '白3', '白4', '白5'],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [themeColors]),
        home: Scaffold(
          body: TeamRegistrationConfirmStep(
            registeredTeamsAsync: AsyncValue.data(teams),
            playerCount: 5,
            selectedCategory: '小学生高学年の部',
            teamName: '赤心館A',
            matchType: '団体戦（5人制）',
            tempSelectedPlayers: const {},
            themeColors: themeColors,
            onEditTeam: (_) {},
            onDeleteTeam: (_) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('小学生高学年の部 : 白龍会A'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });
}
