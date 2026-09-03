import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_team_member_list.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('BunaiksenTeamMemberList Widget Tests', () {
    testWidgets(
      'renders positions and members correctly and triggers clear on tap',
      (tester) async {
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );
        int? clearedIndex;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: BunaiksenTeamMemberList(
                teamSize: 3,
                teamMembers: const ['先鋒選手', null, '大将選手'],
                positions: const ['先鋒', '中堅', '大将'],
                teamColor: AppKendoColors.hansokuRed,
                isDark: false,
                onMemberAssigned: (index, name) {},
                onMemberCleared: (index) => clearedIndex = index,
              ),
            ),
          ),
        );

        expect(find.text('先鋒選手'), findsOneWidget);
        expect(find.text('未定'), findsOneWidget);
        expect(find.text('大将選手'), findsOneWidget);

        await tester.tap(find.text('先鋒選手'));
        await tester.pump();
        expect(clearedIndex, 0);
      },
    );
  });
}
