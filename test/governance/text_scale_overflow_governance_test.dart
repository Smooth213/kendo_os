import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_team_header_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_players_score_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/tournament_header_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_card_result_list.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_format_selector.dart';
import 'package:kendo_os/features/tournament/presentation/providers/match_calculator_provider.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_settings_bottom_sheet.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

// ============================================================================
// 🛡️ KendoOS フォントサイズ拡大（標準・大・特大）文字切れ・省略（...）完全防止ガバナンステスト
// ============================================================================
// 【ガバナンス第3条：デザインシステム・UIレイアウト・テーマ視認性規約】
// 1. 静的コード規約:
//    - 主要ヘッダー・コールバナー・タイムラインにおいて、FittedBox等による文字縮小・自動収縮が適用されていること。
//    - 固定幅直下の無防備なText直書きを防止すること。
// 2. 動的描画規約:
//    - 標準(1.0x)・大(1.20x)・特大(1.35x)の全フォントサイズにおいて、
//      文字あふれ（RenderFlex overflow）および省略（TextOverflow.ellipsis による未収縮切断）が0件であること。
// ============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ [ガバナンス第3条] フォントサイズ拡大時の文字切れ・省略（...）完全防止規約', () {
    late List<File> dartFiles;

    setUpAll(() {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist.');

      dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
    });

    // ------------------------------------------------------------------------
    // 静的コードガバナンス監査
    // ------------------------------------------------------------------------
    test('【静的規約 1】主要ヘッダー・バナーコンポーネントが FittedBox による縮小防護を備えていること', () {
      final targetComponents = [
        'lib/shared/widgets/app_header.dart',
        'lib/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart',
        'lib/features/tournament/presentation/operate/components/home/tournament_header_card.dart',
        'lib/features/tournament/presentation/operate/components/home/home_screen_call_banner.dart',
        'lib/features/viewer/presentation/components/viewer_call_banner.dart',
        'lib/features/tournament/presentation/operate/components/timeline/timeline_group_header.dart',
        'lib/features/viewer/presentation/components/viewer_group_match_card.dart',
        'lib/features/viewer/components/viewer_bunaiksen_match_card.dart',
      ];

      for (final relativePath in targetComponents) {
        final file = dartFiles.firstWhere(
          (f) => f.path.replaceAll('\\', '/').endsWith(relativePath),
          orElse: () => throw Exception('ファイルが見つかりません: $relativePath'),
        );

        final content = file.readAsStringSync();
        expect(
          content.contains('FittedBox') || content.contains('BoxFit.scaleDown'),
          isTrue,
          reason:
              'コンポーネント $relativePath は文字拡大時に文字切れ・省略を防ぐため FittedBox を使用していなければなりません。',
        );
      }
    });

    test('【静的規約 2】AppHeader でのタイトル直書きは禁止され、FittedBox による動的縮小が施されていること', () {
      final headerFile = dartFiles.firstWhere(
        (f) => f.path
            .replaceAll('\\', '/')
            .endsWith('lib/shared/widgets/app_header.dart'),
      );
      final content = headerFile.readAsStringSync();
      expect(content.contains('FittedBox'), isTrue);
      expect(content.contains('BoxFit.scaleDown'), isTrue);
    });

    test(
      '【静的規約 3】DockBottomSheetHeader でのタイトル直書きは禁止され、FittedBox による動的縮小が施されていること',
      () {
        final dockFile = dartFiles.firstWhere(
          (f) => f.path
              .replaceAll('\\', '/')
              .endsWith(
                'lib/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart',
              ),
        );
        final content = dockFile.readAsStringSync();
        expect(content.contains('FittedBox'), isTrue);
        expect(content.contains('BoxFit.scaleDown'), isTrue);
      },
    );

    // ------------------------------------------------------------------------
    // 動的レンダリング文字あふれ・省略検知ヘルパー
    // ------------------------------------------------------------------------
    Future<void> testWidgetWithTextScalers({
      required WidgetTester tester,
      required Widget widget,
      required String componentName,
      double width = 390.0,
      double height = 844.0,
    }) async {
      final scalers = [
        const TextScaler.linear(1.0),
        const TextScaler.linear(1.20),
        const TextScaler.linear(1.35),
      ];

      for (final scaler in scalers) {
        FlutterErrorDetails? caughtError;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          caughtError = details;
          originalOnError?.call(details);
        };

        await tester.binding.setSurfaceSize(Size(width, height));
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData(brightness: Brightness.light),
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, height),
                  textScaler: scaler,
                ),
                child: Scaffold(
                  body: SizedBox(width: width, child: widget),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        FlutterError.onError = originalOnError;

        final scaleLabel = scaler == const TextScaler.linear(1.0)
            ? '標準 (1.0x)'
            : (scaler == const TextScaler.linear(1.20)
                  ? '大 (1.2x)'
                  : '特大 (1.35x)');

        expect(
          caughtError,
          isNull,
          reason: '[$componentName - $scaleLabel] レイアウトオーバーフロー例外が発生してはならない',
        );

        final paragraphs = tester.renderObjectList<RenderParagraph>(
          find.byType(RichText),
        );
        for (final p in paragraphs) {
          if (p.didExceedMaxLines) {
            fail(
              '[$componentName - $scaleLabel] 文字列が領域を超えて文字切れ・省略されています: "${p.text.toPlainText()}"',
            );
          }
        }
      }
    }

    // ------------------------------------------------------------------------
    // 動的描画検証テストケース
    // ------------------------------------------------------------------------
    testWidgets(
      '【動的規約 1】AppBar標準ヘッダー (AppHeader): 長文タイトルでもFittedBoxで綺麗に収まり文字切れゼロ',
      (tester) async {
        await testWidgetWithTextScalers(
          tester: tester,
          widget: const AppHeader(
            title: '2026/09/24 過去の大会 (西日本選抜少年剣道大会アーカイブ 決勝会場特設コート)',
          ),
          componentName: 'AppHeader',
        );
      },
    );

    testWidgets(
      '【動的規約 2】ドックボトムシートヘッダー (DockBottomSheetHeader): 特大時もボタン押し出し・文字切れゼロ',
      (tester) async {
        await testWidgetWithTextScalers(
          tester: tester,
          widget: const DockBottomSheetHeader(
            title: '第3試合場 Aコート 準決勝第2試合 詳細設定シート',
            icon: Icons.menu_book_rounded,
          ),
          componentName: 'DockBottomSheetHeader',
        );
      },
    );

    testWidgets('【動的規約 3】試合チームヘッダー行 (MatchTeamHeaderRow): 左右長文チーム名でも重ならず全文表示', (
      tester,
    ) async {
      await testWidgetWithTextScalers(
        tester: tester,
        widget: const MatchTeamHeaderRow(
          redTeam: '岡山県代表 備前少年剣道道場連合会',
          whiteTeam: '広島県代表 広島南剣道親善クラブ',
          textColor: Colors.black,
        ),
        componentName: 'MatchTeamHeaderRow',
      );
    });

    testWidgets(
      '【動的規約 4】試合選手・スコア行 (MatchPlayersScoreRow): 左右長文選手名でもスコアと干渉せず全文表示',
      (tester) async {
        await testWidgetWithTextScalers(
          tester: tester,
          widget: const MatchPlayersScoreRow(
            redName: '岡山備前: 長谷川健太郎',
            whiteName: '広島南: 佐々木小次郎',
            isRedOwn: true,
            isWhiteOwn: false,
            redPoints: [],
            whitePoints: [],
            isDraw: false,
            textColor: Colors.black,
            subTextColor: Colors.grey,
          ),
          componentName: 'MatchPlayersScoreRow',
        );
      },
    );

    testWidgets(
      '【動的規約 5】大会情報ヘッダー (TournamentHeaderCard): 長文会場名でもFittedBoxで綺麗に全文収まる',
      (tester) async {
        final mockTournament = TournamentModel(
          id: 'gov_tourney',
          name: '第72回全日本都道府県対抗剣道大会 予選',
          date: DateTime(2026, 9, 24),
          venue: '岡山武道館 本館第1メインアリーナ特設道場',
          categories: const ['小学生の部', '中学生の部'],
          organizationId: 'dojo_123',
        );

        await testWidgetWithTextScalers(
          tester: tester,
          widget: TournamentHeaderCard(tournament: mockTournament),
          componentName: 'TournamentHeaderCard',
        );
      },
    );

    testWidgets(
      '【動的規約 6】対戦履歴カードリスト (ExpeditionCardResultList): 長文試合場・進行見出しでも全文表示',
      (tester) async {
        await testWidgetWithTextScalers(
          tester: tester,
          widget: ExpeditionCardResultList(
            cardResults: [
              ExpeditionCardResult(
                cardTitle: '第7試合場, 4回戦, 第23試合目 (予選トーナメント)',
                opponentTeamName: '倉敷少年剣道クラブ旭東中学校',
                myWins: 3,
                myPoints: 5,
                oppWins: 1,
                oppPoints: 2,
                isWin: true,
                isDraw: false,
                resultType: 'team',
                scene: '1回戦',
              ),
            ],
            isDark: false,
          ),
          componentName: 'ExpeditionCardResultList',
        );
      },
    );

    testWidgets('【動的規約 7】試合編集シート (MatchEditSheet): タブ「コート・メモ」等全文字サイズで文字切れゼロ', (
      tester,
    ) async {
      final mockMatch = MatchModel(
        id: 'gov_m1',
        tournamentId: 'test_tourney_id',
        matchType: 'team',
        redName: '岡山道場',
        whiteName: '広島道場',
        status: 'playing',
        order: 1.0,
      );

      await testWidgetWithTextScalers(
        tester: tester,
        widget: MatchEditSheet(
          matches: [mockMatch],
          tournamentId: 'test_tourney_id',
          themeColors: AppThemeColors.ofMode(isDark: false, mode: 'normal'),
        ),
        componentName: 'MatchEditSheet',
      );
    });

    testWidgets(
      '【動的規約 8】コート計算機形式選択 (MatchCalculatorFormatSelector): ボタン文字切れゼロ',
      (tester) async {
        final notifier = MatchCalculatorNotifier();
        await testWidgetWithTextScalers(
          tester: tester,
          widget: MatchCalculatorFormatSelector(
            settings: notifier.state.settings,
            notifier: notifier,
          ),
          componentName: 'MatchCalculatorFormatSelector',
        );
      },
    );

    testWidgets(
      '【動的規約 9】観客用表示設定シート (ViewerSettingsBottomSheet): 全設定タイルで文字切れゼロ',
      (tester) async {
        await testWidgetWithTextScalers(
          tester: tester,
          widget: const ViewerSettingsBottomSheet(),
          componentName: 'ViewerSettingsBottomSheet',
        );
      },
    );
  });
}
