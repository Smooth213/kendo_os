import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_team_detail_dialog.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  const dummyThemeColors = AppThemeColors(
    primaryAccent: Colors.indigo,
    softAccent: Colors.indigoAccent,
    cardBackground: Colors.white,
    scaffoldBackground: Colors.white,
    textColor: Colors.black,
    subTextColor: Colors.grey,
    separatorColor: Colors.grey,
    inputBackground: Colors.white,
    hintColor: Colors.grey,
    rosePink: Colors.pink,
    successColor: Colors.green,
    warningColor: Colors.orange,
    errorColor: Colors.red,
    infoColor: Colors.blue,
  );

  testWidgets('MatchFormatTeamDetailDialog renders correctly', (tester) async {
    const mockTeam = TeamModel(
      id: 'team1',
      tournamentId: 'tourney1',
      category: '小学生の部',
      teamName: '東京A',
      playerNames: ['選手1'],
    );

    final mockPlayers = [
      PlayerModel(
        id: 'p1',
        lastName: '山田',
        firstName: '太郎',
        lastNameKana: 'ヤマダ',
        firstNameKana: 'タロウ',
        grade: 5,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => MatchFormatTeamDetailDialog(
                      team: mockTeam,
                      posNames: const ['先鋒', '次鋒', '中堅', '副将', '大将'],
                      themeColors: dummyThemeColors,
                      players: mockPlayers,
                      onTeamUpdated: (updated) {},
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('東京A'), findsOneWidget);
    expect(find.text('オーダー（タップして入れ替え）'), findsOneWidget);
  });
}
