import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/new_match/new_match_mode_input_section.dart';

void main() {
  group('🛡️ NewMatchModeInputSection Widget Tests', () {
    testWidgets('Renders single match inputs when creationMode is 単発試合', (
      tester,
    ) async {
      final redController = TextEditingController();
      final whiteController = TextEditingController();
      final leagueController = TextEditingController();
      final redFocus = FocusNode();
      final whiteFocus = FocusNode();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NewMatchModeInputSection(
                creationMode: '単発試合',
                redNameController: redController,
                redFocusNode: redFocus,
                whiteNameController: whiteController,
                whiteFocusNode: whiteFocus,
                leagueParticipantsController: leagueController,
                suggestions: const ['選手A', '選手B'],
                redOrg: null,
                redTeam: null,
                whiteOrg: null,
                whiteTeam: null,
                onRedOrgChanged: (_) {},
                onRedTeamChanged: (_) {},
                onWhiteOrgChanged: (_) {},
                onWhiteTeamChanged: (_) {},
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('赤の選手名（またはチーム名）'), findsOneWidget);
      expect(find.text('白の選手名（またはチーム名）'), findsOneWidget);
    });

    testWidgets('Renders league match textarea when creationMode is リーグ戦自動生成', (
      tester,
    ) async {
      final redController = TextEditingController();
      final whiteController = TextEditingController();
      final leagueController = TextEditingController();
      final redFocus = FocusNode();
      final whiteFocus = FocusNode();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NewMatchModeInputSection(
                creationMode: 'リーグ戦自動生成',
                redNameController: redController,
                redFocusNode: redFocus,
                whiteNameController: whiteController,
                whiteFocusNode: whiteFocus,
                leagueParticipantsController: leagueController,
                suggestions: const [],
                redOrg: null,
                redTeam: null,
                whiteOrg: null,
                whiteTeam: null,
                onRedOrgChanged: (_) {},
                onRedTeamChanged: (_) {},
                onWhiteOrgChanged: (_) {},
                onWhiteTeamChanged: (_) {},
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('参加者リスト'), findsOneWidget);
      expect(
        find.text('参加チーム（選手）をカンマ( , )区切りで入力してください\n例: Aチーム, Bチーム, C道場, D剣友会'),
        findsOneWidget,
      );
    });
  });
}
