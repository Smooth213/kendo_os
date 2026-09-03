import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/court_status/team_status_member_order_row.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';

void main() {
  group('TeamStatusMemberOrderRow Widget Tests', () {
    testWidgets('renders red and white players and teams correctly', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: const Scaffold(
            body: TeamStatusMemberOrderRow(
              redTeam: '東剣友会',
              redPlayer: '山田',
              whiteTeam: '西道場',
              whitePlayer: '鈴木',
              redPoints: [PointMark(mark: 'メ')],
              whitePoints: [PointMark(mark: 'コ')],
              isDraw: false,
              isFinished: true,
              redScore: 1,
              whiteScore: 1,
            ),
          ),
        ),
      );

      expect(find.text('東剣友会'), findsOneWidget);
      expect(find.text('山田'), findsOneWidget);
      expect(find.text('西道場'), findsOneWidget);
      expect(find.text('鈴木'), findsOneWidget);
    });
  });
}
