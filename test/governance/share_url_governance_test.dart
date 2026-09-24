import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/band/presentation/services/band_match_text_formatter.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/p2p/infrastructure/local_p2p_broadcaster.dart';
import 'package:kendo_os/features/p2p/presentation/components/p2p_broadcast_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/share_provider.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_share_dialog.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/routing/app_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

class _FakeSharePlatform extends SharePlatform {
  static final _FakeSharePlatform instance = _FakeSharePlatform();
  String? sharedText;

  @override
  Future<ShareResult> share(ShareParams params) async {
    sharedText = params.text;
    return const ShareResult('success', ShareResultStatus.success);
  }

  void reset() {
    sharedText = null;
  }
}

class _FakeLocalP2pBroadcaster extends LocalP2pBroadcaster {
  @override
  Future<String?> startServer({int port = 8080}) async {
    return null;
  }

  @override
  Future<void> stopServer() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharePlatform.instance = _FakeSharePlatform.instance;
    _FakeSharePlatform.instance.reset();
  });

  group('🥋 【ガバナンス 20/20】🔗 観客用共有URL・ルーティング・パラメータ整合性規約', () {
    test('Rule 1: 公式Webビュアーホスト(kendo-os-beta.web.app)完全準拠規約', () {
      final sampleMatch = MatchModel(
        id: 'gov_m1',
        matchType: '個人戦',
        tournamentId: 'gov_t1',
        redName: '赤',
        whiteName: '白',
      );

      final bandText = BandMatchTextFormatter.formatFromMatchGroup(
        matches: [sampleMatch],
        dojoId: 'gov_dojo',
      );

      final url = RegExp(r'https://[^\s]+').firstMatch(bandText)!.group(0)!;
      final uri = Uri.parse(url);

      expect(uri.scheme, 'https');
      expect(uri.host, 'kendo-os-beta.web.app');
    });

    test('Rule 2: AppRouter 正規ルート実在保証規約', () {
      final definedRoutes = appRouter.configuration.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toList();

      final requiredPrefixes = [
        '/viewer/:id',
        '/viewer-team/:groupName',
        '/viewer-kachinuki/:groupName',
        '/viewer-home/:tournamentId',
        '/bunaiksen-viewer-home/:tournamentId',
      ];

      for (final prefix in requiredPrefixes) {
        expect(
          definedRoutes.contains(prefix),
          isTrue,
          reason: 'AppRouter にルート $prefix が定義されていません。',
        );
      }
    });

    test('Rule 3: 必須クエリパラメータ (role=viewer, dojoId, tournamentId) 完全保持規約', () {
      final match = MatchModel(
        id: 'gov_m_team',
        matchType: '団体戦 (先鋒)',
        groupName: '第1試合場 1回戦',
        tournamentId: 'gov_tourney_123',
        redName: '選手A',
        whiteName: '選手B',
      );

      final text = BandMatchTextFormatter.formatFromMatchGroup(
        matches: [match],
        dojoId: 'gov_dojo_test',
      );

      final uri = Uri.parse(
        RegExp(r'https://[^\s]+').firstMatch(text)!.group(0)!,
      );
      expect(uri.queryParameters['role'], 'viewer');
      expect(uri.queryParameters['dojoId'], 'gov_dojo_test');
      expect(uri.queryParameters['tournamentId'], 'gov_tourney_123');
    });

    test('Rule 4: 団体戦・個人戦・勝ち抜き戦 ルーティング厳格分離規約', () {
      final dantaiMatch = MatchModel(
        id: 'm_dantai',
        matchType: '団体戦 (中堅)',
        groupName: '第2試合場 3回戦 1試合目',
        tournamentId: 't1',
        redName: '赤',
        whiteName: '白',
      );
      final dantaiUri = Uri.parse(
        RegExp(r'https://[^\s]+')
            .firstMatch(
              BandMatchTextFormatter.formatFromMatchGroup(
                matches: [dantaiMatch],
                dojoId: 'd1',
              ),
            )!
            .group(0)!,
      );
      expect(
        dantaiUri.path,
        '/viewer-team/${Uri.encodeComponent('第2試合場 3回戦 1試合目')}',
      );

      final kachinukiMatch = MatchModel(
        id: 'm_kachi',
        matchType: '勝ち抜き戦 (1戦目)',
        groupName: '第1試合場 勝ち抜きA',
        tournamentId: 't1',
        isKachinuki: true,
        redName: '赤',
        whiteName: '白',
      );
      final kachinukiUri = Uri.parse(
        RegExp(r'https://[^\s]+')
            .firstMatch(
              BandMatchTextFormatter.formatFromMatchGroup(
                matches: [kachinukiMatch],
                dojoId: 'd1',
              ),
            )!
            .group(0)!,
      );
      expect(
        kachinukiUri.path,
        '/viewer-kachinuki/${Uri.encodeComponent('第1試合場 勝ち抜きA')}',
      );

      final kojinMatch = MatchModel(
        id: 'm_kojin_99',
        matchType: '個人戦',
        tournamentId: 't1',
        redName: '赤',
        whiteName: '白',
      );
      final kojinUri = Uri.parse(
        RegExp(r'https://[^\s]+')
            .firstMatch(
              BandMatchTextFormatter.formatFromMatchGroup(
                matches: [kojinMatch],
                dojoId: 'd1',
              ),
            )!
            .group(0)!,
      );
      expect(kojinUri.path, '/viewer/m_kojin_99');
    });

    testWidgets('Rule 5: 部内戦専用ビュアーホーム (bunaiksen-viewer-home) 完全自動分岐規約', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ViewerShareDialog(
              tournamentId: 'bunaiksen_2026_fall',
              dojoId: 'dojo_bunaiksen',
            ),
          ),
        ),
      );

      final sendButton = find.text('LINEやSNSでURLを送る');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      final shared = _FakeSharePlatform.instance.sharedText!;
      final uri = Uri.parse(
        RegExp(r'https://[^\s]+').firstMatch(shared)!.group(0)!,
      );

      expect(uri.path, '/bunaiksen-viewer-home/bunaiksen_2026_fall');
      expect(uri.queryParameters['role'], 'viewer');
      expect(uri.queryParameters['dojoId'], 'dojo_bunaiksen');
    });

    test('Rule 6: 野良URL・パラメータ欠落URL排除 lib/ コードスキャン規約', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        if (content.contains('https://kendo-os-beta.web.app')) {
          final isLegit =
              file.path.contains('band_match_text_formatter.dart') ||
              file.path.contains('share_provider.dart') ||
              file.path.contains('viewer_share_dialog.dart') ||
              file.path.contains('viewer_bunaiksen_share_dialog.dart') ||
              file.path.contains('bunaiksen_share_dialog.dart') ||
              file.path.contains('viewer_qr_bottom_sheet.dart') ||
              file.path.contains('viewer_match_screen.dart') ||
              file.path.contains('p2p_broadcast_dialog.dart') ||
              file.path.contains('web_app_qr_dialog.dart') ||
              file.path.contains('settings_screen.dart') ||
              file.path.contains('home_screen.dart');

          expect(
            isLegit,
            isTrue,
            reason:
                '管理外のファイル ${file.path} にビュアーURLの直書きが検出されました。共通フォーマッターを使用してください。',
          );
        }
      }
    });

    test('Rule 7-1: ShareService 団体戦・個人戦 URL生成保証', () async {
      final container = ProviderContainer(
        overrides: [currentDojoIdProvider.overrideWith((ref) => 'dojo_gov')],
      );
      addTearDown(container.dispose);

      final shareService = container.read(shareProvider);
      final teamMatch = MatchModel(
        id: 'team_01',
        matchType: '団体戦 (先鋒)',
        groupName: '第1試合場 準決勝',
        tournamentId: 't_gov_01',
        redName: '赤',
        whiteName: '白',
      );
      await shareService.shareMatch(teamMatch);

      final serviceUri = Uri.parse(
        RegExp(
          r'https://[^\s]+',
        ).firstMatch(_FakeSharePlatform.instance.sharedText!)!.group(0)!,
      );
      expect(
        serviceUri.path,
        '/viewer-team/${Uri.encodeComponent('第1試合場 準決勝')}',
      );
      expect(serviceUri.queryParameters['role'], 'viewer');
      expect(serviceUri.queryParameters['dojoId'], 'dojo_gov');
      expect(serviceUri.queryParameters['tournamentId'], 't_gov_01');
    });

    testWidgets('Rule 7-2: P2pBroadcastDialog クラウドフォールバックURL生成保証', (
      tester,
    ) async {
      final teamMatch = MatchModel(
        id: 'team_01',
        matchType: '団体戦 (先鋒)',
        groupName: '第1試合場 準決勝',
        tournamentId: 't_gov_01',
        redName: '赤',
        whiteName: '白',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => 'dojo_p2p_gov'),
            localP2pBroadcasterProvider.overrideWithValue(
              _FakeLocalP2pBroadcaster(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: P2pBroadcastDialog(match: teamMatch)),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
      final textFinder = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.data != null &&
            w.data!.startsWith('https://kendo-os-beta.web.app'),
      );
      expect(textFinder, findsOneWidget);
      final p2pUri = Uri.parse((tester.widget(textFinder) as Text).data!);
      expect(p2pUri.path, '/viewer-team/${Uri.encodeComponent('第1試合場 準決勝')}');
      expect(p2pUri.queryParameters['role'], 'viewer');
      expect(p2pUri.queryParameters['dojoId'], 'dojo_p2p_gov');
    });
  });
}
