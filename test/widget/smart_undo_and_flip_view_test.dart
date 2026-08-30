import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_score_action_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/smart_undo_floating_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_ui_assist_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/widgets/action_buttons.dart';
import '../helpers/test_app.dart';

class FakeSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() {
    return SettingsModel(showConfirmDialog: false);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testOverrides = [
    settingsProvider.overrideWith(() => FakeSettingsNotifier()),
  ];

  group('スマートUndo & 視点反転 Widget Tests', () {
    testWidgets('SmartUndoFloatingBar がイベント登録時に表示され、手動クリアで非表示になること', (
      tester,
    ) async {
      const matchId = 'widget_test_match_1';

      await tester.pumpWidget(
        createTestApp(
          Scaffold(body: SmartUndoFloatingBar(matchId: matchId, isDark: false)),
          overrides: testOverrides,
        ),
      );

      // 初期状態では非表示
      expect(find.textContaining('記録:'), findsNothing);

      // イベントを登録
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SmartUndoFloatingBar)),
      );
      container
          .read(pendingSmartUndoProvider(matchId).notifier)
          .registerEvent(
            ScoreEvent(
              id: 'ev_men',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: DateTime.now(),
            ),
          );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // フローティングバーが表示される
      expect(find.textContaining('【赤・面】'), findsOneWidget);
      expect(find.text('今のを取消'), findsOneWidget);

      // ✕ ボタンで閉じる
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('【赤・面】'), findsNothing);
    });

    testWidgets('MatchScoreActionSection で視点反転ボタンをタップすると左右のパネルがスワップすること', (
      tester,
    ) async {
      const matchId = 'widget_test_match_2';

      await tester.pumpWidget(
        createTestApp(
          Scaffold(
            body: SizedBox(
              height: 400,
              child: MatchScoreActionSection(
                matchId: matchId,
                isInputLocked: false,
                isDark: false,
              ),
            ),
          ),
          overrides: testOverrides,
        ),
      );

      await tester.pumpAndSettle();

      // 初期状態: 正面視点
      expect(find.text('正面視点'), findsOneWidget);

      final initialPanels = tester
          .widgetList<ScoreActionPanel>(find.byType(ScoreActionPanel))
          .toList();
      expect(initialPanels.length, 2);
      expect(initialPanels[0].side, Side.red); // 左が赤
      expect(initialPanels[1].side, Side.white); // 右が白

      // 視点反転ボタンをタップ
      await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 反転後: 逆サイド視点
      expect(find.text('逆サイド視点'), findsOneWidget);

      final flippedPanels = tester
          .widgetList<ScoreActionPanel>(find.byType(ScoreActionPanel))
          .toList();
      expect(flippedPanels.length, 2);
      expect(flippedPanels[0].side, Side.white); // 左が白
      expect(flippedPanels[1].side, Side.red); // 右が赤
    });
  });
}
