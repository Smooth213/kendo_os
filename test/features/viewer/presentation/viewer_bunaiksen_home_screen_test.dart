import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

// GoRouterのスタック状態をモックするためのフェイククラス
class FakeGoRouter extends Fake implements GoRouter {
  final bool mockCanPop;
  FakeGoRouter({this.mockCanPop = false});

  @override
  bool canPop() => mockCanPop;

  @override
  void pop<T extends Object?>([T? result]) {}
}

// SharePlatform の呼び出しを検証するためのフェイククラス
class FakeSharePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements SharePlatform {
  String? sharedText;

  @override
  Future<ShareResult> share(ShareParams params) async {
    sharedText = params.text;
    return const ShareResult('success', ShareResultStatus.success);
  }
}

void main() {
  group('🛡️ ViewerBunaiksenHomeScreen 観客席防衛線・QR大開通自動検証テスト', () {
    late MatchModel testMatch;
    final String targetTournamentId = 'bunaiksen_20260620';
    late FakeSharePlatform fakeSharePlatform;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      testMatch = MatchModel(
        id: 'test_match_001',
        tournamentId: targetTournamentId,
        redName: '山田 太郎',
        whiteName: '123',
        redScore: 0,
        whiteScore: 0,
        status: 'in_progress',
        order: 1.0,
        matchType: '部内戦',
        events: [],
      );

      fakeSharePlatform = FakeSharePlatform();
      SharePlatform.instance = fakeSharePlatform;
    });

    // 共通のテスト環境構築ヘルパー
    Widget createTestWidget({
      required GoRouter router,
      required List<Override> overrides,
    }) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ...overrides,
        ],
        child: MaterialApp(
          home: InheritedGoRouter(
            goRouter: router,
            child: ViewerBunaiksenHomeScreen(tournamentId: targetTournamentId),
          ),
        ),
      );
    }

    testWidgets('①-a 【QR直接アクセス時】スタックが無い状態では、物理的に＜ボタンとカレンダーボタンが消滅すること', (
      WidgetTester tester,
    ) async {
      final fakeRouter = FakeGoRouter(mockCanPop: false); // スタックなし（QR直接起動）

      await tester.pumpWidget(
        createTestWidget(
          router: fakeRouter,
          overrides: [
            bunaiksenMatchesProvider(
              targetTournamentId,
            ).overrideWithValue([testMatch]),
            bunaiksenAvailableDatesProvider.overrideWith(
              (ref) => Stream.value({'20260620'}),
            ),
            currentDojoIdProvider.overrideWith((ref) => 'test201'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 🛡️ アサート: QRアクセス時は戻るボタン(arrow_back_ios_new)もカレンダー(calendar_month)も存在しないこと
      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
      expect(find.byIcon(Icons.calendar_month), findsNothing);
    });

    testWidgets('①-b 【アプリ内遷移時】通常の画面遷移スタックがある状態では、＜ボタンとカレンダーボタンが正常表示されること', (
      WidgetTester tester,
    ) async {
      final fakeRouter = FakeGoRouter(mockCanPop: true); // スタックあり

      await tester.pumpWidget(
        createTestWidget(
          router: fakeRouter,
          overrides: [
            bunaiksenMatchesProvider(
              targetTournamentId,
            ).overrideWithValue([testMatch]),
            bunaiksenAvailableDatesProvider.overrideWith(
              (ref) => Stream.value({'20260620'}),
            ),
            currentDojoIdProvider.overrideWith((ref) => 'test201'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 🛡️ アサート: 通常遷移時はボタンが物理的に存在すること
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    });

    testWidgets(
      '② 【QRコードURL検証】共有リンクに正しいベータドメイン(kendo-os-beta.web.app)が含まれていること',
      (WidgetTester tester) async {
        final fakeRouter = FakeGoRouter(mockCanPop: true);

        await tester.pumpWidget(
          createTestWidget(
            router: fakeRouter,
            overrides: [
              bunaiksenMatchesProvider(
                targetTournamentId,
              ).overrideWithValue([testMatch]),
              bunaiksenAvailableDatesProvider.overrideWith(
                (ref) => Stream.value({'20260620'}),
              ),
              currentDojoIdProvider.overrideWith((ref) => 'test201'),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // 共有ボタン（QRコードアイコン）をタップしてダイアログを開く
        final shareButton = find.byIcon(Icons.qr_code_2);
        expect(shareButton, findsOneWidget);
        await tester.tap(shareButton);
        await tester.pumpAndSettle();

        // 🛡️ アサート: ダイアログ内に QrImageView が存在すること
        final qrFinder = find.byType(QrImageView);
        expect(qrFinder, findsOneWidget);

        // 「LINEやSNSでURLを送る」ボタンをタップして共有を実行
        final sendButton = find.text('LINEやSNSでURLを送る');
        expect(sendButton, findsOneWidget);
        await tester.tap(sendButton);
        await tester.pumpAndSettle();

        // 🛡️ アサート: 共有されたテキストに正しいURLドメインおよびdojoIdが含まれていること
        expect(fakeSharePlatform.sharedText, isNotNull);
        expect(
          fakeSharePlatform.sharedText,
          contains('https://kendo-os-beta.web.app/bunaiksen-viewer-home'),
        );
        expect(fakeSharePlatform.sharedText, contains('dojoId=test201'));
      },
    );

    testWidgets('③ 【専用画面の正常描画】QRから遷移したviewer専用画面にデータが反映され、正常表示されること', (
      WidgetTester tester,
    ) async {
      final fakeRouter = FakeGoRouter(mockCanPop: false);

      await tester.pumpWidget(
        createTestWidget(
          router: fakeRouter,
          overrides: [
            bunaiksenMatchesProvider(
              targetTournamentId,
            ).overrideWithValue([testMatch]),
            bunaiksenAvailableDatesProvider.overrideWith(
              (ref) => Stream.value({'20260620'}),
            ),
            currentDojoIdProvider.overrideWith((ref) => 'test201'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 🛡️ アサート: 専用画面の主要要素（タイトル、試合カード、選手名、VS、ステータス）がエラーなく描画されていること
      expect(find.text('2026/06/20 の記録 (観戦)'), findsOneWidget);
      expect(find.text('第1試合'), findsOneWidget);
      expect(find.text('山田 太郎'), findsOneWidget);
      expect(find.text('123'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
      expect(find.text('進行中'), findsOneWidget);
    });
  });
}
