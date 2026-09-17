import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🧵 【第12条 ガバナンス監査】Isolate完全分離・非同期バックオフ ＆ 非ブロッキング処理規約', () {
    test(
      'Rule 1: [CRDT非同期マージ] sync_crdt_merger.dart における mergeAndRebuildAsync および compute ワーカー配備規約',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/providers/sync_crdt_merger.dart',
        );
        expect(file.existsSync(), isTrue);
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
      'Rule 2: [PDF非同期オフロード] pdf_service.dart におけるPDF生成の compute (Isolate) オフロード義務付け規約',
      () {
        final file = File('lib/features/pdf/pdf_service.dart');
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('compute(_generatePdfBytesInWorker'),
          isTrue,
          reason:
              '_generatePdfBytes はUIスレッドのフリーズを防ぐため、必ず compute 経由で実行されなければなりません。',
        );

        expect(
          content.contains('Future<Uint8List> _generatePdfBytesInWorker'),
          isTrue,
          reason: 'computeで呼び出す _generatePdfBytesInWorker トップレベル関数が必須です。',
        );
      },
    );

    test(
      'Rule 3: [生フォントバイトキャッシュ] pdf_font_loader.dart における生フォントバイト(loadFontBytes)配備規約',
      () {
        final file = File('lib/features/pdf/services/pdf_font_loader.dart');
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('loadFontBytes()'),
          isTrue,
          reason: 'Isolateへ安全にフォントデータを渡すための loadFontBytes() メソッドが必須です。',
        );
        expect(
          content.contains('_cachedRawBytes'),
          isTrue,
          reason: 'フォントバイトの重複読み込みを防ぐための _cachedRawBytes キャッシュが必須です。',
        );
      },
    );

    test(
      'Rule 4: [非ブロッキングバックオフ] sync_engine.dart における Future.delayed ブロッキング禁止 ＆ 非同期バックオフ(_nextAttemptAt)規約',
      () {
        final file = File(
          'lib/shared/infrastructure/repository/sync_engine.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        final hasBlockingDelayed = content.contains(
          RegExp(r'await\s+Future\.delayed'),
        );
        expect(
          hasBlockingDelayed,
          isFalse,
          reason:
              'SyncEngine内で await Future.delayed を使用してスレッドをブロックすることは禁止されています。非同期バックオフ（_nextAttemptAt）を使用してください。',
        );

        expect(
          content.contains('_nextAttemptAt'),
          isTrue,
          reason: '非同期バックオフ管理のための _nextAttemptAt タイムスタンプ変数が必須です。',
        );
        expect(
          content.contains('void resetBackoffAndProcess()'),
          isTrue,
          reason: '電波復帰時や手動同期トリガー用の resetBackoffAndProcess() メソッドが必須です。',
        );
      },
    );

    test(
      'Rule 5: [アセットノンブロッキング暖機] app_startup.dart における prewarmAppAssets 配備およびノンブロッキング事前ウォームアップ規約',
      () {
        final file = File('lib/bootstrap/app_startup.dart');
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('static Future<void> prewarmAppAssets()'),
          isTrue,
          reason: 'シェーダージャンクを防止するため、prewarmAppAssets メソッドが必須です。',
        );

        expect(
          content.contains('unawaited(prewarmAppAssets());'),
          isTrue,
          reason:
              '起動をブロックしないよう、unawaited(prewarmAppAssets()); で事前ウォームアップを実行しなければなりません。',
        );

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

    test('Rule 6: [ブートストラップ最適化結合] main.dart において 5大最適化パイプラインが確実に結合されていること', () {
      final mainFile = File('lib/main.dart');
      expect(mainFile.existsSync(), isTrue);
      final content = mainFile.readAsStringSync();

      expect(
        content.contains('WebPlatformOptimizer.applyOptimizations()'),
        isTrue,
        reason:
            'main.dart で WebPlatformOptimizer.applyOptimizations() が呼ばれていること',
      );
      expect(
        content.contains('AppStartup.configureImageCache()'),
        isTrue,
        reason: 'main.dart で AppStartup.configureImageCache() が呼ばれていること',
      );
      expect(
        content.contains('AppStartup.configureFontOptimization()'),
        isTrue,
        reason: 'main.dart で AppStartup.configureFontOptimization() が呼ばれていること',
      );
      expect(
        content.contains('soundServiceProvider') &&
            content.contains('.prewarm()'),
        isTrue,
        reason: 'main.dart で soundServiceProvider の prewarm が呼ばれていること',
      );
      expect(
        content.contains('userDataCloudSyncManagerProvider') &&
            content.contains('.initialize()'),
        isTrue,
        reason:
            'main.dart で userDataCloudSyncManagerProvider の initialize が呼ばれていること',
      );
      expect(
        content.contains('AppStartup.prewarmAppAssets()'),
        isTrue,
        reason: 'main.dart で AppStartup.prewarmAppAssets() が呼ばれていること',
      );
    });

    test(
      'Rule 7: [SyncEngineライフサイクル＆タイマー破棄] SyncEngine の AppLifecycleListener コールドスリープ ＆ dispose時破棄規約',
      () {
        final syncEngineFile = File(
          'lib/shared/infrastructure/repository/sync_engine.dart',
        );
        expect(syncEngineFile.existsSync(), isTrue);
        final content = syncEngineFile.readAsStringSync();

        expect(
          content.contains('AppLifecycleListener('),
          isTrue,
          reason: 'SyncEngine に AppLifecycleListener が配備されていなければならない',
        );
        expect(
          content.contains('onPause: _stopSyncLoop'),
          isTrue,
          reason: 'paused時にタイマーループを停止しなければならない',
        );
        expect(
          content.contains('_lifecycleListener?.dispose()'),
          isTrue,
          reason: 'SyncEngine の dispose() で _lifecycleListener が破棄されていなければならない',
        );
        expect(
          content.contains('_debounceSyncTimer?.cancel()'),
          isTrue,
          reason:
              'SyncEngine の dispose() で _debounceSyncTimer?.cancel() を呼ばなければならない',
        );
      },
    );
  });
}
