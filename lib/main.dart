import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kendo_os/admin/providers/metrics_provider.dart';
import 'package:kendo_os/bootstrap/app_startup.dart';
import 'package:kendo_os/features/auth/application/user_data_cloud_sync_manager.dart';
import 'package:kendo_os/shared/application/services/sound_service.dart';
import 'package:kendo_os/shared/infrastructure/services/web_platform_optimizer.dart';

import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart'
    as legacy_sync;
import 'package:kendo_os/shared/bootstrap/app_bootstrap_helper.dart';
import 'package:kendo_os/shared/errors/emergency_crash_preserver.dart';
import 'package:kendo_os/shared/errors/global_error_handler.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/shared/infrastructure/services/notification_service.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/routing/app_router.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/thermal_floating_toast.dart';

export 'package:kendo_os/shared/bootstrap/app_bootstrap_helper.dart';
export 'package:kendo_os/shared/routing/app_router.dart';

void main() {
  GlobalErrorHandler.runWithZone(() async {
    WidgetsFlutterBinding.ensureInitialized();
    usePathUrlStrategy();

    // 🌐 【Phase 7】Safari & Chrome 2大ブラウザ極限最適化
    WebPlatformOptimizer.applyOptimizations();

    // 💾 【Phase 2】メモリ効率＆画像キャッシュ上限の自動制御
    AppStartup.configureImageCache();

    // 📦 【Phase 6】フォント・アセット最適化
    AppStartup.configureFontOptimization();

    final initResult = await AppBootstrapHelper.initialize();
    final nonNullPrefs = initResult.prefs;
    final isar = initResult.isar;

    try {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(nonNullPrefs),
          isarProvider.overrideWithValue(isar),
        ],
      );

      try {
        container.read(notificationServiceProvider).initializeNotification();
      } catch (e) {
        debugPrint('⚠️ [Notification] Startup initialization failed: $e');
      }

      // ☁️ Google連携アカウント設定・履歴のクラウド自動同期マネージャー起動
      try {
        container.read(userDataCloudSyncManagerProvider).initialize();
      } catch (e) {
        debugPrint('⚠️ [UserDataCloudSync] Startup initialization failed: $e');
      }

      // 🔊 【Phase 8】オーディオPre-warming（ノンブロッキング非同期で事前暖機）
      try {
        unawaited(container.read(soundServiceProvider).prewarm());
      } catch (e) {
        debugPrint('⚠️ [SoundService] Prewarm failed: $e');
      }

      // ⚡ 【Plan 1-5】アセット・フォント・シェーダーの事前ウォームアップ（ノンブロッキング非同期）
      unawaited(AppStartup.prewarmAppAssets());

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        // 🛡️ 【Plan 3-3】Fatal Crash Trap: 直前状態の緊急退避
        EmergencyCrashPreserver.preserveOnCrash(
          error: details.exception,
          stackTrace: details.stack,
        );
        container.read(metricsProvider).recordError();
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        // 🛡️ 【Plan 3-3】Fatal Crash Trap: 直前状態の緊急退避
        EmergencyCrashPreserver.preserveOnCrash(
          error: error,
          stackTrace: stack,
        );
        container.read(metricsProvider).recordError();
        return true;
      };

      ErrorWidget.builder = (FlutterErrorDetails details) {
        return Scaffold(
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
                      Row(
                        children: [
                          const Icon(
                            Icons.shield,
                            color: AppKendoColors.ipponGold,
                            size: 28,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Expanded(
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
        );
      };

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const KendoOSApp(),
        ),
      );
    } catch (e) {
      runApp(
        MaterialApp(
          home: Scaffold(body: Center(child: Text('起動エラー: $e'))),
        ),
      );
    }
  });
}

class KendoOSApp extends ConsumerStatefulWidget {
  const KendoOSApp({super.key});

  @override
  ConsumerState<KendoOSApp> createState() => _KendoOSAppState();
}

