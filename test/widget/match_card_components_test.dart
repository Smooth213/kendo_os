import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_card_action_buttons.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_card_header_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_card_note_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_point_badge.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] 試合カード各種UIコンポーネント 総合テスト', () {
    // 1. MatchCardActionButtons
    testWidgets('MatchCardActionButtonsにおいて 全ボタン表示とタップイベントが正常連動すること', (
      WidgetTester tester,
    ) async {
      bool summaryPressed = false;
      bool infoPressed = false;
      bool scorePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCardActionButtons(
              showSummaryButton: true,
              showInfoButton: true,
              showScoreButton: true,
              textColor: Colors.white,
              subTextColor: Colors.grey,
              onSummaryPressed: () => summaryPressed = true,
              onInfoPressed: () => infoPressed = true,
              onScorePressed: () => scorePressed = true,
            ),
          ),
        ),
      );

      expect(find.text('簡易'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('スコア'), findsOneWidget);

      await tester.tap(find.text('簡易'));
      expect(summaryPressed, isTrue);

      await tester.tap(find.byIcon(Icons.info_outline));
      expect(infoPressed, isTrue);

      await tester.tap(find.text('スコア'));
      expect(scorePressed, isTrue);
    });

    testWidgets('MatchCardActionButtonsにおいて 非表示フラグ指定時にボタンが非表示となること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchCardActionButtons(
              showSummaryButton: false,
              showInfoButton: false,
              showScoreButton: false,
              textColor: Colors.white,
              subTextColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('簡易'), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);
      expect(find.text('スコア'), findsNothing);
    });

    // 2. MatchCardHeaderRow
    testWidgets('MatchCardHeaderRowにおいて ヘッダー要素およびleading要素が正しく描画されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchCardHeaderRow(
              leading: Text('MATCH_NUM'),
              actionButtons: Text('ACTIONS'),
              statusBadge: Text('STATUS'),
            ),
          ),
        ),
      );

      expect(find.text('MATCH_NUM'), findsOneWidget);
      expect(find.text('ACTIONS'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
    });

    // 3. MatchCardNoteRow
    testWidgets('MatchCardNoteRowにおいて 備考および試合区分が正しく描画されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchCardNoteRow(
              displayNote: '第1試合',
              matchType: '先鋒',
              noteColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.textContaining('第1試合'), findsOneWidget);
      expect(find.textContaining('【先鋒】'), findsOneWidget);
    });

    // 4. MatchStatusBadge
    testWidgets('MatchStatusBadgeにおいて 進行状態に応じたバッジと文言が正しく描画されること', (
      WidgetTester tester,
    ) async {
      Widget buildBadge({
        required bool isPlaying,
        required bool isFinished,
        required bool isDark,
        String? customFinishedText,
      }) {
        return MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: isDark, mode: 'normal')],
          ),
          home: Scaffold(
            body: Center(
              child: MatchStatusBadge(
                isPlaying: isPlaying,
                isFinished: isFinished,
                isDark: isDark,
                customFinishedText: customFinishedText,
              ),
            ),
          ),
        );
      }

      // 試合中 (LIVE)
      await tester.pumpWidget(
        buildBadge(isPlaying: true, isFinished: false, isDark: false),
      );
      expect(find.text('試合中 (LIVE)'), findsOneWidget);
      expect(find.byIcon(Icons.fiber_manual_record), findsOneWidget);

      // 待機中
      await tester.pumpWidget(
        buildBadge(isPlaying: false, isFinished: false, isDark: false),
      );
      expect(find.text('⏳ 待機中'), findsOneWidget);

      // 終了
      await tester.pumpWidget(
        buildBadge(isPlaying: false, isFinished: true, isDark: false),
      );
      expect(find.text('終了'), findsOneWidget);

      // カスタム終了テキスト
      await tester.pumpWidget(
        buildBadge(
          isPlaying: false,
          isFinished: true,
          isDark: false,
          customFinishedText: '🏁 全試合終了',
        ),
      );
      expect(find.text('🏁 全試合終了'), findsOneWidget);

      // ダークモード環境
      await tester.pumpWidget(
        buildBadge(isPlaying: true, isFinished: false, isDark: true),
      );
      expect(find.text('試合中 (LIVE)'), findsOneWidget);
    });

    // 5. MatchPointBadge
    testWidgets('MatchPointBadgeにおいて 打突マークと先取丸枠線および記号正規化が正常動作すること', (
      WidgetTester tester,
    ) async {
      // 通常マーク（先取なし）
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchPointBadge(mark: 'メ', isFirst: false, color: Colors.red),
          ),
        ),
      );
      expect(find.text('メ'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('メ'));
      expect(textWidget.style?.color, equals(Colors.red));

      // 先取マーク（丸枠線あり）
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchPointBadge(
              mark: 'コ',
              isFirst: true,
              color: Colors.white,
            ),
          ),
        ),
      );
      expect(find.text('コ'), findsOneWidget);
      final circleDecorations = tester
          .widgetList<Container>(find.byType(Container))
          .where((container) {
            final decoration = container.decoration;
            return decoration is BoxDecoration &&
                decoration.shape == BoxShape.circle;
          });
      expect(circleDecorations.isNotEmpty, isTrue);

      // 全角バツ記号の正規化
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchPointBadge(
              mark: '✕',
              isFirst: false,
              color: Colors.grey,
            ),
          ),
        ),
      );
      expect(find.text('×'), findsOneWidget);
    });
  });
}
