import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔋 【ガバナンス監査 25/25】端末低負荷・省電力・I/Oバッファリング＆LRUメモリ保護 永続保証規約', () {
    test(
      'Rule 1: liquid_background.dart における毎フレーム StackTrace 走査の再混入禁止 ＆ RadialGradient 保持規約',
      () {
        final file = File('lib/shared/widgets/liquid_background.dart');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'liquid_background.dart が存在すること',
        );
        final content = file.readAsStringSync();

        // build 内での StackTrace.current.toString() 走査が完全排除されていること
        expect(
          content.contains('StackTrace.current.toString()'),
          isFalse,
          reason:
              '毎フレームの StackTrace.current.toString() 走査はCPU酷使と発熱を招くため完全禁止です。',
        );

        // RadialGradient によるソフトグラデーションが使用されていること（GPUガウシアンブラー負荷削減）
        expect(
          content.contains('RadialGradient'),
          isTrue,
          reason:
              'GPU高負荷なBackdropFilterガウシアンブラーをバイパスするため、オーブには RadialGradient を使用してください。',
        );

        // RepaintBoundary で前面UIへの再描画波及を遮断していること
        expect(
          content.contains('RepaintBoundary'),
          isTrue,
          reason:
              '背景アニメーションが前面Scaffold全体に不要な再描画を伝播させないため、RepaintBoundary で保護してください。',
        );
      },
    );

    test(
      'Rule 2: match_timer_provider.dart における Timer.periodic 内ディスクI/O禁止 ＆ メモリ集約規約',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/providers/match_timer_provider.dart',
        );
        expect(
          file.existsSync(),
          isTrue,
          reason: 'match_timer_provider.dart が存在すること',
        );
        final content = file.readAsStringSync();

        // RenseikaiMasterTimerNotifier の Timer.periodic 内でメモリ集約されていること
        expect(
          content.contains(
            '// 🔋 毎秒のディスクI/O (SharedPreferences書き込み) を撤廃し、メモリ内State更新のみに集約',
          ),
          isTrue,
          reason: 'タイマーループ内でのメモリ集約・毎秒Prefs書き込み排除コメントが存在すること',
        );

        // state > 0 のブロック内で _saveState() が呼ばれていないこと（毎秒ディスクI/Oの完全禁止）
        final ifStatePos = content.indexOf('if (state > 0) {');
        expect(ifStatePos, isNonNegative, reason: 'if (state > 0) ブロックが存在すること');
        final elsePos = content.indexOf('} else {', ifStatePos);
        expect(elsePos, isNonNegative, reason: 'else ブロックが存在すること');
        final stateDecrementBlock = content.substring(ifStatePos, elsePos);

        expect(
          stateDecrementBlock.contains('state--;'),
          isTrue,
          reason: '毎秒のカウントダウンはメモリ内State更新のみで行うこと',
        );
        expect(
          stateDecrementBlock.contains('_saveState();'),
          isFalse,
          reason: '毎秒のカウントダウンブロック内で _saveState() を呼ぶことは禁止されています。',
        );
      },
    );

    test(
      'Rule 3: program_viewer_pdf_page_cache.dart における LRU キャッシュ上限 ＆ メモリ解放(clearUrl)規約',
      () {
        final file = File(
          'lib/features/tournament/presentation/components/program_viewer/program_viewer_pdf_page_cache.dart',
        );
        expect(
          file.existsSync(),
          isTrue,
          reason: 'program_viewer_pdf_page_cache.dart が存在すること',
        );
        final content = file.readAsStringSync();

        // LRU最大保持ページ数定数が定義されていること
        expect(
          content.contains('maxCachedPagesPerDoc'),
          isTrue,
          reason: '無制限なPDFバイト蓄積を防ぐため、maxCachedPagesPerDoc 定数によるLRU上限が必要です。',
        );

        // 単一ページキャッシュの解放メソッド clearUrl が配備されていること
        expect(
          content.contains('void clearUrl(String url)'),
          isTrue,
          reason: 'ビューワー画面を閉じた際に単一ページPDFバイトを即座に解放するための clearUrl メソッドが必須です。',
        );
      },
    );

    test(
      'Rule 4: match_snapshot_helper.dart / match_snapshot_service.dart におけるドキュメント内スナップショット保持数上限(1件)規約',
      () {
        final helperFile = File(
          'lib/features/match/application/services/match_snapshot_helper.dart',
        );
        expect(
          helperFile.existsSync(),
          isTrue,
          reason: 'match_snapshot_helper.dart が存在すること',
        );
        final helperContent = helperFile.readAsStringSync();

        // デフォルトの maxSnapshots が 1 であること（直前Undo専用、ドキュメント肥大化防止）
        expect(
          helperContent.contains('this.maxSnapshots = 1'),
          isTrue,
          reason:
              'Firestoreドキュメント肥大化と通信量増大を防ぐため、スナップショット保持上限はデフォルト1件でなければなりません。',
        );

        final serviceFile = File(
          'lib/features/tournament/presentation/operate/providers/match_snapshot_service.dart',
        );
        expect(
          serviceFile.existsSync(),
          isTrue,
          reason: 'match_snapshot_service.dart が存在すること',
        );
        final serviceContent = serviceFile.readAsStringSync();

        // takeSnapshot において 20件保持ではなく 1件保持になっていること
        expect(
          serviceContent.contains('newSnapshots.length > 1'),
          isTrue,
          reason:
              'MatchSnapshotService.takeSnapshot においてもスナップショット保持数は1件に制限されなければなりません。',
        );
        expect(
          serviceContent.contains('newSnapshots.length > 20'),
          isFalse,
          reason: '旧仕様の20件スナップショット保持コードは残存してはなりません。',
        );
      },
    );

    test(
      'Rule 5: match_list_provider.dart における matchListByTournamentProvider の autoDispose ＆ keepAlive 配備規約',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/providers/match_list_provider.dart',
        );
        expect(
          file.existsSync(),
          isTrue,
          reason: 'match_list_provider.dart が存在すること',
        );
        final content = file.readAsStringSync();

        // matchListByTournamentProvider が autoDispose であること
        expect(
          content.contains(
            'StreamProvider.family.autoDispose<List<MatchModel>, String>',
          ),
          isTrue,
          reason:
              '非アクティブな大会のFirestoreリスナーがバックグラウンドで動作し続けるのを防ぐため、autoDispose が必須です。',
        );

        // ref.keepAlive によるキャッシュ保持が配備されていること（画面遷移時の再接続チラつき防止）
        expect(
          content.contains('ref.keepAlive()'),
          isTrue,
          reason: '画面切り替え時の頻繁な切断・再接続を防ぐため、keepAlive によるキャッシュ保持タイマーが必要です。',
        );
      },
    );
  });
}
