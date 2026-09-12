import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kendo_os/features/band/domain/entities/band_group_model.dart';
import 'package:kendo_os/features/band/presentation/components/band_group_select_sheet.dart';
import 'package:kendo_os/features/band/presentation/providers/band_provider.dart';

void main() {
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

  group('🛡️ 【SFSafariViewController・アプリ内ブラウザ白紙残留 物理ゼロ保証テスト】', () {
    group('📱 1. ネイティブ環境（iOS / Android）保証', () {
      setUp(() {
        BandLauncherHelper.isWebOverride = false;
      });

      test(
        'Native Rule 1: アプリ内ブラウザ（inAppWebView / platformDefault）を厳格に禁止し、必ず LaunchMode.externalApplication が指定されること',
        () async {
          Uri? capturedUri;
          LaunchMode? capturedMode;
          String? capturedWindowName;

          BandLauncherHelper.urlLauncherAdvancedOverride =
              (uri, mode, {webOnlyWindowName}) async {
                capturedUri = uri;
                capturedMode = mode;
                capturedWindowName = webOnlyWindowName;
                return true;
              };

          final testUrls = [
            'https://band.us/@test_dojo',
            'https://band.us/n/a0a60e0aFfx1f',
            'https://band.us/band/12345678',
            'band.us/@custom_dojo',
            'bandapp://band/999',
            '',
          ];

          for (final url in testUrls) {
            final result = await BandLauncherHelper.launchBandUrl(url);
            expect(result, isTrue);
            expect(capturedUri, isNotNull);
            expect(
              capturedMode,
              LaunchMode.externalApplication,
              reason:
                  'Native環境で $url を開く際、SFSafariViewControllerやChrome Custom Tabsの残留を防ぐため、LaunchMode.externalApplication 以外は許可されません。',
            );
            expect(
              capturedWindowName,
              isNull,
              reason: 'Native環境では webOnlyWindowName は null でなければなりません。',
            );
          }
        },
      );

      test(
        'Native Rule 2: バンドID形式（https://band.us/band/12345）は直接ネイティブスキーム bandapp://band/12345 へ自動変換されること',
        () async {
          Uri? capturedUri;

          BandLauncherHelper.urlLauncherOverride = (uri) async {
            capturedUri = uri;
            return true;
          };

          await BandLauncherHelper.launchBandUrl('https://band.us/band/554433');
          expect(capturedUri, Uri.parse('bandapp://band/554433'));
        },
      );

      test(
        'Native Rule 3: 空URLまたはband.usトップはデフォルトで bandapp:// へ自動変換されること',
        () async {
          Uri? capturedUri;

          BandLauncherHelper.urlLauncherOverride = (uri) async {
            capturedUri = uri;
            return true;
          };

          await BandLauncherHelper.launchBandUrl('');
          expect(capturedUri, Uri.parse('bandapp://'));

          await BandLauncherHelper.launchBandUrl('https://band.us');
          expect(capturedUri, Uri.parse('bandapp://'));
        },
      );
    });

    group('🌐 2. Web環境（iOS PWA / Safari / Chrome）保証', () {
      setUp(() {
        BandLauncherHelper.isWebOverride = true;
      });

      test(
        'Web Rule 1: トップURLやバンドID形式は安全に bandapp:// スキームへ変換され、招待URL等はUniversal Linkとして保持されること',
        () {
          expect(BandLauncherHelper.convertToBandAppScheme(''), 'bandapp://');
          expect(
            BandLauncherHelper.convertToBandAppScheme('https://band.us'),
            'bandapp://',
          );
          expect(
            BandLauncherHelper.convertToBandAppScheme(
              'https://band.us/band/12345',
            ),
            'bandapp://band/12345',
          );
          expect(
            BandLauncherHelper.convertToBandAppScheme(
              'https://band.us/n/inv123',
            ),
            'https://band.us/n/inv123',
            reason:
                '招待URLはBANDアプリのUniversal Linkとしてそのまま維持され、未対応エラー（現在ご利用いただけません）を防ぎます',
          );
        },
      );

      test(
        'Web Rule 2: Web環境では window.open をバイパスし、同一ウィンドウ直接キック（launchWebDirect）が最優先実行されること',
        () async {
          String? capturedDirectUrl;
          bool urlLauncherWasCalled = false;

          BandLauncherHelper.webDirectLauncherOverride = (url) {
            capturedDirectUrl = url;
            return true;
          };

          BandLauncherHelper.urlLauncherAdvancedOverride =
              (uri, mode, {webOnlyWindowName}) async {
                urlLauncherWasCalled = true;
                return true;
              };

          final result = await BandLauncherHelper.launchBandUrl(
            'https://band.us/n/a0a60e0aFfx1f',
          );

          expect(result, isTrue);
          // Universal Link として該当グループ画面へ直接遷移するためグループURLが渡されること
          expect(capturedDirectUrl, 'https://band.us/n/a0a60e0aFfx1f');
          expect(
            urlLauncherWasCalled,
            isFalse,
            reason:
                'url_launcher の window.open は noopener,noreferrer により空のSFSafariViewControllerを生成するため、Web直接ランチャーが最優先実行され urlLauncher は呼ばれてはなりません。',
          );
        },
      );

      test(
        'Web Rule 3: Webフォールバック時でも webOnlyWindowName: _self かつ LaunchMode.externalApplication が厳格に渡されること',
        () async {
          Uri? capturedUri;
          LaunchMode? capturedMode;
          String? capturedWindowName;

          // webDirectLauncher が false を返した場合（フォールバック時）
          BandLauncherHelper.webDirectLauncherOverride = (url) => false;

          BandLauncherHelper.urlLauncherAdvancedOverride =
              (uri, mode, {webOnlyWindowName}) async {
                capturedUri = uri;
                capturedMode = mode;
                capturedWindowName = webOnlyWindowName;
                return true;
              };

          final result = await BandLauncherHelper.launchBandUrl(
            'bandapp://band/12345',
          );

          expect(result, isTrue);
          expect(capturedUri, Uri.parse('bandapp://band/12345'));
          expect(capturedMode, LaunchMode.externalApplication);
          expect(
            capturedWindowName,
            '_self',
            reason:
                'Web環境で新しいコンテキストを作らないよう、必ず webOnlyWindowName: _self が渡されなければなりません。',
          );
        },
      );
    });

    group('📱✨ 3. UI（BandGroupSelectSheet）連携における白紙画面防止保証', () {
      final sampleGroups = [
        BandGroupModel(
          id: 'g_inv',
          name: '少年部（招待URL）',
          url: 'https://band.us/n/inv12345',
          order: 1,
          createdAt: DateTime(2026, 9, 1),
        ),
      ];

      testWidgets(
        'UI Rule 1: Web環境でグループをタップした際、LIVE配信可能なグループ画面へ直行するためグループURLがキックされシートが正しく閉じること',
        (tester) async {
          BandLauncherHelper.isWebOverride = true;
          String? launchedUrl;
          BandLauncherHelper.webDirectLauncherOverride = (url) {
            launchedUrl = url;
            return true;
          };

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                bandGroupsStreamProvider.overrideWith(
                  (ref) => Stream.value(sampleGroups),
                ),
              ],
              child: const MaterialApp(
                home: Scaffold(
                  body: BandGroupSelectSheet(formattedText: '試合速報テキスト'),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // 少年部（招待URL）をタップ
          final tile = find.text('少年部（招待URL）');
          expect(tile, findsOneWidget);
          await tester.tap(tile);
          await tester.pumpAndSettle();

          // LIVE配信・投稿が自由にできるグループトップ画面へ直行するため、登録グループURLが直接キックされること
          expect(launchedUrl, 'https://band.us/n/inv12345');
        },
      );

      testWidgets(
        'UI Rule 2: ヘッダーの「BANDアプリを開く」ボタンをタップした際、直接 bandapp:// が安全に起動されること',
        (tester) async {
          BandLauncherHelper.isWebOverride = true;
          String? launchedUrl;
          BandLauncherHelper.webDirectLauncherOverride = (url) {
            launchedUrl = url;
            return true;
          };

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                bandGroupsStreamProvider.overrideWith(
                  (ref) => Stream.value(sampleGroups),
                ),
              ],
              child: const MaterialApp(
                home: Scaffold(
                  body: BandGroupSelectSheet(formattedText: '試合速報テキスト'),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final openAppBtn = find.text('BANDアプリを開く');
          expect(openAppBtn, findsOneWidget);
          await tester.tap(openAppBtn);
          await tester.pumpAndSettle();

          expect(launchedUrl, 'bandapp://');
        },
      );

      testWidgets('UI Rule 3: 招待URL形式のグループをタップした際、その招待URLが直接キックされること', (
        tester,
      ) async {
        BandLauncherHelper.isWebOverride = true;
        String? launchedUrl;
        BandLauncherHelper.webDirectLauncherOverride = (url) {
          launchedUrl = url;
          return true;
        };

        final testGroup = BandGroupModel(
          id: 'g_low',
          name: '低学年チーム',
          url: 'https://band.us/n/low_invite_123',
          order: 1,
          createdAt: DateTime(2026, 9, 1),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bandGroupsStreamProvider.overrideWith(
                (ref) => Stream.value([testGroup]),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: BandGroupSelectSheet(formattedText: '第1試合速報'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('低学年チーム'));
        await tester.pumpAndSettle();
        expect(launchedUrl, 'https://band.us/n/low_invite_123');
      });

      testWidgets(
        'UI Rule 4: バンドID形式（https://band.us/band/...）のグループをタップした際、ネイティブスキームに変換されてキックされること',
        (tester) async {
          BandLauncherHelper.isWebOverride = true;
          String? launchedUrl;
          BandLauncherHelper.webDirectLauncherOverride = (url) {
            launchedUrl = url;
            return true;
          };

          final testGroup = BandGroupModel(
            id: 'g_mid',
            name: '中学生チーム',
            url: 'https://band.us/band/998877',
            order: 1,
            createdAt: DateTime(2026, 9, 1),
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                bandGroupsStreamProvider.overrideWith(
                  (ref) => Stream.value([testGroup]),
                ),
              ],
              child: const MaterialApp(
                home: Scaffold(
                  body: BandGroupSelectSheet(formattedText: '第2試合速報'),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('中学生チーム'));
          await tester.pumpAndSettle();
          expect(launchedUrl, 'bandapp://band/998877');
        },
      );

      testWidgets('UI Rule 5: グループ選択シート内にBANDアプリのインストールが必要な旨の案内バナーが表示されていること', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bandGroupsStreamProvider.overrideWith(
                (ref) => Stream.value(sampleGroups),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: BandGroupSelectSheet(formattedText: '速報テキスト'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('端末に「BANDアプリ」のインストールが必要です'), findsOneWidget);
        expect(find.text('コピーのみで閉じる'), findsOneWidget);
      });

      testWidgets(
        'UI Rule 6: LIVE配信ができない投稿共有API（bandapp://create/post）が呼ばれず、必ずグループURLがキックされること',
        (tester) async {
          BandLauncherHelper.isWebOverride = true;
          String? launchedUrl;
          BandLauncherHelper.webDirectLauncherOverride = (url) {
            launchedUrl = url;
            return true;
          };

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                bandGroupsStreamProvider.overrideWith(
                  (ref) => Stream.value(sampleGroups),
                ),
              ],
              child: const MaterialApp(
                home: Scaffold(
                  body: BandGroupSelectSheet(
                    formattedText:
                        '【試合中】[先鋒] 勇武館 vs 翔武会\nhttps://kendo-os-beta.web.app',
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('少年部（招待URL）'));
          await tester.pumpAndSettle();

          // bandapp://create/post ではなく、LIVE配信・投稿が可能なグループURLであること
          expect(launchedUrl, isNot(startsWith('bandapp://create/post')));
          expect(launchedUrl, 'https://band.us/n/inv12345');
        },
      );
    });
  });
}
