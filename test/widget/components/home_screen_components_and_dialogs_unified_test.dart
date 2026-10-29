import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/home_screen_call_banner.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/home_screen_qr_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/home_screen_setup_checklist_card.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] ホーム画面 各種カード・バナー・ダイアログ統合検証テスト', () {
    testWidgets('HomeScreenQrDialogにおいて 観戦リンクと共有ボタンが表示され閉じる操作が正常に動作すること', (
      WidgetTester tester,
    ) async {
      bool isClosed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: HomeScreenQrDialog(
              shareUrl: 'https://kendo-os-beta.web.app/viewer-home/test_tour_1',
              onClose: () {
                isClosed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('大会観戦リンク'), findsOneWidget);
      expect(find.textContaining('離れた場所にいる保護者や仲間も'), findsOneWidget);
      expect(find.text('LINEやSNSでURLを送る'), findsOneWidget);
      expect(find.text('閉じる'), findsOneWidget);

      await tester.tap(find.text('閉じる'));
      await tester.pump();
      expect(isClosed, isTrue);
    });

    testWidgets('HomeScreenSetupChecklistCardにおいて 準備ステップと完了率が正しく描画されること', (
      WidgetTester tester,
    ) async {
      final sampleTournament = TournamentModel(
        id: 'tour_1',
        name: '第50回剣道大会',
        date: DateTime(2026, 8, 15),
        venue: '武道館',
        organizationId: 'org_1',
        categoryRules: const {'団体戦': CategoryRuleSet()},
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: HomeScreenSetupChecklistCard(
              tournament: sampleTournament,
              teams: const ['チームA'],
              themeColors: themeColors,
              isDark: false,
              enableLiquidGlass: false,
              tournamentId: 'tour_1',
            ),
          ),
        ),
      );

      expect(find.text('大会準備ステップ'), findsOneWidget);
      expect(find.text('75% 完了'), findsOneWidget);
      expect(find.text('大会基本情報の登録'), findsOneWidget);
      expect(find.text('出場チーム・選手の登録'), findsOneWidget);
      expect(find.text('部門別ルールの設定'), findsOneWidget);
      expect(find.text('最初の試合枠の作成'), findsOneWidget);
    });

    testWidgets('HomeScreenCallBannerにおいて 進行中試合および次試合情報が正しく描画されること', (
      WidgetTester tester,
    ) async {
      const match1 = MatchModel(
        id: 'm1',
        tournamentId: 'tour_1',
        matchType: '個人戦',
        redName: 'チームA: 山田',
        whiteName: 'チームB: 佐藤',
        status: 'in_progress',
        note: '第1試合場',
      );

      const match2 = MatchModel(
        id: 'm2',
        tournamentId: 'tour_1',
        matchType: '個人戦',
        redName: 'チームC: 田中',
        whiteName: 'チームD: 高橋',
        status: 'waiting',
      );

      const match3 = MatchModel(
        id: 'm3',
        tournamentId: 'tour_1',
        matchType: '個人戦',
        redName: 'チームE: 渡辺',
        whiteName: 'チームF: 伊藤',
        status: 'waiting',
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: HomeScreenCallBanner(
              uniqueInProgress: const [match1],
              uniqueWaiting: const [match2, match3],
              themeColors: themeColors,
              isDark: false,
              enableLiquidGlass: false,
            ),
          ),
        ),
      );

      expect(find.text('進行中'), findsOneWidget);
      expect(find.text('第1試合場'), findsOneWidget);
      expect(find.text('次試合'), findsOneWidget);
      expect(find.textContaining('次々試合:'), findsOneWidget);
    });

    testWidgets('HomeScreenCallBannerにおいて 試合がない場合にバナーが非表示となること', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: HomeScreenCallBanner(
              uniqueInProgress: const [],
              uniqueWaiting: const [],
              themeColors: themeColors,
              isDark: false,
              enableLiquidGlass: false,
            ),
          ),
        ),
      );

      expect(find.text('進行中'), findsNothing);
      expect(find.text('次試合'), findsNothing);
    });
  });
}
