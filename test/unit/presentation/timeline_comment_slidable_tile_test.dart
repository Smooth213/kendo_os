import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_comment_slidable_tile.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';

void main() {
  group('TimelineCommentSlidableTile テスト', () {
    testWidgets('コメントテキストが正確に描画されること', (tester) async {
      final comment = MatchCommentModel(
        id: 'c_100',
        text: '【重要】コート清掃中',
        lastUpdatedAt: DateTime(2026, 9, 3, 11, 0),
        order: 1.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return TimelineCommentSlidableTile(
                    comment: comment,
                    tournamentId: 'tour_1',
                    isDark: false,
                    ref: ref,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('【重要】コート清掃中'), findsOneWidget);
      expect(find.byIcon(Icons.label_outline), findsOneWidget);
    });

    testWidgets('ダークモード時も正常にクラッシュせず描画されること', (tester) async {
      final comment = MatchCommentModel(
        id: 'c_200',
        text: '【第2試合場】準備中',
        lastUpdatedAt: DateTime(2026, 9, 3, 11, 0),
        order: 2.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return TimelineCommentSlidableTile(
                    comment: comment,
                    tournamentId: 'tour_2',
                    isDark: true,
                    ref: ref,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('【第2試合場】準備中'), findsOneWidget);
    });
  });
}
