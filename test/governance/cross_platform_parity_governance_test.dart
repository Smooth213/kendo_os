import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/utils/payload_compression_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Governance] 第1条 ガバナンス監査において Web/Native クロスプラットフォーム完全同一動作保証テスト', () {
    test(
      'プラットフォーム安全ガードに関して、dart:io を利用する基盤コードに Web (kIsWeb) 判定・フォールバックが配備されていること',
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
      'データ圧縮・復元同一性に関して、Web/Native いずれの環境でも Gzip 圧縮・伸張データが 100% 可逆復元されること',
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

    test('オフラインストレージ・PWA整合性に関して、Web/Native 間で同期コンテキストのキー体系が統一されていること', () {
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
      'レスポンシブ・UIレイアウト安全規約に関して、デスクトップ(Web)とモバイル(Native)の画面サイズ変化で破綻しないこと',
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

    test('ファイル境界・Webビルド安全規約に関して、lib/配下にWeb非互換な直書きPlatform呼び出しが存在しないこと', () {
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

    test(
      'Web/PWA リロード戻るボタン孤立ゼロ規約に関して、主要画面の AppHeader に fallbackRoute または leading が明示されていること',
      () {
        final protectedScreens = [
          'lib/features/tournament/presentation/operate/screens/home_screen.dart',
          'lib/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart',
          'lib/features/tournament/presentation/operate/screens/tournament_list_screen.dart',
        ];

        for (final path in protectedScreens) {
          final file = File(path);
          expect(file.existsSync(), isTrue, reason: '$path が存在すること');
          final content = file.readAsStringSync();

          if (content.contains('AppHeader(')) {
            final hasFallback =
                content.contains('fallbackRoute:') ||
                content.contains('leading:') ||
                content.contains('onBackPressed:');
            expect(
              hasFallback,
              isTrue,
              reason:
                  '$path の AppHeader に fallbackRoute または leading または onBackPressed が指定されていません。Webリロード時に戻るボタンが消滅するのを防ぐため必須です。',
            );
          }
        }
      },
    );

    test(
      'アプリ表示名整合性に関して、全プラットフォーム（iOS/Android/Web/PWA/main.dart）のアプリ表示名が Kendo Sync で完全統一されていること',
      () {
        // 1. Android: android/app/src/main/AndroidManifest.xml
        final androidManifestFile = File(
          'android/app/src/main/AndroidManifest.xml',
        );
        expect(androidManifestFile.existsSync(), isTrue);
        final androidContent = androidManifestFile.readAsStringSync();
        expect(
          androidContent.contains('android:label="Kendo Sync"'),
          isTrue,
          reason:
              'AndroidManifest.xml の android:label は "Kendo Sync" でなければなりません',
        );

        // 2. iOS: ios/Runner/Info.plist
        final infoPlistFile = File('ios/Runner/Info.plist');
        expect(infoPlistFile.existsSync(), isTrue);
        final iosContent = infoPlistFile.readAsStringSync();
        expect(
          iosContent.contains(
            '<key>CFBundleDisplayName</key>\n\t<string>Kendo Sync</string>',
          ),
          isTrue,
          reason: 'Info.plist の CFBundleDisplayName は "Kendo Sync" でなければなりません',
        );
        expect(
          iosContent.contains(
            '<key>CFBundleName</key>\n\t<string>Kendo Sync</string>',
          ),
          isTrue,
          reason: 'Info.plist の CFBundleName は "Kendo Sync" でなければなりません',
        );

        // 3. Web: web/index.html
        final webIndexFile = File('web/index.html');
        expect(webIndexFile.existsSync(), isTrue);
        final webIndexContent = webIndexFile.readAsStringSync();
        expect(
          webIndexContent.contains('<title>Kendo Sync</title>'),
          isTrue,
          reason: 'web/index.html の <title> は "Kendo Sync" でなければなりません',
        );
        expect(
          webIndexContent.contains(
            '<meta name="apple-mobile-web-app-title" content="Kendo Sync">',
          ),
          isTrue,
          reason:
              'web/index.html の apple-mobile-web-app-title は "Kendo Sync" でなければなりません',
        );

        // 4. PWA: web/manifest.json
        final manifestFile = File('web/manifest.json');
        expect(manifestFile.existsSync(), isTrue);
        final manifestContent = manifestFile.readAsStringSync();
        final manifestJson =
            jsonDecode(manifestContent) as Map<String, dynamic>;
        expect(
          manifestJson['name'],
          'Kendo Sync',
          reason: 'web/manifest.json の name は "Kendo Sync" でなければなりません',
        );
        expect(
          manifestJson['short_name'],
          'Kendo Sync',
          reason: 'web/manifest.json の short_name は "Kendo Sync" でなければなりません',
        );

        // 5. Flutter App: lib/main.dart
        final mainDartFile = File('lib/main.dart');
        expect(mainDartFile.existsSync(), isTrue);
        final mainDartContent = mainDartFile.readAsStringSync();
        expect(
          mainDartContent.contains("title: 'Kendo Sync'"),
          isTrue,
          reason:
              "lib/main.dart の MaterialApp.router に title: 'Kendo Sync' が指定されていなければなりません",
        );
      },
    );
  });
}
