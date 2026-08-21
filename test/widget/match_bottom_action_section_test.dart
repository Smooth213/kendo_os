import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_bottom_action_section.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

void main() {
  group('MatchBottomActionSection Tests', () {
    testWidgets('shows approved text when isApproved is true', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        redName: 'A',
        whiteName: 'B',
        matchType: '団体戦',
        status: 'approved',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Scaffold(
              body: MatchBottomActionSection(
                match: match,
                rule: MatchRule(),
                isApproved: true,
                isViewOnly: false,
                isTie: false,
                isAllDone: true,
                isDark: false,
                myUserId: 'u1',
                teamMatches: [match],
                onAddRenseikaiNext: () {},
                onShowConfirmDialog: (title, content) async => true,
                onShowMatchFinishedDialog: (ctx, m, next) {},
                onShowHanteiDialog: (m) async => null,
              ),
            ),
          ),
        ),
      );

      expect(find.text('公式記録確定済み'), findsOneWidget);
    });
  });
}
