import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_team_header_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_content_layout_builder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_daihyo_overlay.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_header_widgets.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_view_only_notice_banner.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('[Widget] MatchScreenSubComponentsAndHeaders 統合テスト', () {
    testWidgets('MatchHeaderTitleにおいて 試合形式および選手名が正しく描画されること', (tester) async {
      final match = MatchModel(
        id: 'm1',
        matchOrder: 1,
        redName: '佐藤',
        whiteName: '鈴木',
        redScore: 1,
        whiteScore: 0,
        status: 'in_progress',
        matchType: '個人戦',
        category: '一般の部',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MatchHeaderTitle(match: match)),
        ),
      );

      expect(find.text('一般の部 - 個人戦'), findsOneWidget);
      expect(find.text('佐藤 vs 鈴木'), findsOneWidget);
    });

    testWidgets('縦画面レイアウトが正しく描画されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchContentLayoutBuilder(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 800),
              isDark: false,
              corruptedBanner: const Text('CORRUPTED'),
              viewOnlyBanner: const Text('VIEW_ONLY'),
              timerPart: const Text('TIMER'),
              groupButtonPart: const Text('GROUP_BUTTONS'),
              scoreboardPart: const Text('SCOREBOARD'),
              actionPanelPart: const Text('ACTION_PANEL'),
              undoArea: const Text('UNDO_AREA'),
              bottomButtonPart: const Text('BOTTOM_BUTTONS'),
            ),
          ),
        ),
      );

      expect(find.text('TIMER'), findsOneWidget);
      expect(find.text('GROUP_BUTTONS'), findsOneWidget);
      expect(find.text('SCOREBOARD'), findsOneWidget);
      expect(find.text('ACTION_PANEL'), findsOneWidget);
    });

    testWidgets('MatchViewOnlyNoticeBannerにおいて 警告バナーおよび切替ボタンが描画されること', (
      tester,
    ) async {
      bool claimed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchViewOnlyNoticeBanner(
              isSomeoneElseOperating: true,
              isApproved: false,
              isReadOnly: false,
              onClaimScorer: () {
                claimed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('他の記録員が入力中です'), findsOneWidget);
      expect(find.text('自分に切り替える'), findsOneWidget);

      await tester.tap(find.text('自分に切り替える'));
      expect(claimed, isTrue);
    });

    testWidgets('MatchDaihyoOverlayにおいて ボタンが描画されコールバックが呼び出されること', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      bool selected = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: MatchDaihyoOverlay(
                  match: const MatchModel(
                    id: 'representative-match',
                    matchType: '代表戦',
                    redName: '赤チーム : 代表選手',
                    whiteName: '白チーム : 代表選手',
                    status: 'waiting',
                  ),
                  onSelectDaihyo: () {
                    selected = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('代表戦の選手が未設定です'), findsOneWidget);
      expect(find.text('代表者を選択する'), findsOneWidget);

      await tester.tap(find.text('代表者を選択する'));
      expect(selected, isTrue);
    });

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
