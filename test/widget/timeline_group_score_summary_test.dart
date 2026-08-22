import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_group_score_summary.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ TimelineGroupScoreSummary Widget Tests', () {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

    testWidgets(
      '1. TimelineGroupScoreSummary calculates wins and renders teams',
      (WidgetTester tester) async {
        final matches = [
          MatchModel(
            id: 'm1',
            matchType: '団体戦',
            redName: '青龍館: 山田',
            whiteName: '白虎館: 佐藤',
            redScore: 2,
            whiteScore: 0,
            status: 'finished',
          ),
          MatchModel(
            id: 'm2',
            matchType: '団体戦',
            redName: '青龍館: 鈴木',
            whiteName: '白虎館: 田中',
            redScore: 1,
            whiteScore: 1,
            status: 'finished',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: TimelineGroupScoreSummary(
                groupList: matches,
                rTeam: '青龍館',
                wTeam: '白虎館',
                ownTeams: const ['青龍館'],
                titleColor: AppKendoColors.pureBlack,
                isDark: false,
              ),
            ),
          ),
        );

        final redText = tester.widget<Text>(find.text('青龍館'));
        expect(redText.style?.color, equals(const Color(0xFFD97706)));
        expect(redText.style?.fontWeight, equals(AppFontWeight.black));

        final whiteText = tester.widget<Text>(find.text('白虎館'));
        expect(whiteText.style?.color, equals(AppKendoColors.pureBlack));

        expect(find.text('自道場'), findsNothing);
        expect(find.text('1'), findsOneWidget); // red wins: 1
        expect(find.text('(3)'), findsOneWidget); // red points: 3
        expect(find.text('0'), findsOneWidget); // white wins: 0
        expect(find.text('(1)'), findsOneWidget); // white points: 1
      },
    );
  });
}
