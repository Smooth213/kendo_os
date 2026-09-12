import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kendo_os/features/band/presentation/providers/band_provider.dart';

// ============================================================================
// 🥋 【ガバナンス 21/21】🛡️ BAND LIVE配信連携・外部直行遷移 ＆ 白紙ブラウザ残留ゼロ規約
//
// 本ガバナンス規約は、Kendo OSからBANDへの外部連携において：
// 1. iOS PWA等における白紙Safari（SFSafariViewController）の居残り
// 2. BAND未対応スキーム（bandapp://n/... 等）による「現在ご利用いただけません」エラー
// 3. LIVE配信ができないテキスト専用投稿API（bandapp://create/post）への誤退行
// をプロジェクト全体で永久に遮断・検知し、安全なLIVE配信連携を保証します。
// ============================================================================
void main() {
  group('🥋 【ガバナンス 21/21】🛡️ BAND LIVE配信連携・外部直行遷移 ＆ 白紙ブラウザ残留ゼロ規約', () {
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

    setUp(() {
      BandLauncherHelper.urlLauncherOverride = null;
      BandLauncherHelper.urlLauncherWithModeOverride = null;
      BandLauncherHelper.urlLauncherAdvancedOverride = null;
      BandLauncherHelper.isWebOverride = null;
      BandLauncherHelper.webDirectLauncherOverride = null;
    });

    tearDown(() {
      BandLauncherHelper.urlLauncherOverride = null;
      BandLauncherHelper.urlLauncherWithModeOverride = null;
      BandLauncherHelper.urlLauncherAdvancedOverride = null;
      BandLauncherHelper.isWebOverride = null;
      BandLauncherHelper.webDirectLauncherOverride = null;
    });

    // ------------------------------------------------------------------------
    // 【静的コードスキャン規約】プロジェクト全域のコード健全性検査
    // ------------------------------------------------------------------------

    test('Rule 1: [静的スキャン] BAND起動・URL変換の責務集約規約（野良起動の完全排除）', () {
      final violations = <String>[];

      for (final file in dartFiles) {
        // BAND機能モジュール内部およびサービス定義は除外
        if (file.path.contains('lib/features/band/')) {
          continue;
        }

        final content = file.readAsStringSync();
        // features/band 外で直接 bandapp:// を生成したり、直接 launchUrl している箇所を検出
        if (content.contains('bandapp://') ||
            (content.contains('band.us') && content.contains('launchUrl('))) {
          violations.add(file.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'BAND起動・URL変換が lib/features/band/ 外で直接記述されています。必ず BandLauncherHelper を経由してください。\n'
            '違反ファイル:\n${violations.join('\n')}',
      );
    });

    test(
      'Rule 2: [静的スキャン] BAND未対応スキーム（bandapp://n/, bandapp://@）生成の完全排除規約',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          final content = file.readAsStringSync();
          // BANDアプリで「現在ご利用いただけません」エラーとなる未対応スキームの生成・置換を検知
          if (content.contains('bandapp://n/') ||
              content.contains('bandapp://@') ||
              content.contains("'bandapp://n/'") ||
              content.contains('"bandapp://n/"')) {
            violations.add(file.path);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'BANDアプリで「現在ご利用いただけません」エラーを誘発する未対応スキーム（bandapp://n/ 等）が検出されました。\n'
              '招待URLは Universal Link（https://band.us/n/...）として維持しなければなりません。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      'Rule 3: [静的スキャン] LIVE配信不可共有API（bandapp://create/post）への強制リダイレクト排除規約',
      () {
        final bandProviderFile = File(
          'lib/features/band/presentation/providers/band_provider.dart',
        );
        expect(bandProviderFile.existsSync(), isTrue);

        final content = bandProviderFile.readAsStringSync();

        // launchBandUrl 内で buildBandPostCreateUrl が呼ばれて LIVE配信画面が奪われていないことを保証
        final launchBandUrlBody = RegExp(
          r'Future<bool>\s+launchBandUrl\s*\([\s\S]*?\}\s*\}',
        ).firstMatch(content);

        expect(
          launchBandUrlBody,
          isNotNull,
          reason: 'launchBandUrl のメソッド本体が見つかりません。',
        );

        final methodBody = launchBandUrlBody!.group(0)!;
        expect(
          methodBody.contains('buildBandPostCreateUrl'),
          isFalse,
          reason:
              'launchBandUrl 内で buildBandPostCreateUrl が呼び出されています。'
              '公式共有API（bandapp://create/post）はテキスト投稿専用でありLIVE配信ができません。'
              'LIVE配信が可能なグループ通常画面へ直行するよう Universal Link を維持してください。',
        );
      },
    );

    // ------------------------------------------------------------------------
    // 【動的規約】実行時におけるブラウザ残留防止＆URL正規化整合性規約
    // ------------------------------------------------------------------------

    test(
      'Rule 4: [動的規約] ネイティブ環境アプリ内ブラウザ（SFSafariViewController）完全排除規約',
      () async {
        BandLauncherHelper.isWebOverride = false;

        Uri? capturedUri;
        LaunchMode? capturedMode;

        BandLauncherHelper.urlLauncherAdvancedOverride =
            (uri, mode, {webOnlyWindowName}) async {
              capturedUri = uri;
              capturedMode = mode;
              return true;
            };

        final testCases = [
          'https://band.us/n/invite_test_123',
          'https://band.us/@dojo_sample',
          'https://band.us/band/88776655',
          '',
        ];

        for (final url in testCases) {
          await BandLauncherHelper.launchBandUrl(url);
          expect(capturedUri, isNotNull);
          expect(
            capturedMode,
            LaunchMode.externalApplication,
            reason:
                'ネイティブ環境で $url を起動する際、SFSafariViewController / Chrome Custom Tabs の残留を防ぐため、'
                'LaunchMode.externalApplication が厳格に適用されなければなりません。',
          );
        }
      },
    );

    test('Rule 5: [動的規約] Web環境（iOS PWA）同一コンテキスト直接キック最優先規約', () async {
      BandLauncherHelper.isWebOverride = true;

      String? directKickUrl;
      bool windowOpenWasCalled = false;

      BandLauncherHelper.webDirectLauncherOverride = (url) {
        directKickUrl = url;
        return true;
      };

      BandLauncherHelper.urlLauncherAdvancedOverride =
          (uri, mode, {webOnlyWindowName}) async {
            windowOpenWasCalled = true;
            return true;
          };

      // 招待URL（Universal Link）を開く
      final result = await BandLauncherHelper.launchBandUrl(
        'https://band.us/n/pwa_direct_test',
      );

      expect(result, isTrue);
      expect(directKickUrl, 'https://band.us/n/pwa_direct_test');
      expect(
        windowOpenWasCalled,
        isFalse,
        reason:
            'iOS PWA では url_launcher の window.open による白紙Safari立ち塞がりを防ぐため、'
            'Web直接キック（launchWebDirect）が最優先実行され、url_launcher がバイパスされなければなりません。',
      );
    });

    test('Rule 6: [動的規約] BAND URL正規化＆LIVE配信画面ルート整合性規約', () {
      // 1. 空URLまたはトップURL ➔ 安全に bandapp://
      expect(BandLauncherHelper.convertToBandAppScheme(''), 'bandapp://');
      expect(
        BandLauncherHelper.convertToBandAppScheme('https://band.us'),
        'bandapp://',
      );
      expect(
        BandLauncherHelper.convertToBandAppScheme('https://band.us/'),
        'bandapp://',
      );

      // 2. バンドID形式 ➔ 直接ネイティブスキーム bandapp://band/{id}
      expect(
        BandLauncherHelper.convertToBandAppScheme(
          'https://band.us/band/98765432',
        ),
        'bandapp://band/98765432',
      );

      // 3. 招待URL・公開Band ➔ BAND公式 Universal Link としてそのまま維持（LIVE配信画面へ直行）
      expect(
        BandLauncherHelper.convertToBandAppScheme(
          'https://band.us/n/live_invite_999',
        ),
        'https://band.us/n/live_invite_999',
      );
      expect(
        BandLauncherHelper.convertToBandAppScheme(
          'https://band.us/@dojo_official',
        ),
        'https://band.us/@dojo_official',
      );
    });
  });
}
