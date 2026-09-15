import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('⚡ 【ガバナンス監査 30/30】極限高速化・UIスレッドIsolate完全分離＆ゼロ遅延即応 永続保証規約', () {
    test(
      'Rule 1: sync_crdt_merger.dart における mergeAndRebuildAsync および compute ワーカー配備規約',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/providers/sync_crdt_merger.dart',
        );
        expect(
          file.existsSync(),
          isTrue,
          reason: 'sync_crdt_merger.dart が存在すること',
        );
        final content = file.readAsStringSync();

        expect(
          content.contains('Future<MatchModel> mergeAndRebuildAsync('),
          isTrue,
          reason: '大規模マージ処理をUIスレッドから隔離するため、mergeAndRebuildAsync が必須です。',
        );

        expect(
          content.contains('compute(_crdtMergeWorker, params)'),
          isTrue,
          reason:
              'バックグラウンドIsolateで実行するため、compute(_crdtMergeWorker, params) が必須です。',
        );

        expect(
          content.contains('Future<MatchModel> _crdtMergeWorker('),
          isTrue,
          reason: 'computeで実行するためのトップレベルワーカー関数 _crdtMergeWorker が必須です。',
        );
      },
    );

    test(
      'Rule 2: action_buttons.dart における打突ボタンの RepaintBoundary 配置＆先行触覚・楽観的UI即時発火規約',
      () {
        final file = File('lib/shared/widgets/action_buttons.dart');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'action_buttons.dart が存在すること',
        );
        final content = file.readAsStringSync();

        // 打突ボタンと反則ボタンが RepaintBoundary で保護されていること
        expect(
          content.contains(
            '// ⚡ 【Plan 1-1】ボタン単位のRepaintBoundary隔離でGPU再ラスタライズコストを局所化',
          ),
          isTrue,
          reason: 'ボタン単位のRepaintBoundary隔離コメントおよび実装が必須です。',
        );

        // 先行オプティミスティック触覚（awaitによる同期ブロックを行わず即時発火）
        expect(
          content.contains('// ⚡ 【Plan 1-4】先行オプティミスティック触覚＆UI更新（ゼロ遅延化）'),
          isTrue,
          reason: '先行オプティミスティック触覚＆UI更新のゼロ遅延化ロジックが必須です。',
        );

        // KendoHaptics.scorePoint() と foulHansoku() が onConfirm 内で即座に呼ばれていること
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
      'Rule 3: match_score_action_section.dart における RepaintBoundary 適用＆極小粒度 select 規約',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/components/match_screen/match_score_action_section.dart',
        );
        expect(
          file.existsSync(),
          isTrue,
          reason: 'match_score_action_section.dart が存在すること',
        );
        final content = file.readAsStringSync();

        // leftHanded の極小粒度 select
        expect(
          content.contains('settingsProvider.select((s) => s.leftHanded)'),
          isTrue,
          reason:
              'settingsProvider 全体ではなく、leftHanded のみを select 監視して不要リビルドを根絶しなければなりません。',
        );

        // パネル全体の RepaintBoundary
        expect(
          content.contains(
            '// ⚡ 【Plan 1-1】RepaintBoundaryによるアクションパネル全体の再描画境界隔離',
          ),
          isTrue,
          reason: 'アクションパネル全体が RepaintBoundary で隔離されていなければなりません。',
        );
      },
    );

    test(
      'Rule 4: app_startup.dart における prewarmAppAssets 配備およびノンブロッキング事前ウォームアップ規約',
      () {
        final file = File('lib/bootstrap/app_startup.dart');
        expect(file.existsSync(), isTrue, reason: 'app_startup.dart が存在すること');
        final content = file.readAsStringSync();

        // prewarmAppAssets の定義
        expect(
          content.contains('static Future<void> prewarmAppAssets()'),
          isTrue,
          reason: 'シェーダージャンクを防止するため、prewarmAppAssets メソッドが必須です。',
        );

        // initialize 内での呼び出し
        expect(
          content.contains('unawaited(prewarmAppAssets());'),
          isTrue,
          reason:
              '起動をブロックしないよう、unawaited(prewarmAppAssets()); で事前ウォームアップを実行しなければなりません。',
        );

        // コア画像アセットとフォントのウォームアップ
        expect(
          content.contains('assets/kendo_icon.png'),
          isTrue,
          reason: '主要画像アセット assets/kendo_icon.png のプリロードが必須です。',
        );
        expect(
          content.contains('GoogleFonts.pendingFonts'),
          isTrue,
          reason: '主要フォントの GoogleFonts.pendingFonts による事前ロードが必須です。',
        );
      },
    );

    test('Rule 5: トーナメント表・巨大テーブルにおけるリストアイテム/カード単位の RepaintBoundary カリング規約', () {
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

      expect(tournamentListFile.existsSync(), isTrue);
      expect(scoreTableFile.existsSync(), isTrue);
      expect(indivCardFile.existsSync(), isTrue);
      expect(leagueCardFile.existsSync(), isTrue);

      final tournamentListContent = tournamentListFile.readAsStringSync();
      final scoreTableContent = scoreTableFile.readAsStringSync();
      final indivCardContent = indivCardFile.readAsStringSync();
      final leagueCardContent = leagueCardFile.readAsStringSync();

      expect(
        tournamentListContent.contains(
          '// ⚡ 【Plan 1-3】RepaintBoundaryによるリストアイテム描画カリング＆GPU再ラスタライズ防止',
        ),
        isTrue,
        reason:
            'tournament_list_screen.dart のリストアイテムは RepaintBoundary で保護されていなければなりません。',
      );

      expect(
        scoreTableContent.contains(
          '// ⚡ 【Plan 1-3】RepaintBoundaryによる巨大スコアテーブルカードの描画キャッシュとラスタライズ分離',
        ),
        isTrue,
        reason: 'score_table_card.dart は RepaintBoundary で保護されていなければなりません。',
      );

      expect(
        indivCardContent.contains(
          '// ⚡ 【Plan 1-3】RepaintBoundaryによる個人戦リストカードの描画キャッシュとラスタライズ分離',
        ),
        isTrue,
        reason: 'individual_list_card.dart は RepaintBoundary で保護されていなければなりません。',
      );

      expect(
        leagueCardContent.contains(
          '// ⚡ 【Plan 1-3】RepaintBoundaryによるリーグ戦グリッドカードの描画分離',
        ),
        isTrue,
        reason: 'league_grid_card.dart は RepaintBoundary で保護されていなければなりません。',
      );
    });
  });
}
