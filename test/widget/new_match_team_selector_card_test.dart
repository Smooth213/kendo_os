import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/new_match/new_match_team_selector_card.dart';
import 'package:kendo_os/shared/domain/entities/organization.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ NewMatchTeamSelectorCard Widget Tests', () {
    testWidgets('Renders organization dropdown and triggers selection', (
      WidgetTester tester,
    ) async {
      Organization? selectedOrg;
      TeamTemplate? selectedTeam;

      final org1 = Organization(id: 'org1', name: '東京剣道クラブ');
      final org2 = Organization(id: 'org2', name: '大阪剣友会');
      final team1 = TeamTemplate(
        id: 'team1',
        name: 'Aチーム',
        orderedMemberNames: ['選手1', '選手2'],
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return NewMatchTeamSelectorCard(
                  colorLabel: '赤',
                  orgs: [org1, org2],
                  isRed: true,
                  selectedOrg: selectedOrg,
                  selectedTeam: selectedTeam,
                  teamTemplates: [team1],
                  onOrgChanged: (val) {
                    setState(() {
                      selectedOrg = val;
                    });
                  },
                  onTeamChanged: (val) {
                    setState(() {
                      selectedTeam = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('赤チーム選択'), findsOneWidget);
      expect(find.text('組織（道場・学校）を選択'), findsOneWidget);
      expect(find.text('チームテンプレを選択'), findsNothing);

      // 組織ドロップダウンを開く
      await tester.tap(find.text('組織（道場・学校）を選択'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('東京剣道クラブ'), findsOneWidget);
      expect(find.text('大阪剣友会'), findsOneWidget);

      // 「東京剣道クラブ」を選択
      await tester.tap(find.text('東京剣道クラブ').last);
      await tester.pumpAndSettle();

      expect(selectedOrg, org1);
      expect(find.text('チームテンプレを選択'), findsOneWidget);
    });
  });
}
