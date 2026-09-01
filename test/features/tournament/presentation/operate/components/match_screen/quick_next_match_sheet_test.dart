import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/quick_next_match_sheet.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

void main() {
  group('QuickNextMatchSheet Tests', () {
    testWidgets(
      'Displays team name, position count, and empty memo with placeholder',
      (tester) async {
        final currentMatch = MatchModel(
          id: 'match-1',
          redName: '誠道館 : 山田',
          whiteName: 'ライバル道場 : 田中',
          matchType: '先鋒',
          order: 0,
          matchTimeMinutes: 3,
          rule: MatchRule(matchTimeMinutes: 3),
        );

        final teamMatches = [
          currentMatch,
          MatchModel(
            id: 'match-2',
            redName: '誠道館 : 佐藤',
            whiteName: 'ライバル道場 : 鈴木',
            matchType: '次鋒',
            order: 1,
            matchTimeMinutes: 3,
          ),
          MatchModel(
            id: 'match-3',
            redName: '誠道館 : 高橋',
            whiteName: 'ライバル道場 : 渡辺',
            matchType: '中堅',
            order: 2,
            matchTimeMinutes: 3,
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: QuickNextMatchSheet(
                  currentMatch: currentMatch,
                  teamMatches: teamMatches,
                ),
              ),
            ),
          ),
        );

        // タイトル
        expect(find.text('次の対戦へ連戦開始 (クイック対戦)'), findsOneWidget);
        expect(find.textContaining('誠道館'), findsWidgets);
        expect(find.textContaining('3名'), findsWidgets);

        // ③ メモ入力欄が空欄で、プレースホルダーが表示されること
        final textFields = tester
            .widgetList<AppTextField>(find.byType(AppTextField))
            .toList();
        expect(textFields.length, 2);

        // 相手チーム入力欄
        expect(textFields[0].controller?.text, '');
        expect(textFields[0].hintText, '例: ○○道場、△△中学校');

        // メモ入力欄
        expect(textFields[1].controller?.text, '');
        expect(textFields[1].hintText, '例: 申合せ 第2試合 (空欄可)');

        // 開始ボタン
        expect(find.text('このオーダーで第1試合を開始'), findsOneWidget);
      },
    );

    testWidgets('Correctly resolves own team when white side is own team', (
      tester,
    ) async {
      final currentMatch = MatchModel(
        id: 'match-1',
        redName: '相手チーム : 田中',
        whiteName: '自チーム (誠道館) : 山田',
        matchType: '先鋒',
        order: 0,
        matchTimeMinutes: 3,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickNextMatchSheet(
                currentMatch: currentMatch,
                teamMatches: [currentMatch],
              ),
            ),
          ),
        ),
      );

      // ④ 白側が自チームの場合でも自チーム名が正しく抽出・ハイライトされること
      expect(find.textContaining('自チーム (誠道館)'), findsWidgets);
    });
  });
}
