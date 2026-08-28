import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_team_header_row.dart';

void main() {
  group('MatchTeamHeaderRow Tests', () {
    testWidgets('④ Highlights red team when isRedOwn is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchTeamHeaderRow(
              redTeam: '誠道館',
              whiteTeam: 'ライバル道場',
              textColor: Color(0xFF000000),
              isRedOwn: true,
              isWhiteOwn: false,
            ),
          ),
        ),
      );

      final redText = tester.widget<Text>(find.text('誠道館'));
      expect(redText.style?.color, const Color(0xFFD97706));
      expect(redText.style?.fontWeight, FontWeight.bold);

      final whiteText = tester.widget<Text>(find.text('ライバル道場'));
      expect(whiteText.style?.color, const Color(0xFF000000));
    });

    testWidgets('④ Highlights white team when isWhiteOwn is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchTeamHeaderRow(
              redTeam: '相手チーム',
              whiteTeam: '自チーム道場',
              textColor: Color(0xFF000000),
              isRedOwn: false,
              isWhiteOwn: true,
            ),
          ),
        ),
      );

      final whiteText = tester.widget<Text>(find.text('自チーム道場'));
      expect(whiteText.style?.color, const Color(0xFFD97706));
      expect(whiteText.style?.fontWeight, FontWeight.bold);

      final redText = tester.widget<Text>(find.text('相手チーム'));
      expect(redText.style?.color, const Color(0xFF000000));
    });
  });
}
