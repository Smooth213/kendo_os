import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/quick_roster_swap_dialog.dart';

void main() {
  testWidgets(
    'QuickRosterSwapDialog renders reorderable player list with drag handles',
    (tester) async {
      final teamMatches = [
        const MatchModel(
          id: 'match-1',
          redName: '誠道館 : 山田',
          whiteName: 'ライバル : 田中',
          matchType: '先鋒',
          order: 0,
        ),
        const MatchModel(
          id: 'match-2',
          redName: '誠道館 : 佐藤',
          whiteName: 'ライバル : 鈴木',
          matchType: '次鋒',
          order: 1,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickRosterSwapDialog(
                currentMatch: teamMatches.first,
                teamMatches: teamMatches,
                isRedSide: true,
              ),
            ),
          ),
        ),
      );

      // タイトルと各要素の確認
      expect(find.textContaining('オーダー並び替え'), findsOneWidget);
      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('次鋒'), findsOneWidget);
      expect(find.text('山田'), findsOneWidget);
      expect(find.text('佐藤'), findsOneWidget);

      // ドラッグハンドル「＝」アイコンが2つ表示されていること
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));

      // 保存ボタンが表示されていること
      final buttonFinder = find.widgetWithText(ElevatedButton, 'このオーダーで一括保存');
      expect(buttonFinder, findsOneWidget);
    },
  );
}