class _KendoOSAppState extends ConsumerState<KendoOSApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 🌟 Web/PWA起動直後のiOS Webkit初期ビューポート判定ラグを強制補正
        WidgetsBinding.instance.handleMetricsChanged();
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            WidgetsBinding.instance.handleMetricsChanged();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncEngineProvider);
    ref.watch(legacy_sync.syncEngineProvider);
    ref.watch(dojoRoomSyncProvider);
    ref.watch(routeObserverProvider);

    // ⚡【Plan 最適化】themeMode/textSizeModeをピンポイント購読し、他の設定変更（バイブ・確認ダイアログ・スリープ等）による
    // KendoOSApp（ルートMaterialApp全体）の不要な再ビルド（フレームドロップ・Jank）を完全排除
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final textSizeMode = ref.watch(
      settingsProvider.select((s) => s.textSizeMode),
    );

    final isSunshine = themeMode == 'sunshine';
    ThemeMode currentThemeMode = ThemeMode.system;
    if (themeMode == 'light' || isSunshine) {
      currentThemeMode = ThemeMode.light;
    } else if (themeMode == 'dark') {
      currentThemeMode = ThemeMode.dark;
    }

    final commonDialogTheme = const DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
    );

    final commonBottomSheetTheme = const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xlargeValue),
        ),
      ),
    );

    final darkThemeBase = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppKendoColors.pureBlack,
      canvasColor: AppKendoColors.pureBlack,
      dialogTheme: commonDialogTheme,
      bottomSheetTheme: commonBottomSheetTheme,
      textTheme: GoogleFonts.notoSansJpTextTheme(ThemeData.dark().textTheme),
      extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
    );

    final lightThemeBase = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: isSunshine
          ? AppKendoColors.pureWhite
          : const Color(0xFFF2F2F7),
      dialogTheme: commonDialogTheme,
      bottomSheetTheme: commonBottomSheetTheme,
      textTheme: GoogleFonts.notoSansJpTextTheme(ThemeData.light().textTheme),
      extensions: [
        AppThemeColors.ofMode(
          isDark: false,
          mode: isSunshine ? 'sunshine' : 'normal',
        ),
      ],
    );

    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      themeMode: currentThemeMode,
      theme: lightThemeBase,
      darkTheme: darkThemeBase,
      routerConfig: appRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        // 🛡️ 第1防壁: 年長者・弱視向け文字拡大スケーラー & 上限クランプリミッター
        final baseScaler = MediaQuery.of(context).textScaler;
        final TextScaler effectiveScaler;
        switch (textSizeMode) {
          case 'large':
            effectiveScaler = baseScaler.clamp(
              minScaleFactor: 1.15,
              maxScaleFactor: 1.25,
            );
            break;
          case 'extraLarge':
            effectiveScaler = baseScaler.clamp(
              minScaleFactor: 1.30,
              maxScaleFactor: 1.40,
            );
            break;
          case 'normal':
          default:
            effectiveScaler = baseScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.15,
            );
            break;
        }

        final scaledChild = MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: effectiveScaler),
          child: child,
        );

        return Consumer(
          builder: (context, ref, _) {
            final isOffline =
                ref.watch(globalConnectivityProvider).value ?? false;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Scaffold(
              backgroundColor: isDark
                  ? AppKendoColors.pureBlack
                  : const Color(0xFFF2F2F7),
              body: ThermalToastListener(
                child: Column(
                  children: [
                    if (isOffline)
                      Container(
                        width: double.infinity,
                        color: const Color(0xFFD97706),
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 8,
                          bottom: AppSpacing.sm,
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              color: AppKendoColors.pureWhite,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                kIsWeb
                                    ? '⚠️ 体育館オフライン運営モード：ブラウザキャッシュへ即時保存中'
                                    : '⚠️ 体育館オフライン運営モード：ローカルDB（Isar）へ即時保存中',
                                style: const TextStyle(
                                  color: AppKendoColors.pureWhite,
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: AppFontSize.bodySmall,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(child: scaledChild),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
