import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar_community/isar.dart';
import 'dart:ui';
import 'dart:async'; // 🌟 TimeoutExceptionを有効化するために追加
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:kendo_os/firebase_options.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_registration_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/start_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/program_management_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/program_viewer_screen.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/tournament_list_screen.dart';
import 'package:kendo_os/shared/routing/match_router.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_match_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/admin/presentation/screens/master_management_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/create_tournament_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/setup_match_format_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/order_setup_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/team_scoreboard_screen.dart'; // 🌟 タイポを完全に排除しました
import 'package:kendo_os/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/features/tournament/presentation/screens/standings_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/official_record_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/auth_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/local_stroke_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_comment_entity.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_projection_entity.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_setup_screen.dart';
import 'package:kendo_os/features/tournament/presentation/screens/bunaiksen_official_record_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_official_record_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_team_scoreboard_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_kachinuki_scoreboard_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_official_record_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/admin/providers/metrics_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/features/auth/presentation/screens/role_select_screen.dart';
import 'package:kendo_os/features/auth/presentation/screens/pin_auth_screen.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/infrastructure/services/notification_service.dart';

import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart'
    as legacy_sync;
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/errors/global_error_handler.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

enum KendoOsEnv { dev, beta, prod }

class KendoOsConfig {
  final KendoOsEnv env;
  final bool enableTournamentMode;

  const KendoOsConfig({required this.env, this.enableTournamentMode = true});

