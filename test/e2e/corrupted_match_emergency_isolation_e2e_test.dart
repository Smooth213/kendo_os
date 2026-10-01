import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/match_corrupted_state.dart';
import 'package:kendo_os/shared/widgets/corrupted_match_banner.dart';

void main() {
  group('[E2E] 試合データ破損緊急隔離およびフェイルセーフ二次破壊阻止テスト', () {
    testWidgets('試合ステータスが破損状態の際に赤色警告バナーが表示され編集が隔離遮断され救済エクスポートが許可されること', (
      WidgetTester tester,
    ) async {
      final corruptedMatch = MatchModel(
        id: 'corrupted-match-e2e',
        tournamentId: 't-e2e',
        matchType: '個人戦',
        redName: '選手赤',
        whiteName: '選手白',
        status: 'corrupted',
      );

      final state = MatchCorruptedState(corruptedMatch);

      // 1. ドメインレベルでの防衛プロパティ検証
      expect(state.isCorrupted, isTrue);
      expect(state.allowEdit, isFalse);
      expect(state.allowViewer, isTrue);
      expect(state.allowExport, isTrue);

      // 2. UIレベルでの赤色警告バナー表示検証
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  if (state.isCorrupted)
                    CorruptedMatchBanner(matchId: corruptedMatch.id),
                  Expanded(
                    child: Center(
                      child: ElevatedButton(
                        onPressed: state.allowEdit ? () {} : null,
                        child: const Text('スコア打突入力'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 赤色警告バナーの文言が表示されていること
      expect(find.text('データに問題が発生しました'), findsOneWidget);
      expect(find.byType(CorruptedMatchBanner), findsOneWidget);

      // 編集ボタンが非活性（無効化）されていること
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.enabled, isFalse);
    });
  });
}
