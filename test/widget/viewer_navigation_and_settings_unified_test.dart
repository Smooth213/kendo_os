import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_call_banner.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_quick_action_buttons.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_settings_bottom_sheet.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_share_dialog.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_tournament_info_card.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('[Widget] 観戦ナビゲーション・大会情報・共有・設定UI 統合検証テスト', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('呼出バナーにおいて進行中および待機中の試合情報が正しく描画されること', (tester) async {
      final match1 = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: 'team',
        order: 1,
        redName: '先鋒: 田中',
        whiteName: '先鋒: 佐藤',
        status: 'in_progress',
        note: '1回戦',
      );
      final match2 = MatchModel(
        id: 'm2',
        tournamentId: 't1',
        matchType: 'team',
        order: 2,
        redName: '次鋒: 鈴木',
        whiteName: '次鋒: 高橋',
        status: 'waiting',
        note: '1回戦',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViewerCallBanner(
              inProgressMatches: [match1],
              waitingMatches: [match2],
            ),
          ),
        ),
      );

      expect(find.text('進行中'), findsOneWidget);
      expect(find.text('次試合'), findsOneWidget);
    });

    testWidgets('大会情報カードにおいて大会名・日時・会場・注意事項が正しく描画されること', (tester) async {
      final tournament = TournamentModel(
        id: 't1',
        organizationId: 'org1',
        name: '全国剣道大会',
        date: DateTime(2026, 8, 20),
        venue: '日本武道館',
        notes: '注意事項メモ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViewerTournamentInfoCard(tournament: tournament),
          ),
        ),
      );

      expect(find.text('全国剣道大会'), findsOneWidget);
      expect(find.text('2026年08月20日'), findsOneWidget);
      expect(find.text('日本武道館'), findsOneWidget);
      expect(find.text('注意事項メモ'), findsOneWidget);
    });

    testWidgets('観客用クイックアクションボタンが正しく描画されること', (tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: const Scaffold(
              body: ViewerQuickActionButtons(
                tournamentId: 't1',
                enableLiquidGlass: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('試合結果一覧'), findsOneWidget);
      expect(find.text('大会プログラム'), findsOneWidget);
    });

    testWidgets('観戦用設定ボトムシートにおいてテーマや省電力設定項目が正しく描画されること', (tester) async {
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(
            home: Scaffold(body: ViewerSettingsBottomSheet()),
          ),
        ),
      );

      expect(find.text('表示設定'), findsOneWidget);
      expect(find.text('テーマの切り替え'), findsOneWidget);
      expect(find.text('省エネモード'), findsOneWidget);
      expect(find.text('背景アニメーション停止'), findsOneWidget);
      expect(find.text('サーマル冷却・省電力制御'), findsOneWidget);
    });

    testWidgets('観戦リンク共有ダイアログにおいてQRコードと送信ボタンが正しく描画されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ViewerShareDialog(tournamentId: 't1', dojoId: 'd1'),
          ),
        ),
      );

      expect(find.text('大会観戦リンク'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('LINEやSNSでURLを送る'), findsOneWidget);
      expect(find.text('閉じる'), findsOneWidget);
    });
  });
}
