import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_daihyo_overlay.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_hantei_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_infinite_next_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_snapshot_history_dialog.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('[Widget] 試合操作画面 ダイアログ・オーバーレイ統合検証テスト', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('MatchDaihyoOverlayにおいて 代表者設定状態に応じた案内が正しく表示されること', (
      tester,
    ) async {
      Widget buildSubject(MatchModel match) {
        return ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Scaffold(
              body: MatchDaihyoOverlay(match: match, onSelectDaihyo: () {}),
            ),
          ),
        );
      }

      const matchUnset = MatchModel(
        id: 'representative-match',
        matchType: '代表戦',
        redName: '赤チーム : 代表選手',
        whiteName: '白チーム : 代表選手',
        status: 'waiting',
      );

      await tester.pumpWidget(buildSubject(matchUnset));
      expect(find.text('代表戦の選手が未設定です'), findsOneWidget);
      expect(find.text('代表者を選択する'), findsOneWidget);

      const matchSet = MatchModel(
        id: 'representative-match',
        matchType: '代表戦',
        redName: '赤チーム : 山田',
        whiteName: '白チーム : 鈴木',
        status: 'waiting',
      );

      await tester.pumpWidget(buildSubject(matchSet));
      expect(find.text('代表戦の選手が未設定です'), findsNothing);
      expect(find.text('代表者を選択する'), findsNothing);
    });

    testWidgets('MatchHanteiDialogにおいて 判定選択が正しくコールバック実行されること', (tester) async {
      String? selectedResult = 'initial';
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: MatchHanteiDialog(
              redName: 'チームA: 山田',
              whiteName: 'チームB: 佐藤',
              isDark: false,
              onSelected: (result) {
                selectedResult = result;
              },
            ),
          ),
        ),
      );

      expect(find.text('勝敗の判定'), findsOneWidget);
      expect(find.textContaining('同点のため、判定'), findsOneWidget);
      expect(find.textContaining('赤の判定勝ち'), findsOneWidget);
      expect(find.textContaining('白の判定勝ち'), findsOneWidget);
      expect(find.text('引き分け'), findsOneWidget);
      expect(find.text('キャンセル（戻る）'), findsOneWidget);

      await tester.tap(find.textContaining('赤の判定勝ち'));
      await tester.pump();
      expect(selectedResult, 'red');

      await tester.tap(find.textContaining('白の判定勝ち'));
      await tester.pump();
      expect(selectedResult, 'white');

      await tester.tap(find.text('引き分け'));
      await tester.pump();
      expect(selectedResult, 'draw');

      await tester.tap(find.text('キャンセル（戻る）'));
      await tester.pump();
      expect(selectedResult, isNull);
    });

    testWidgets('MatchInfiniteNextDialogにおいて 無限稽古アクションが正常に実行されること', (
      tester,
    ) async {
      bool finishClicked = false;
      bool restClicked = false;
      bool startImmediatelyClicked = false;
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: MatchInfiniteNextDialog(
              redName: '山田',
              whiteName: '佐藤',
              winnerStreak: 3,
              onFinishInfinite: () {
                finishClicked = true;
              },
              onRestAndReturn: () {
                restClicked = true;
              },
              onStartNextMatchImmediately: () {
                startImmediatelyClicked = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('無限稽古: 次の試合'), findsOneWidget);
      expect(find.text('🔥 挑戦者が入りました！'), findsOneWidget);
      expect(find.text('防衛(赤): 山田 (3連勝中)'), findsOneWidget);
      expect(find.text('挑戦(白): 佐藤'), findsOneWidget);

      await tester.tap(find.text('無限稽古を終了'));
      await tester.pump();
      expect(finishClicked, isTrue);

      await tester.tap(find.text('一覧に戻る（休憩）'));
      await tester.pump();
      expect(restClicked, isTrue);

      await tester.tap(find.text('すぐに次の試合を開始'));
      await tester.pump();
      expect(startImmediatelyClicked, isTrue);
    });

    testWidgets('MatchSnapshotHistoryDialogにおいて 履歴表示と巻き戻しが正しく動作すること', (
      tester,
    ) async {
      int? selectedVersion;
      int? selectedIndex;
      final now = DateTime(2026, 8, 15, 14, 30, 0);

      final event1 = ScoreEvent(
        id: 'e1',
        strikeType: StrikeType.men,
        isIppon: true,
        side: Side.red,
        timestamp: now,
      );

      final event2 = ScoreEvent(
        id: 'e2',
        strikeType: StrikeType.kote,
        isIppon: true,
        side: Side.white,
        timestamp: now.add(const Duration(minutes: 1)),
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: MatchSnapshotHistoryDialog(
              validEvents: [event1, event2],
              isDark: false,
              onSelectRewind: (version, index) {
                selectedVersion = version;
                selectedIndex = index;
              },
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('操作履歴と取り消し'), findsOneWidget);
      expect(find.text('赤 メン'), findsOneWidget);
      expect(find.text('白 コテ'), findsOneWidget);
      expect(find.text('1本目まで戻る'), findsOneWidget);
      expect(find.text('2本目まで戻る'), findsOneWidget);

      await tester.tap(find.text('赤 メン'));
      await tester.pump();
      expect(selectedVersion, 1);
      expect(selectedIndex, 0);
    });
  });
}
