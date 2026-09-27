import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/band/domain/entities/band_group_model.dart';
import 'package:kendo_os/features/band/presentation/components/band_group_select_sheet.dart';
import 'package:kendo_os/features/band/presentation/providers/band_provider.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/p2p/infrastructure/local_p2p_broadcaster.dart';
import 'package:kendo_os/features/p2p/presentation/components/p2p_broadcast_dialog.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:qr_flutter/qr_flutter.dart';

class FakeLocalP2pBroadcaster extends LocalP2pBroadcaster {
  final String? mockUrl;
  final int mockClients;

  FakeLocalP2pBroadcaster({
    this.mockUrl = 'http://192.168.1.100:8080',
    this.mockClients = 3,
  });

  @override
  Future<String?> startServer({int port = 8080}) async {
    return mockUrl;
  }

  @override
  int get clientCount => mockClients;

  @override
  void broadcastMatch(MatchModel match, {int? remainingSeconds}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyMatch = const MatchModel(
    id: 'm_golden_p2p_1',
    tournamentId: 't_golden_1',
    matchType: '個人戦',
    redName: '選手赤',
    whiteName: '選手白',
    redScore: 1,
    whiteScore: 0,
    status: 'in_progress',
  );

  final dummyBandGroups = [
    const BandGroupModel(
      id: 'bg_1',
      name: '誠道館 父母会LIVE',
      url: 'https://band.us/band/12345678',
    ),
    const BandGroupModel(
      id: 'bg_2',
      name: '中体連 剣道部LIVE配信',
      url: 'https://band.us/band/87654321',
    ),
  ];

  Widget buildWrapper({
    required Widget child,
    required bool isDark,
    double textScale = 1.0,
    List<Override> overrides = const [],
  }) {
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    return ProviderScope(
      overrides: [
        currentDojoIdProvider.overrideWith((ref) => 'test_dojo_p2p'),
        currentTournamentIdProvider.overrideWith((ref) => 'test_tourney_p2p'),
        localP2pBroadcasterProvider.overrideWith(
          (ref) => FakeLocalP2pBroadcaster(),
        ),
        ...overrides,
      ],
      child: AppThemeModeWrapper(
        mode: isDark ? 'dark' : 'normal',
        child: MaterialApp(
          theme: isDark
              ? ThemeData.dark().copyWith(extensions: [themeColors])
              : ThemeData.light().copyWith(extensions: [themeColors]),
          builder: (context, widget) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: widget!,
            );
          },
          home: Scaffold(body: Center(child: child)),
        ),
      ),
    );
  }

  group('📸 【Golden】P2Pローカル配信QR ＆ BANDグループ共有シート ピクセル視覚整合性テスト', () {
    testWidgets('1. P2pBroadcastDialog: 通常スマホ幅(390px) ライトモード レンダリング検証', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildWrapper(
          child: P2pBroadcastDialog(match: dummyMatch),
          isDark: false,
        ),
      );
      await tester.pumpAndSettle();

      // QRコード、閉じるボタン、IPアドレス、接続端末数が正しく描画されていること
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('閉じる'), findsOneWidget);
      expect(find.text('http://192.168.1.100:8080'), findsOneWidget);
      expect(find.text('接続中の端末: 3 台'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '2. P2pBroadcastDialog: 極小端末(iPhone SE / 375x667) & ダークモード ピクセル整合性検証',
      (tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildWrapper(
            child: P2pBroadcastDialog(match: dummyMatch),
            isDark: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.text('閉じる'), findsOneWidget);
        expect(find.text('接続中の端末: 3 台'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '3. P2pBroadcastDialog: 特大文字(textScaler 2.0x) 下でのレイアウト崩れ・オーバーフローゼロ検証',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildWrapper(
            child: P2pBroadcastDialog(match: dummyMatch),
            isDark: false,
            textScale: 2.0,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.text('閉じる'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('4. BandGroupSelectSheet: 登録グループ一覧・通常幅(390px) ライトモード ピクセル検証', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildWrapper(
          child: const BandGroupSelectSheet(
            formattedText: '【対戦カード速報】\n先鋒戦: 選手赤 vs 選手白',
          ),
          isDark: false,
          overrides: [
            bandGroupsStreamProvider.overrideWith(
              (ref) => Stream.value(dummyBandGroups),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BANDでLIVE配信・共有'), findsOneWidget);
      expect(find.text('誠道館 父母会LIVE'), findsOneWidget);
      expect(find.text('中体連 剣道部LIVE配信'), findsOneWidget);
      expect(find.text('コピーのみで閉じる'), findsOneWidget);
      expect(find.text('Bandを追加'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '5. BandGroupSelectSheet: 極小端末(375x667) & 特大文字(textScaler 2.0x) オーバーフローゼロ検証',
      (tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildWrapper(
            child: const BandGroupSelectSheet(
              formattedText: '【対戦カード速報】\n先鋒戦: 選手赤 vs 選手白',
            ),
            isDark: true,
            textScale: 2.0,
            overrides: [
              bandGroupsStreamProvider.overrideWith(
                (ref) => Stream.value(dummyBandGroups),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('BANDでLIVE配信・共有'), findsOneWidget);
        expect(find.text('誠道館 父母会LIVE'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