  static const current = KendoOsConfig(
    env: KendoOsEnv.beta,
    enableTournamentMode: true,
  );
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// 🌟 起動したその瞬間からオフライン状態を100%確実に先制検知するグローバル・プロバイダ
final globalConnectivityProvider = StreamProvider.autoDispose<bool>((ref) {
  final controller = StreamController<bool>();

  // 起動時の初期接続状態を即座にチェックして反映
  Connectivity().checkConnectivity().then((result) {
    if (!controller.isClosed) {
      controller.add(result.contains(ConnectivityResult.none));
    }
  });

  // 以降の状態変化をリアルタイム追従
  final subscription = Connectivity().onConnectivityChanged.listen((result) {
    if (!controller.isClosed) {
      controller.add(result.contains(ConnectivityResult.none));
    }
  });

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

void main() {
  GlobalErrorHandler.runWithZone(() async {
    WidgetsFlutterBinding.ensureInitialized();
    usePathUrlStrategy();

    SharedPreferences? prefs;
    Isar? isar;

    Future<void> runInitialization() async {
      try {
        for (int i = 0; i < 15; i++) {
          if (Firebase.apps.isNotEmpty) {
            debugPrint(
              '⚡ [Sync] ネイティブのFirebaseインスタンスとの自動同期が完了しました (apps: ${Firebase.apps.length})',
            );
            break;
          }
          await Future.delayed(const Duration(milliseconds: 20));
        }

        if (Firebase.apps.isEmpty) {
          try {
            await Firebase.initializeApp();
            debugPrint('⚡ [Sync] optionsなしでネイティブの既存 [DEFAULT] をロード同期しました。');
          } catch (_) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
            debugPrint('🚀 Firebase [DEFAULT] をオプション指定でクリーンに新規初期化しました。');
          }
        } else {
          debugPrint(
            '📢 Firebase [DEFAULT] はすでに常駐しているため、初期化呼び出しを完全にスキップして既存インスタンスを安全に100%再利用します。',
          );
        }
      } catch (e) {
        final errorStr = e.toString();
        debugPrint('⚠️ Firebase初期化のキャッチ: $e');

        if (errorStr.contains('duplicate-app') ||
            errorStr.contains('already exists')) {
          for (int i = 0; i < 15; i++) {
            if (Firebase.apps.isNotEmpty) {
              break;
            }
            await Future.delayed(const Duration(milliseconds: 20));
          }
        }
      }

      try {
        if (!kIsWeb) {
          FlutterError.onError = (errorDetails) {
            try {
              FirebaseCrashlytics.instance.recordFlutterFatalError(
                errorDetails,
              );
            } catch (_) {}
          };
          PlatformDispatcher.instance.onError = (error, stack) {
            try {
              FirebaseCrashlytics.instance.recordError(
                error,
                stack,
                fatal: true,
              );
            } catch (_) {}
            return true;
          };
          debugPrint('🚀 [Crashlytics] ネイティブ環境の致命的クラッシュ監視ラインを活性化しました');
        } else {
          debugPrint('🚀 [Web WebAnalytics] Webアプリ版のブラウザ例外例外トラックを確立しました');
        }
      } catch (e) {
        debugPrint('⚠️ [Crashlytics] 初期化に失敗: $e');
      }

      () async {
        try {
          if (FirebaseAuth.instance.currentUser == null) {
            await FirebaseAuth.instance.signInAnonymously().timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException('Auth Timeout'),
            );
            debugPrint('🛡️ [Auth] 匿名ゲスト認証を自動確立しました');
          }
        } catch (_) {}
      }();

      try {
        prefs = await SharedPreferences.getInstance();
      } catch (e) {
        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
      }

      () async {
        try {
          if (!kIsWeb && prefs != null) {
            final hasCleared =
                prefs!.getBool('has_cleared_corrupted_firestore_cache_v3') ??
                false;
            if (!hasCleared) {
              try {
                await FirebaseFirestore.instance.terminate();
                await FirebaseFirestore.instance.clearPersistence();
                await prefs!.setBool(
                  'has_cleared_corrupted_firestore_cache_v3',
                  true,
                );
              } catch (_) {}
            }

            await FirebaseFirestore.instance.enableNetwork().timeout(
              const Duration(seconds: 1),
              onTimeout: () {},
            );
            FirebaseFirestore.instance
                .collectionGroup('matches')
                .limit(1)
                .snapshots()
                .listen((_) {}, onError: (_) {});
          }
        } catch (_) {}
      }();

      try {
        if (!kIsWeb) {
          final dir = await getApplicationDocumentsDirectory();
          final existingIsar = Isar.getInstance();
          if (existingIsar != null) {
            isar = existingIsar;
          } else {
            isar = await Isar.open([
              MatchEntitySchema,
              LocalStrokeModelSchema,
              MatchCommentEntitySchema,
              MatchProjectionEntitySchema,
              MatchCommandEntitySchema,
            ], directory: dir.path);
            debugPrint('🚀 [Isar] 新規にIsarインスタンスをオープンしました。');
          }
        }
      } catch (e) {
        debugPrint('⚠️ [Isar Init] エラー: $e');
      }
    }

    try {
      await Future.any([
        runInitialization().catchError((_) {}),
        Future.delayed(const Duration(milliseconds: 1500)),
      ]);
    } catch (_) {}

    if (prefs == null) {
      try {
        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
      } catch (_) {}
    }

    final nonNullPrefs = prefs!;
    try {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(nonNullPrefs),
          isarProvider.overrideWithValue(isar),
        ],
      );

      // 🌟 プッシュ通知インフラの起動時初期化（ネイティブ端末用）
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ UIレンダリング・エラー発生',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    details.exceptionAsString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
              // 物理ネットワークの切断状態を、最上位のレイアウト階層からダイレクトに監視
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
                            // 🔒 どの画面のロード状態がハングしていようとも、物理的に切断されていれば最前面に強制出現
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
                                    color: Colors.transparent,
                                    child: Container(
                                      width: double.infinity,
                                      color: Colors.amber.shade900,
                                      padding: const EdgeInsets.only(
                                        top: 34,
                                        bottom: 8,
                                      ),
                                      alignment: Alignment.center,
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.wifi_off_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            '⚠️ 体育館オフライン運営モード：ローカルキャッシュへ即時保存中',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
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

class AuthGuard extends ConsumerWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final session = ref.watch(authSessionProvider);
    return authState.when(
      data: (user) {
        if (user == null) {
          if (session != null && session.role == UserRole.viewer) {
            return child;
          }
          return const RoleSelectScreen();
        }
        return child;
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('エラー: $e'))),
    );
  }
}

final _router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/role-select',
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('ページが見つかりません: ${state.uri}'))),
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGuard(child: StartScreen()),
    ),
    GoRoute(
      path: '/role-select',
      builder: (context, state) => const RoleSelectScreen(),
    ),
    GoRoute(
      path: '/pin-auth',
      builder: (context, state) {
        final roleStr = state.uri.queryParameters['role'] ?? 'viewer';
        final role = UserRole.values.firstWhere(
          (e) => e.name == roleStr,
          orElse: () => UserRole.viewer,
        );
        return PinAuthScreen(role: role);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/master',
      builder: (context, state) => const MasterManagementScreen(),
    ),
    GoRoute(
      path: '/tournament-list',
      builder: (context, state) {
        final isArchive = state.extra as bool? ?? false;
        final screen = TournamentListScreen(isArchive: isArchive);
        if (isArchive) {
          return AppThemeModeWrapper(mode: 'normal_viewer', child: screen);
        }
        return screen;
      },
    ),
    GoRoute(
      path: '/viewer/:id',
      builder: (context, state) => AppThemeModeWrapper(
        mode: 'normal_viewer',
        child: ViewerMatchScreen(matchId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/home/:tournamentId',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.pathParameters['tournamentId']!,
        child: HomeScreen(tournamentId: state.pathParameters['tournamentId']!),
      ),
    ),
    GoRoute(
      path: '/tournament/:id/programs',
      builder: (context, state) =>
          ProgramManagementScreen(tournamentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/program-viewer',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return ProgramViewerScreen(
          programs: args['programs'] as List<ProgramModel>,
          initialIndex: args['index'] as int,
        );
      },
    ),
    GoRoute(
      path: '/match/:id',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.uri.queryParameters['tournamentId'],
        child: MatchRouter(matchId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/team-scoreboard/:groupName',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.uri.queryParameters['tournamentId'],
        child: TeamScoreboardScreen(
          groupName: state.pathParameters['groupName']!,
        ),
      ),
    ),
    GoRoute(
      path: '/viewer-home/:tournamentId',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.pathParameters['tournamentId']!,
        child: AppThemeModeWrapper(
          mode: 'normal_viewer',
          child: ViewerHomeScreen(
            tournamentId: state.pathParameters['tournamentId']!,
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/viewer-record/:tournamentId',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.pathParameters['tournamentId']!,
        child: AppThemeModeWrapper(
          mode: 'normal_viewer',
          child: ViewerOfficialRecordScreen(
            tournamentId: state.pathParameters['tournamentId']!,
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/viewer-team/:groupName',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.uri.queryParameters['tournamentId'],
        child: AppThemeModeWrapper(
          mode: 'normal_viewer',
          child: ViewerTeamScoreboardScreen(
            groupName: state.pathParameters['groupName']!,
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/viewer-kachinuki/:groupName',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.uri.queryParameters['tournamentId'],
        child: AppThemeModeWrapper(
          mode: 'normal_viewer',
          child: ViewerKachinukiScoreboardScreen(
            groupName: state.pathParameters['groupName']!,
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/kachinuki-scoreboard/:groupName',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.uri.queryParameters['tournamentId'],
        child: KachinukiScoreboardScreen(
          groupName: state.pathParameters['groupName']!,
        ),
      ),
    ),
    GoRoute(
      path: '/create-tournament',
      builder: (context, state) => const CreateTournamentScreen(),
    ),
    GoRoute(
      path: '/setup-match/:id',
      builder: (context, state) =>
          SetupMatchFormatScreen(tournamentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/order-setup/:id',
      builder: (context, state) =>
          OrderSetupScreen(tournamentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/team-registration/:id',
      builder: (context, state) =>
          TeamRegistrationScreen(tournamentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/standings/:id',
      builder: (context, state) =>
          StandingsScreen(tournamentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/official-record/:id',
      builder: (context, state) =>
          OfficialRecordScreen(tournamentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/bunaiksen-home',
      builder: (context, state) => const AppThemeModeWrapper(
        mode: 'bunaiksen',
        child: BunaiksenHomeScreen(),
      ),
    ),
    GoRoute(
      path: '/bunaiksen-setup',
      builder: (context, state) => const AppThemeModeWrapper(
        mode: 'bunaiksen',
        child: BunaiksenSetupScreen(),
      ),
    ),
    GoRoute(
      path: '/bunaiksen-record',
      builder: (context, state) => const AppThemeModeWrapper(
        mode: 'bunaiksen',
        child: BunaiksenOfficialRecordScreen(),
      ),
    ),
    GoRoute(
      path: '/bunaiksen-viewer-home/:tournamentId',
      builder: (context, state) => RoleInjector(
        roleStr: 'viewer',
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.pathParameters['tournamentId']!,
        child: AppThemeModeWrapper(
          mode: 'bunaiksen_viewer',
          child: ViewerBunaiksenHomeScreen(
            tournamentId: state.pathParameters['tournamentId']!,
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/bunaiksen-viewer-record/:tournamentId',
      builder: (context, state) => RoleInjector(
        roleStr: 'viewer',
        dojoId: state.uri.queryParameters['dojoId'],
        child: AppThemeModeWrapper(
          mode: 'bunaiksen_viewer',
          child: ViewerBunaiksenOfficialRecordScreen(
            tournamentId: state.pathParameters['tournamentId']!,
          ),
        ),
      ),
    ),
  ],
);

final routeObserverProvider = Provider<void>((ref) {
  void listener() {
    final location = _router.routeInformationProvider.value.uri.path;
    final targetMode = location.contains('master')
        ? OperationMode.local
        : OperationMode.tournament;
    if (ref.read(operationModeProvider) != targetMode) {
      Future.microtask(() {
        ref.read(operationModeProvider.notifier).state = targetMode;
      });
    }
  }

  listener();
  _router.routerDelegate.addListener(listener);
  ref.onDispose(() => _router.routerDelegate.removeListener(listener));
});

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

    ThemeMode currentThemeMode = ThemeMode.system;
    if (settings.themeMode == 'light') {
      currentThemeMode = ThemeMode.light;
    } else if (settings.themeMode == 'dark') {
      currentThemeMode = ThemeMode.dark;
    }

    final darkThemeBase = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
      canvasColor: Colors.black,
      textTheme: GoogleFonts.notoSansJpTextTheme(ThemeData.dark().textTheme),
      extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
    );

    final lightThemeBase = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      textTheme: GoogleFonts.notoSansJpTextTheme(ThemeData.light().textTheme),
      extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
    );

    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      themeMode: currentThemeMode,
      theme: lightThemeBase,
      darkTheme: darkThemeBase,
      routerConfig: _router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
      // 🔒 遷移後の画面（child）の真上を強制的にジャックし、どの画面にいてもバナーを最前面へ絶対露出させます
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        return Consumer(
          builder: (context, ref, _) {
            final isOffline =
                ref.watch(globalConnectivityProvider).value ?? false;

            return Scaffold(
              backgroundColor: Colors.black, // 隙間風（背景のチラつき）を完全防衛するベースカラー
              body: Column(
                children: [
                  // 🔒 オフライン時のみ最上部にニュッと出現し、下の画面を安全に押し下げるインジケータ
                  if (isOffline)
                    Container(
                      width: double.infinity,
                      color: Colors.amber.shade900,
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 8,
                        bottom: 8,
                        left: 16,
                        right: 16,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              kIsWeb
                                  ? '⚠️ 体育館オフライン運営モード：ブラウザキャッシュへ即時保存中'
                                  : '⚠️ 体育館オフライン運営モード：ローカルDB（Isar）へ即時保存中',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // アプリケーション本来の画面遷移レイヤー（バナーの下に100%安全に描画され、戻るボタンも完全生存）
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

class RoleInjector extends ConsumerWidget {
  final Widget child;
  final String? roleStr;
  final String? dojoId;
  final String? tournamentId;

  const RoleInjector({
    super.key,
    required this.child,
    this.roleStr,
    this.dojoId,
    this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDojoId = ref.read(currentDojoIdProvider);
    final currentTournamentId = ref.read(webCurrentTournamentIdProvider);

    if (dojoId != null && dojoId!.isNotEmpty && currentDojoId != dojoId) {
      Future.microtask(() {
        ref.read(currentDojoIdProvider.notifier).state = dojoId!;
        debugPrint('🏢 [Role Injector] 描画同期サイクル内でテナントID($dojoId)を永久確定しました');
      });
    }

    if (kIsWeb &&
        tournamentId != null &&
        tournamentId!.isNotEmpty &&
        currentTournamentId != tournamentId) {
      Future.microtask(() {
        ref.read(webCurrentTournamentIdProvider.notifier).state = tournamentId!;
        debugPrint('🎯 [Role Injector] 描画同期サイクル内で大会ID($tournamentId)を永久確定しました');
      });
    }

    if (roleStr == 'viewer') {
      final currentSession = ref.read(authSessionProvider);
      if (currentSession == null || currentSession.role == UserRole.viewer) {
        Future.microtask(() {
          ref
              .read(authSessionProvider.notifier)
              .establishSession(
                UserRole.viewer,
                dojoId ?? ref.read(currentDojoIdProvider),
              );
          debugPrint('🔐 [Role Injector] 一般観客席セッションを確実にロックしました');
        });
      }
    }

    return child;
  }
}
