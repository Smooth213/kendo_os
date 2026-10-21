import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/components/viewer_individual_matches_list_card.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_individual_player_card.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('[Widget] ViewerIndividualCards 統合検証', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('ViewerIndividualMatchesListCardにおいて 選手名とスコアが正しく描画されること', (
      WidgetTester tester,
    ) async {
      final match1 = MatchModel(
        id: 'indiv_1',
        redName: '東軍: 坂本',
        whiteName: '西軍: 岡田',
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
        matchType: 'individual',
        note: '第1試合',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViewerIndividualMatchesListCard(
              groupName: '男子個人の部',
              matches: [match1],
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('【個人戦】 男子個人の部'), findsOneWidget);
      expect(find.text('坂本'), findsOneWidget);
      expect(find.text('岡田'), findsOneWidget);
      expect(find.text('東軍'), findsOneWidget);
      expect(find.text('西軍'), findsOneWidget);
      expect(find.text('第1試合'), findsOneWidget);
    });

    testWidgets('ViewerIndividualPlayerCardにおいて 選手名と試合一覧が正しく描画されること', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final prefs = await SharedPreferences.getInstance();

      final match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: 'individual',
        order: 1,
        redName: '選手A',
        whiteName: '選手B',
        status: 'in_progress',
        note: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: ViewerIndividualPlayerCard(
                playerName: '選手A',
                playerMatches: [match],
                matchLabel: '個人戦',
              ),
            ),
          ),
        ),
      );

      expect(find.text('選'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('選手A'),
        ),
        findsOneWidget,
      );
      expect(find.text('試合中 (LIVE)'), findsOneWidget);
    });
  });
}
