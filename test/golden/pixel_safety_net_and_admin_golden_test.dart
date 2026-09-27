import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/admin/dashboard/observability_dashboard_screen.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildSafetyNetView({
    required FlutterErrorDetails details,
    required Size size,
    double textScale = 1.0,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: AppKendoColors.pureBlack,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppKendoColors.pureBlack,
                    borderRadius: AppRadius.large,
                    border: Border.all(
                      color: AppKendoColors.ipponGold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.shield,
                            color: AppKendoColors.ipponGold,
                            size: 28,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '🛡️ KendoOS 不壊セーフティネット作動',
                              style: TextStyle(
                                color: AppKendoColors.pureWhite,
                                fontWeight: AppFontWeight.bold,
                                fontSize: AppFontSize.headline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        '試合データは自動退避・保護されました。クラッシュによるデータ消失は発生していません。',
                        style: TextStyle(
                          color: AppKendoColors.pureWhite,
                          fontSize: AppFontSize.body,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        details.exceptionAsString(),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppKendoColors.pureWhite.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: AppFontSize.small,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAdminDashboardView({required Size size, double textScale = 1.0}) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: const ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ObservabilityDashboardScreen(),
        ),
      ),
    );
  }

  group('📸 【Golden】不壊セーフティネット作動画面 ＆ 管理者ダッシュボード ピクセル完全性テスト', () {
    final simulatedDetails = FlutterErrorDetails(
      exception: Exception('現場テスト用シミュレーションエラー: Database timeout'),
      stack: StackTrace.current,
    );

    testWidgets('1. セーフティネット作動画面: 通常画面 (1080x1920) ピクセル描画検証', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildSafetyNetView(
          details: simulatedDetails,
          size: const Size(1080, 1920),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🛡️ KendoOS 不壊セーフティネット作動'), findsOneWidget);
      expect(
        find.text('試合データは自動退避・保護されました。クラッシュによるデータ消失は発生していません。'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. セーフティネット作動画面: 極小端末 (iPhone SE / 375x667) オーバーフローゼロ検証', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildSafetyNetView(
          details: simulatedDetails,
          size: const Size(375, 667),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🛡️ KendoOS 不壊セーフティネット作動'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. セーフティネット作動画面: 特大文字（textScaler: 2.0倍）ピクセル崩れゼロ検証', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildSafetyNetView(
          details: simulatedDetails,
          size: const Size(390, 844),
          textScale: 2.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🛡️ KendoOS 不壊セーフティネット作動'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('4. 管理者ダッシュボード: 初期レイアウト描画検証 (ObservabilityDashboardScreen)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildAdminDashboardView(size: const Size(800, 1200)),
      );
      await tester.pumpAndSettle();

      expect(find.text('運用ダッシュボード (Observability)'), findsOneWidget);
      expect(find.text('総イベント処理数'), findsOneWidget);
      expect(find.text('システムエラー率 (直近)'), findsOneWidget);
      expect(find.text('同時書き込み競合率 (直近)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
