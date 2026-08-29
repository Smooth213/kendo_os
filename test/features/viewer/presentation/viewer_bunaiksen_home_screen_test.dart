import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

// GoRouterのスタック状態および遷移先パスを精密に追跡する拡張フェイククラス
class FakeGoRouter extends Fake implements GoRouter {
  final bool mockCanPop;
  String? lastPushedPath; // 進入した遷移先URLをガッチリ捕捉する記録スタック

  FakeGoRouter({this.mockCanPop = false});

  @override
  bool canPop() => mockCanPop;

  @override
  void pop<T extends Object?>([T? result]) {}

  @override
  Future<T?> push<T extends Object?>(String location, {Object? extra}) {
    lastPushedPath = location; // 画面から発行されたパスを物理フック
    return Future.value(null);
  }

  @override
  Future<T?> pushReplacement<T extends Object?>(
    String location, {
    Object? extra,
  }) {
    return Future.value(null);
  }
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
        order: 1,
        matchType: '部内戦',
        events: [],
      );

      fakeSharePlatform = FakeSharePlatform();
      SharePlatform.instance = fakeSharePlatform;
    });

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

      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
      expect(find.byIcon(Icons.calendar_month), findsNothing);
    });

    testWidgets('①-b 【アプリ内遷移時】通常の画面遷移スタックがある状態では、＜ボタンとカレンダーボタンが正常表示されること', (
      WidgetTester tester,
    ) async {
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

        // Moreメニューを開いて「観戦リンクを共有する」をタップ
        final moreButton = find.byIcon(Icons.more_horiz_rounded);
        expect(moreButton, findsOneWidget);
        await tester.tap(moreButton);
        await tester.pumpAndSettle();

        final shareButton = find.text('観戦リンクを共有する');
        expect(shareButton, findsOneWidget);
        await tester.tap(shareButton);
        await tester.pumpAndSettle();

        final qrFinder = find.byType(QrImageView);
        expect(qrFinder, findsOneWidget);

        final sendButton = find.text('LINEやSNSでURLを送る');
        expect(sendButton, findsOneWidget);
        await tester.tap(sendButton);
        await tester.pumpAndSettle();

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

      expect(find.text('2026/06/20 の記録 (観戦)'), findsOneWidget);
      expect(find.text('第1試合'), findsOneWidget);
      expect(find.text('山田 太郎'), findsOneWidget);
      expect(find.text('123'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
      expect(find.text('進行中'), findsOneWidget);
    });

    testWidgets(
      '④ 【UI形状同期検証】試合カードの margin が EdgeInsets.zero であり、操作員画面とサイズが完全一致していること',
      (WidgetTester tester) async {
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

        // 🛡️ アサート: Cardを見つけ出し、余白の重複が排除され margin が零(zero)であることを徹底検証
        final cardFinder = find.byType(Card);
        expect(cardFinder, findsOneWidget);
        final cardWidget = tester.widget<Card>(cardFinder);
        expect(cardWidget.margin, EdgeInsets.zero);
      },
    );

    testWidgets(
      '⑤ 【閲覧スコープ防衛検証】試合カードをタップした際、スコア入力画面(/match)ではなく閲覧専用詳細画面(/viewer)へ遷移すること',
      (WidgetTester tester) async {
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

        // テスト用Keyで試合カード（InkWell）をピンポイント捕捉
        final cardInkWellFinder = find.byKey(
          Key('viewer_match_card_test_match_001'),
        );
        expect(cardInkWellFinder, findsOneWidget);

        // タップを執行
        await tester.tap(cardInkWellFinder);
        await tester.pumpAndSettle();

        // 🛡️ アサート: 操作員用パス '/match/' が完全に拒絶され、一般観客用の安全な一本速報パス '/viewer/' へ向かっていることを検証
        expect(fakeRouter.lastPushedPath, isNotNull);
        expect(fakeRouter.lastPushedPath, startsWith('/viewer/'));
        expect(fakeRouter.lastPushedPath, contains('role=viewer'));
        expect(fakeRouter.lastPushedPath, contains('dojoId=test201'));
        expect(
          fakeRouter.lastPushedPath,
          isNot(contains('/match/')),
        ); // 操作員画面への進入漏洩が0%であることを確定
      },
    );
  });
}
