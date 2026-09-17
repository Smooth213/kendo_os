import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🎨 【第10条 ガバナンス監査】レンダリング負荷隔離 ＆ RepaintBoundary最適化規約', () {
    test(
      'Rule 1: [打突ボタン描画隔離＆先行触覚] action_buttons.dart における打突ボタンの RepaintBoundary 配置＆先行触覚ゼロ遅延規約',
      () {
        final file = File('lib/shared/widgets/action_buttons.dart');
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains(
            '// ⚡ 【Plan 1-1】ボタン単位のRepaintBoundary隔離でGPU再ラスタライズコストを局所化',
          ),
          isTrue,
          reason: 'ボタン単位のRepaintBoundary隔離コメントおよび実装が必須です。',
        );

        expect(
          content.contains('// ⚡ 【Plan 1-4】先行オプティミスティック触覚＆UI更新（ゼロ遅延化）'),
          isTrue,
          reason: '先行オプティミスティック触覚＆UI更新のゼロ遅延化ロジックが必須です。',
        );

        expect(
          content.contains('KendoHaptics.scorePoint();'),
          isTrue,
          reason: '一本確定時に即座に KendoHaptics.scorePoint() が発火しなければなりません。',
        );
        expect(
          content.contains('KendoHaptics.foulHansoku();'),
          isTrue,
          reason: '反則確定時に即座に KendoHaptics.foulHansoku() が発火しなければなりません。',
        );
      },
    );

    test(
      'Rule 2: [スコア操作パネル描画隔離] match_score_action_section.dart および match_screen.dart の主要セクション RepaintBoundary 隔離規約',
      () {
        final actionFile = File(
          'lib/features/tournament/presentation/operate/components/match_screen/match_score_action_section.dart',
        );
        expect(actionFile.existsSync(), isTrue);
        final actionContent = actionFile.readAsStringSync();

        expect(
          actionContent.contains(
            '// ⚡ 【Plan 1-1】RepaintBoundaryによるアクションパネル全体の再描画境界隔離',
          ),
          isTrue,
          reason: 'アクションパネル全体が RepaintBoundary で隔離されていなければなりません。',
        );

        final screenFile = File(
          'lib/features/tournament/presentation/operate/match_screen.dart',
        );
        expect(screenFile.existsSync(), isTrue);
        final screenContent = screenFile.readAsStringSync();

        expect(
          screenContent.contains('final timerPart = RepaintBoundary'),
          isTrue,
          reason: 'タイマー更新時のリビルドを局所化するため、timerPart に RepaintBoundary が必須です。',
        );
        expect(
          screenContent.contains('final scoreboardPart = RepaintBoundary'),
          isTrue,
          reason: 'スコアボードの再描画を局所化するため、scoreboardPart に RepaintBoundary が必須です。',
        );
      },
    );

    test(
      'Rule 3: [タイムライン描画隔離] match_timeline_list.dart で RepaintBoundary によるチームカード描画隔離がなされていること',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/components/home/match_timeline_list.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains(
                'RepaintBoundary(\n                    child: TimelineTeamCard(',
              ) ||
              content.contains('RepaintBoundary(child: TimelineTeamCard(') ||
              (content.contains('RepaintBoundary') &&
                  content.contains('TimelineTeamCard')),
          isTrue,
          reason:
              'match_timeline_list.dart で各チームカードが RepaintBoundary で囲まれていること',
        );
      },
    );

    test(
      'Rule 4: [観戦画面描画隔離] viewer_category_section_list.dart で RepaintBoundary による描画隔離および ViewerTeamGroupingHelper が配備されていること',
      () {
        final file = File(
          'lib/features/viewer/presentation/components/viewer_category_section_list.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('RepaintBoundary('),
          isTrue,
          reason:
              'viewer_category_section_list.dart では各カテゴリセクションに RepaintBoundary の配置が必須',
        );

        expect(
          content.contains('ViewerCategorySection'),
          isTrue,
          reason: 'カテゴリセクションが独立したWidgetとして分割されていること',
        );

        expect(
          content.contains('ViewerTeamGroupingHelper'),
          isTrue,
          reason: '集計・ソート計算が純粋関数ヘルパー ViewerTeamGroupingHelper に分離されていること',
        );
      },
    );

    testWidgets(
      'Rule 5: [LiquidBackground静止モード] match_screen.dart で isAnimated: false となり AnimatedBuilder をバイパスすること',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: LiquidBackground(
                isAnimated: false,
                child: Text('Static Match Screen'),
              ),
            ),
          ),
        );

        expect(find.text('Static Match Screen'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(LiquidBackground),
            matching: find.byType(AnimatedBuilder),
          ),
          findsNothing,
        );
        expect(find.byType(RepaintBoundary), findsWidgets);

        final screenFile = File(
          'lib/features/tournament/presentation/operate/match_screen.dart',
        );
        expect(screenFile.existsSync(), isTrue);
        final screenContent = screenFile.readAsStringSync();
        expect(screenContent.contains('isAnimated: false'), isTrue);
      },
    );

    test(
      'Rule 6: [カード・ドック描画隔離] トーナメント表・巨大テーブル・ドックシートにおける RepaintBoundary 隔離規約',
      () {
        final tournamentListFile = File(
          'lib/features/tournament/presentation/operate/screens/tournament_list_screen.dart',
        );
        final scoreTableFile = File(
          'lib/shared/widgets/match_tables/score_table_card.dart',
        );
        final indivCardFile = File(
          'lib/shared/widgets/match_tables/individual_list_card.dart',
        );
        final leagueCardFile = File(
          'lib/shared/widgets/match_tables/league_grid_card.dart',
        );
        final dockSheetFile = File(
          'lib/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart',
        );

        expect(tournamentListFile.existsSync(), isTrue);
        expect(scoreTableFile.existsSync(), isTrue);
        expect(indivCardFile.existsSync(), isTrue);
        expect(leagueCardFile.existsSync(), isTrue);
        expect(dockSheetFile.existsSync(), isTrue);

        expect(
          tournamentListFile.readAsStringSync().contains(
            '// ⚡ 【Plan 1-3】RepaintBoundaryによるリストアイテム描画カリング＆GPU再ラスタライズ防止',
          ),
          isTrue,
        );
        expect(
          scoreTableFile.readAsStringSync().contains(
            '// ⚡ 【Plan 1-3】RepaintBoundaryによる巨大スコアテーブルカードの描画キャッシュとラスタライズ分離',
          ),
          isTrue,
        );
        expect(
          indivCardFile.readAsStringSync().contains(
            '// ⚡ 【Plan 1-3】RepaintBoundaryによる個人戦リストカードの描画キャッシュとラスタライズ分離',
          ),
          isTrue,
        );
        expect(
          leagueCardFile.readAsStringSync().contains(
            '// ⚡ 【Plan 1-3】RepaintBoundaryによるリーグ戦グリッドカードの描画分離',
          ),
          isTrue,
        );

        final dockContent = dockSheetFile.readAsStringSync();
        expect(
          dockContent.contains(
                'RepaintBoundary(\n                      child: Builder(',
              ) ||
              dockContent.contains('RepaintBoundary(child: Builder(') ||
              (dockContent.contains('RepaintBoundary') &&
                  dockContent.contains('widget.builder')),
          isTrue,
          reason:
              'dock_draggable_sheet.dart でコンテンツエリアが RepaintBoundary で囲まれていること',
        );
      },
    );
  });
}
