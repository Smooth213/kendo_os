import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_team_header_row.dart';

void main() {
  group('[Widget] MatchTeamHeaderRow テスト', () {
    testWidgets('自チームが赤の場合に赤チームがハイライト表示されること', (tester) async {
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

    testWidgets('自チームが白の場合に白チームがハイライト表示されること', (tester) async {
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

    testWidgets('チーム名が正しく描画されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchTeamHeaderRow(
              redTeam: '道上剣友会',
              whiteTeam: '相手道場',
              textColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('道上剣友会'), findsOneWidget);
      expect(find.text('相手道場'), findsOneWidget);
    });

    testWidgets('チーム名が空の場合にフォールバック「（個人エントリー）」が描画されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchTeamHeaderRow(
              redTeam: '',
              whiteTeam: '',
              textColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('（個人エントリー）'), findsNWidgets(2));
    });
  });
}
