import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kendo_os/admin/providers/metrics_provider.dart';

import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart'
    as legacy_sync;
import 'package:kendo_os/shared/bootstrap/app_bootstrap_helper.dart';
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

export 'package:kendo_os/shared/bootstrap/app_bootstrap_helper.dart';
export 'package:kendo_os/shared/routing/app_router.dart';

void main() {
  GlobalErrorHandler.runWithZone(() async {
    WidgetsFlutterBinding.ensureInitialized();
    usePathUrlStrategy();

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

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        container.read(metricsProvider).recordError();
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        container.read(metricsProvider).recordError();
        return true;
      };

      ErrorWidget.builder = (FlutterErrorDetails details) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ UIレンダリング・エラー発生',
                    style: TextStyle(
                      color: AppKendoColors.red,
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.headline,
                    ),
                  ),
                  Text(
                    details.exceptionAsString(),
                    style: const TextStyle(
                      color: AppKendoColors.pureBlack,
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      };

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, child) {
              final isOffline =
                  ref.watch(globalConnectivityProvider).value ?? false;

              return Localizations(
                locale: PlatformDispatcher.instance.locale,
                delegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Overlay(
                    initialEntries: [
                      OverlayEntry(
                        builder: (context) => Stack(
                          children: [
                            const KendoOSApp(),
                            if (isOffline)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: MediaQuery(
                                  data: MediaQueryData.fromView(
                                    PlatformDispatcher.instance.views.first,
                                  ),
                                  child: Material(
                                    color: AppKendoColors.transparent,
                                    child: Container(
                                      width: double.infinity,
                                      color: const Color(0xFFD97706),
                                      padding: const EdgeInsets.only(
                                        top: 34,
                                        bottom: AppSpacing.sm,
                                      ),
                                      alignment: Alignment.center,
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.wifi_off_rounded,
                                            color: AppKendoColors.pureWhite,
                                            size: 18,
                                          ),
                                          SizedBox(width: AppSpacing.sm),
                                          Text(
                                            '⚠️ 体育館オフライン運営モード：ローカルキャッシュへ即時保存中',
                                            style: TextStyle(
                                              color: AppKendoColors.pureWhite,
                                              fontWeight: AppFontWeight.bold,
                                              fontSize: AppFontSize.bodySmall,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (kIsWeb) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      debugPrint('🌙 [Lifecycle] アプリがバックグラウンドに移行しました。未送信データの強制同期を試行します...');
      ref.read(syncEngineProvider).processQueue();
      ref.read(legacy_sync.syncEngineProvider).syncNow();
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

    final settings = ref.watch(settingsProvider);

    final isSunshine = settings.themeMode == 'sunshine';
    ThemeMode currentThemeMode = ThemeMode.system;
    if (settings.themeMode == 'light' || isSunshine) {
      currentThemeMode = ThemeMode.light;
    } else if (settings.themeMode == 'dark') {
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

        return Consumer(
          builder: (context, ref, _) {
            final isOffline =
                ref.watch(globalConnectivityProvider).value ?? false;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Scaffold(
              backgroundColor: isDark
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFFF2F2F7),
              body: Column(
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
                  Expanded(child: child),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
