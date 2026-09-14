import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('⚡ 【ガバナンス監査 24/24】UIレスポンス高速化・局所再描画・非同期バックオフ 永続保証規約', () {
    test('Rule 1: sync_engine.dart における Future.delayed ブロッキングスリープの再混入完全禁止規約', () {
      final file = File(
        'lib/shared/infrastructure/repository/sync_engine.dart',
      );
      expect(file.existsSync(), isTrue, reason: 'sync_engine.dart が存在すること');
      final content = file.readAsStringSync();

      // processQueue 内で await Future.delayed による同期ブロックが存在しないこと
      final hasBlockingDelayed = content.contains(
        RegExp(r'await\s+Future\.delayed'),
      );
      expect(
        hasBlockingDelayed,
        isFalse,
        reason:
            'SyncEngine内で await Future.delayed を使用してスレッドをブロックすることは禁止されています。非同期バックオフ（_nextAttemptAt）を使用してください。',
      );
    });

    test(
      'Rule 2: sync_engine.dart における非同期バックオフ変数(_nextAttemptAt)および即時再送メソッド(resetBackoffAndProcess)配備規約',
      () {
        final file = File(
          'lib/shared/infrastructure/repository/sync_engine.dart',
        );
        final content = file.readAsStringSync();

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
      'Rule 3: pdf_service.dart におけるPDF生成の compute (Isolate) オフロード義務付け規約',
      () {
        final file = File('lib/features/pdf/pdf_service.dart');
        expect(file.existsSync(), isTrue, reason: 'pdf_service.dart が存在すること');
        final content = file.readAsStringSync();

        // compute を使ってPDF生成をオフロードしていること
        expect(
          content.contains('compute(_generatePdfBytesInWorker'),
          isTrue,
          reason:
              '_generatePdfBytes はUIスレッドのフリーズを防ぐため、必ず compute 経由で実行されなければなりません。',
        );

        // ワーカー用トップレベル関数が存在すること
        expect(
          content.contains('Future<Uint8List> _generatePdfBytesInWorker'),
          isTrue,
          reason: 'computeで呼び出す _generatePdfBytesInWorker トップレベル関数が必須です。',
        );
      },
    );

    test('Rule 4: pdf_font_loader.dart における生フォントバイト(loadFontBytes)配備規約', () {
      final file = File('lib/features/pdf/services/pdf_font_loader.dart');
      expect(file.existsSync(), isTrue, reason: 'pdf_font_loader.dart が存在すること');
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
    });

    test('Rule 5: scoreboard.dart における階層パス直結アクセス優先規約 (O(1) 直結監視)', () {
      final file = File('lib/shared/widgets/scoreboard.dart');
      expect(file.existsSync(), isTrue, reason: 'scoreboard.dart が存在すること');
      final content = file.readAsStringSync();

      // dojoId と tournamentId を用いた直接パス指定が含まれていること
      expect(
        content.contains('.collection(\'organizations\')') &&
            content.contains('.collection(\'tournaments\')') &&
            content.contains('.collection(\'matches\')'),
        isTrue,
        reason:
            'WebScoreboardMatchProvider は collectionGroup より前に、organizations/tournaments/matches の直接パス監視を優先しなければなりません。',
      );
    });

    test('Rule 6: プログラム画像レンダリングにおける cacheWidth / cacheHeight ダウンサンプリング規約', () {
      final viewsFile = File(
        'lib/features/tournament/presentation/components/program_management/program_management_content_views.dart',
      );
      expect(viewsFile.existsSync(), isTrue);
      final viewsContent = viewsFile.readAsStringSync();

      // グリッド・リストの両方で cacheWidth が設定されていること
      expect(
        viewsContent.contains('cacheWidth: 400'),
        isTrue,
        reason: 'GridViewのサムネイルには cacheWidth: 400 が必須です。',
      );
      expect(
        viewsContent.contains('cacheWidth: 150'),
        isTrue,
        reason: 'ListViewのサムネイルには cacheWidth: 150 が必須です。',
      );

      final bodyFile = File(
        'lib/features/tournament/presentation/components/program_viewer/program_viewer_image_body.dart',
      );
      expect(bodyFile.existsSync(), isTrue);
      final bodyContent = bodyFile.readAsStringSync();

      expect(
        bodyContent.contains('cacheWidth: displaySize.width.toInt()'),
        isTrue,
        reason: 'プログラムビューア本文の画像には動的 cacheWidth が必須です。',
      );
    });

    test(
      'Rule 7: match_screen.dart における singleMatchProvider 局所購読および RepaintBoundary 配備規約',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/match_screen.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        // singleMatchProvider を使用していること
        expect(
          content.contains('singleMatchProvider(widget.matchId)'),
          isTrue,
          reason:
              '他試合の更新による再描画を遮断するため、MatchScreenは singleMatchProvider を監視しなければなりません。',
        );

        // 主要セクションに RepaintBoundary が配備されていること
        expect(
          content.contains('final timerPart = RepaintBoundary'),
          isTrue,
          reason: 'タイマー更新時のリビルドを局所化するため、timerPart に RepaintBoundary が必須です。',
        );
        expect(
          content.contains('final scoreboardPart = RepaintBoundary'),
          isTrue,
          reason: 'スコアボードの再描画を局所化するため、scoreboardPart に RepaintBoundary が必須です。',
        );
      },
    );
  });
}
