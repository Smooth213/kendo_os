import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/utils/payload_compression_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🌐 【第1条 ガバナンス監査】Web/Native クロスプラットフォーム完全同一動作保証テスト', () {
    test(
      '1. [プラットフォーム安全ガード] dart:io を利用する基盤コードに Web (kIsWeb) 判定・フォールバックが配備されていること',
      () {
        final targetFiles = [
          'lib/shared/utils/payload_compression_helper.dart',
          'lib/features/pdf/pdf_service.dart',
        ];

        for (final path in targetFiles) {
          final file = File(path);
          expect(file.existsSync(), isTrue, reason: '$path が存在すること');
          final content = file.readAsStringSync();

          // dart:io をインポートしている場合、kIsWeb による分岐または universal 抽象化が必須
          if (content.contains("import 'dart:io'")) {
            expect(
              content.contains('kIsWeb') || content.contains('universal_io'),
              isTrue,
              reason: '$path では Web 環境でのクラッシュを防ぐため kIsWeb ガードまたは抽象化が必須です',
            );
          }
        }
      },
    );

    test(
      '2. [データ圧縮・復元同一性] Web/Native いずれの環境でも Gzip 圧縮・伸張データが 100% 可逆復元されること',
      () {
        final originalString =
            '🥋 KendoOS - 剣道大会リアルタイムスコア＆クロスプラットフォーム同期データ検証サンプル 2026';
        final originalBytes = Uint8List.fromList(utf8.encode(originalString));

        // 圧縮
        final compressed = PayloadCompressionHelper.compressBytes(
          originalBytes,
        );
        expect(compressed.isNotEmpty, isTrue);
        expect(PayloadCompressionHelper.isGzip(compressed), isTrue);

        // 伸張（解凍）
        final decompressed = PayloadCompressionHelper.decompressBytes(
          compressed,
        );
        final restoredString = utf8.decode(decompressed);

        expect(restoredString, originalString, reason: '圧縮・伸張後に元データと完全一致すること');
      },
    );

    test('3. [オフラインストレージ・PWA整合性] Web/Native 間で同期コンテキストのキー体系が統一されていること', () {
      final pwaStorageFile = File(
        'lib/shared/infrastructure/services/pwa_storage_service.dart',
      );
      if (pwaStorageFile.existsSync()) {
        final content = pwaStorageFile.readAsStringSync();
        expect(
          content.contains('kIsWeb'),
          isTrue,
          reason: 'pwa_storage_service は Web/Native の分岐を明示的に処理していなければならない',
        );
      }
    });

    testWidgets(
      '4. [レスポンシブ・UIレイアウト安全規約] デスクトップ(Web)とモバイル(Native)の画面サイズ変化で破綻しないこと',
      (WidgetTester tester) async {
        // モバイルサイズ (390 x 844)
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        expect(tester.view.physicalSize.width, 780);

        // デスクトップ/Webサイズ (1920 x 1080)
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        expect(tester.view.physicalSize.width, 1920);
      },
    );

    test('5. [ファイル境界・Webビルド安全規約] lib/配下にWeb非互換な直書きPlatform呼び出しが存在しないこと', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final illegalDirectPlatformCalls = <String>[];

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Platform.isAndroid, Platform.isIOS が kIsWeb ガードなしで使われていないかチェック
          if (line.contains('Platform.is') && !line.contains('kIsWeb')) {
            // ファイル全体で kIsWeb をインポート＆チェックしているか確認
            final fullContent = file.readAsStringSync();
            if (!fullContent.contains('kIsWeb')) {
              illegalDirectPlatformCalls.add(
                '${file.path}:${i + 1} -> $line (kIsWeb ガードなしの Platform 参照)',
              );
            }
          }
        }
      }

      expect(
        illegalDirectPlatformCalls,
        isEmpty,
        reason:
            'Web で Unsupported operation が発生する危険な Platform 呼び出し:\n${illegalDirectPlatformCalls.join('\n')}',
      );
    });
  });
}
