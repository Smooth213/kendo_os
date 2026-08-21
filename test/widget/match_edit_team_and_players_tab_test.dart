import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_data_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_team_and_players_tab.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ MatchEditTeamAndPlayersTab Widget Tests', () {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

    test('1. MatchEditDataHelper extracts names and clean notes correctly', () {
      expect(
        MatchEditDataHelper.extractTeamName('青龍道場: 山田', 'fallback', true),
        '青龍道場',
      );
      expect(MatchEditDataHelper.extractPlayerName('青龍道場: 山田'), '山田');
      expect(MatchEditDataHelper.cleanNoteText('第1コート\n個人戦メモ'), '個人戦メモ');
      expect(MatchEditDataHelper.getPositionLabel(0, 5), '先鋒');
      expect(MatchEditDataHelper.getPositionLabel(4, 5), '大将');
    });

    testWidgets(
      '2. MatchEditTeamAndPlayersTab renders text fields and handles swap',
      (WidgetTester tester) async {
        final redTeamCtrl = TextEditingController(text: '赤チーム');
        final whiteTeamCtrl = TextEditingController(text: '白チーム');
        final redPlayerCtrls = [TextEditingController(text: '赤選手1')];
        final whitePlayerCtrls = [TextEditingController(text: '白選手1')];
        bool swapCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: MatchEditTeamAndPlayersTab(
                isDantai: true,
                redTeamController: redTeamCtrl,
                whiteTeamController: whiteTeamCtrl,
                redPlayerControllers: redPlayerCtrls,
                whitePlayerControllers: whitePlayerCtrls,
                primaryAccent: AppKendoColors.indigo,
                isDark: false,
                textColor: AppKendoColors.pureBlack,
                onSwapTeamsAndPlayers: () {
                  swapCalled = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('🏫 団体戦 対戦チーム'), findsOneWidget);
        expect(find.text('赤チーム'), findsOneWidget);
        expect(find.text('白チーム'), findsOneWidget);
        expect(find.text('赤選手1'), findsOneWidget);
        expect(find.text('白選手1'), findsOneWidget);

        await tester.tap(find.text('チーム丸ごと赤と白を入れ替える ⇄'));
        await tester.pumpAndSettle();

        expect(swapCalled, isTrue);
      },
    );
  });
}
