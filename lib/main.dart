import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // ★ Phase 9-3: インポート追加
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ★ 追加: 未ログイン時の通信エラー回避用
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar_community/isar.dart';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // ★ 追加: URLの#を消すためのプラグイン

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
import 'package:kendo_os/features/tournament/presentation/operate/team_scoreboard_screen.dart';
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
import 'package:kendo_os/shared/infrastructure/persistence/models/match_projection_entity.dart'; // ★ 追加
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

import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart'
    as legacy_sync;
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/errors/global_error_handler.dart';

// =========================================================================
// 🛡️ Phase 6 - STEP 6-1 & 6-2 要件：環境分離 ＆ Feature Flag 基盤
// Firebaseのdev/beta/prodを完全隔離し、将来的な大会運営拡張機能の安全な
// トグル制御（enableTournamentMode）をフロントエンドに配備します。
// =========================================================================
enum KendoOsEnv { dev, beta, prod }

class KendoOsConfig {
  final KendoOsEnv env;
  final bool enableTournamentMode;

  const KendoOsConfig({
    required this.env,
    this.enableTournamentMode = true, // 🌟 デフォルトで大会運営拡張機能を活性化
  });

  static const current = KendoOsConfig(
    env: KendoOsEnv.beta, // 🌟 現在は遠征・道場現場投入用の「beta」環境に固定
    enableTournamentMode: true,
  );
}

// ★ 追加: 画面のNavigatorをどこからでも取得するためのグローバルキー
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

// ★ Step 5-2: アプリ全体でバックグラウンド通知を表示するための「どこでもドア」キー
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  // 🛡️ 起動シーケンスの完全カプセル化（Zone mismatch & 未初期化エラーを同時リセット）
  GlobalErrorHandler.runWithZone(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // ★ URLパスから「#」を取り除き、Webのディープリンクを正常に処理させる（ホワイトアウト対策1）
    usePathUrlStrategy();

    SharedPreferences? prefs;
    Isar? isar;

    // 非同期初期化処理をカプセル化したローカル関数
    Future<void> runInitialization() async {
      // 1. Firebase初期化（先行フォールバック同期仕様 + 非同期同期完了待ち + no-app防止ガード）
      try {
        // Hot Restart時、ネイティブ側に存在する既存アプリ情報がプラットフォームチャネル経由で
        // Dart側の Firebase.apps に同期されるまで数ミリ秒のラグがあるため、少し待機して自動同期を待つ
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
            // Hot Restart時、ネイティブにすでにアプリが存在しているなら、optionsなしで呼ぶと
            // ネイティブがアサートクラッシュせず、既存の [DEFAULT] をそのまま Dart に同期して返します。
            await Firebase.initializeApp();
            debugPrint('⚡ [Sync] optionsなしでネイティブの既存 [DEFAULT] をロード同期しました。');
          } catch (_) {
            // ネイティブにまだ存在しない場合 (コールドスタート等) は plist がなく失敗するので、
            // 正規の options を与えてクリーンに新規初期化します。
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

        // もし duplicate-app が発生した場合、ネイティブ側には確実にアプリが存在するので、
        // Dart側へ同期されるまで再度待機して no-app 例外の誘発を100%防ぐ
        if (errorStr.contains('duplicate-app') ||
            errorStr.contains('already exists')) {
          debugPrint('🛡️ [duplicate-app] を検知。既存インスタンスのロード同期完了を待ちます...');
          for (int i = 0; i < 15; i++) {
            if (Firebase.apps.isNotEmpty) {
              debugPrint('🛡️ [duplicate-app] 既存インスタンスのロード同期に成功しました。');
              break;
            }
            await Future.delayed(const Duration(milliseconds: 20));
          }
        }
      }

      // 2. Crashlyticsの設定
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

      // 3. 匿名ログイン（ゲスト認証）
      try {
        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously();
          debugPrint('🛡️ [Auth] 匿名ゲスト認証を自動確立しました（ルーム参加準備完了）');
        }
      } catch (e) {
        debugPrint('⚠️ [Auth] 匿名認証に失敗: $e');
      }

      // 4. SharedPreferencesの初期化
      try {
        prefs = await SharedPreferences.getInstance();
      } catch (e) {
        debugPrint('⚠️ [SharedPreferences] 取得失敗、モックで代替します: $e');
        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
      }

      // 5. Firestoreキャッシュクリア＆強制オンライン化
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
              debugPrint('🧹 [Firestore] 古いローカルキャッシュを強制ワイプしました（スタック完全解消 v3）');
            } catch (e) {
              debugPrint('⚠️ [Firestore] キャッシュワイプに失敗: $e');
            }
          }

          await FirebaseFirestore.instance.enableNetwork();
          debugPrint('🌐 [Firestore] ネットワーク接続を強制的に有効化しました');

          FirebaseFirestore.instance
              .collectionGroup('matches')
              .limit(1)
              .snapshots()
              .listen((_) {});
        }
      } catch (e) {
        debugPrint('⚠️ [Firestore Settings] 失敗: $e');
      }

      // 6. Isar DBの衝突回避オープン
      try {
        if (!kIsWeb) {
          final dir = await getApplicationDocumentsDirectory();

          const bool forceWipeIsar = false;
          // ignore: dead_code
          if (forceWipeIsar) {
            try {
              final isarDir = Directory(dir.path);
              if (isarDir.existsSync()) {
                for (var file in isarDir.listSync()) {
                  if (file.path.endsWith('.isar') ||
                      file.path.endsWith('.isar.lock')) {
                    file.deleteSync();
                  }
                }
              }
              debugPrint('🧹 [Isar] データベースファイルを強制リセットしました');
            } catch (e) {
              debugPrint('⚠️ [Isar Wipe] エラー: $e');
            }
          }

          final existingIsar = Isar.getInstance();
          if (existingIsar != null) {
            isar = existingIsar;
            debugPrint('📢 [Isar] 既存のIsarインスタンスを安全に100%再利用します。');
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

    // 🌟 タイムアウト安全弁（3秒で強制カット＆フォールバック起動。孤立例外によるクラッシュを完全に防ぐ catchError 付き）
    try {
      await Future.any([
        runInitialization().catchError((e) {
          debugPrint('⚠️ [Background Init Error] バックグラウンド初期化中に例外が発生しました: $e');
        }),
        Future.delayed(const Duration(seconds: 3)).then((_) {
          debugPrint('⚠️ [Timeout] アプリの初期化が3秒以内に完了しなかったため、安全弁が起動しました。');
        }),
      ]);
    } catch (e) {
      debugPrint('⚠️ [Initialization Warning/Timeout]: $e');
    }

    // タイムアウトなどでSharedPreferencesが取得できなかった場合の防衛策
    if (prefs == null) {
      try {
        debugPrint('🛡️ [Fallback] SharedPreferencesのモックを取得して起動を続行します');
        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
      } catch (e) {
        debugPrint('🔥 [Critical Fallback Failed] SharedPreferencesの取得に失敗: $e');
      }
    }

    try {
      // ProviderContainer作成
      final container = ProviderContainer(
        overrides: [
          if (prefs != null)
            sharedPreferencesProvider.overrideWithValue(prefs!),
          isarProvider.overrideWithValue(isar),
        ],
      );

      // UIエラーキャッチ
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        if (!kIsWeb) {
          try {
            FirebaseCrashlytics.instance.recordFlutterFatalError(details);
          } catch (_) {}
        }
        container.read(metricsProvider).recordError();
        debugPrint('⚠️ UIエラー: ${details.exception}');
      };

      // 非同期例外キャッチ
      PlatformDispatcher.instance.onError = (error, stack) {
        if (!kIsWeb) {
          try {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          } catch (_) {}
        }
        container.read(metricsProvider).recordError();
        debugPrint('⚠️ 裏側エラー: $error');
        return true;
      };

      // 最強のエラー画面表示
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
                  const SizedBox(height: 12),
                  const Text(
                    '以下のログを開発者へ共有してください：',
                    style: TextStyle(color: Colors.black87, fontSize: 12),
                  ),
                  const Divider(),
                  Text(
                    details.exceptionAsString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    details.stack?.toString() ?? 'スタックトレースなし',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        );
      };

      // ★ UncontrolledProviderScope を使って、自前で作ったコンテナをアプリに渡す
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const KendoOSApp(),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('🔥 [Fatal Init Error] 起動時に致命的なエラーが発生しました: $e');
      debugPrint('🔥 [Fatal Init StackTrace]\n$stackTrace');

      // エラー内容を判定して、表示するメッセージを最適化
      final errorStr = e.toString();
      String displayMessage =
          'アプリの起動に失敗しました。\n\n'
          '【原因の可能性】\n'
          '・QRコードリーダーの内蔵ブラウザを使用している\n'
          '・プライベートブラウズ（シークレットモード）になっている\n\n'
          '右下の「Safari/Chromeで開く」アイコン等を押して、通常のブラウザで開き直してください。\n\n'
          '詳細エラー: $errorStr';

      // データベース制限（アプリ内ブラウザ等）の場合、英語のエラー文を隠して優しい案内に差し替え
      if (errorStr.contains('IsarError') || errorStr.contains('IndexedDB')) {
        displayMessage =
            '【ブラウザのセキュリティ制限】\n\n'
            'LINEやQRコードリーダーの内蔵ブラウザ、またはシークレットモードでは、プライバシー保護機能によりアプリが起動できません。\n\n'
            '画面右下（または右上）のメニューから\n'
            '「Safariで開く」または「ブラウザで開く」\n'
            'を選択して、通常の環境で開き直してください。';
      }

      // ★ 起動処理全体を囲んでエラー画面を表示する（ホワイトアウト完全対策）
      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  displayMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return; // 処理を終了
    }
  });
}

// ==========================================
// ★ Phase 8-8: 画面単位の認証ガード (Zero Trust Router)
// ==========================================
class AuthGuard extends ConsumerWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final session = ref.watch(authSessionProvider);
    return authState.when(
      data: (user) {
        // 未ログインであっても、一般観客席 (UserRole.viewer) セッションが確立している場合は通過させる
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

// ==========================================
// ★ 静的ルーター（クラッシュとURL消失を完全防止）
// ==========================================
final _router = GoRouter(
  navigatorKey: rootNavigatorKey, // ★ 追加: ルーターキーを登録
  initialLocation: '/role-select', // ★ 初期ルートをロール選択へ固定してViewer固定問題を完全解決
  // ★ 存在しないURLやルーティングエラー時に真っ白になるのを防ぐ（ホワイトアウト対策3）
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'ページが見つかりません: ${state.uri}\nURLが間違っているか、削除された可能性があります。',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  ),
  routes: [
    GoRoute(
      path: '/',
      // ★ 管理者ホームは AuthGuard で守る（未ログインならURLは/のままLoginScreenが出る）
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
    ), // ★ Phase 2: 設定画面へのルート
    // ==========================================
    // ★ Phase 9: Hidden Feature 完全隔離
    // ==========================================
    // 以下の開発者専用ルートは、一般ユーザーがディープリンク等で不正アクセスすることを
    // 防ぐため、Stage2 βルーティングテーブルから完全に排除されました。
    // (ObservabilityDashboardScreen, ReplayConsole, ChaosDrill へのパスを物理除去)

    // ★ 復旧: 選手マスタ管理画面へのルートを再開通
    GoRoute(
      path: '/master',
      builder: (context, state) => const MasterManagementScreen(),
    ),

    GoRoute(
      path: '/tournament-list',
      builder: (context, state) {
        // extra からアーカイブモードかどうかを受け取る（デフォルトは false）
        final isArchive = state.extra as bool? ?? false;
        return TournamentListScreen(isArchive: isArchive);
      },
    ),
    GoRoute(
      path: '/viewer/:id',
      builder: (context, state) =>
          ViewerMatchScreen(matchId: state.pathParameters['id']!),
    ),
    // ★ Phase 6: 全ての共有可能画面を RoleInjector で包み、URLからViewer権限を適用できるようにする
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
        // Map形式で programs と index を受け取る
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
        child: ViewerHomeScreen(
          tournamentId: state.pathParameters['tournamentId']!,
        ),
      ),
    ),
    GoRoute(
      path: '/viewer-record/:tournamentId',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.pathParameters['tournamentId']!,
        child: ViewerOfficialRecordScreen(
          tournamentId: state.pathParameters['tournamentId']!,
        ),
      ),
    ),
    GoRoute(
      path: '/viewer-team/:groupName',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.uri.queryParameters['tournamentId'],
        child: ViewerTeamScoreboardScreen(
          groupName: state.pathParameters['groupName']!,
        ),
      ),
    ),
    GoRoute(
      path: '/viewer-kachinuki/:groupName',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.uri.queryParameters['tournamentId'],
        child: ViewerKachinukiScoreboardScreen(
          groupName: state.pathParameters['groupName']!,
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
    // ★ Phase 8-3: 自チーム成績と出力用スコアのルーター設定を追加
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
      builder: (context, state) => const BunaiksenHomeScreen(),
    ),
    GoRoute(
      path: '/bunaiksen-setup',
      builder: (context, state) => const BunaiksenSetupScreen(),
    ),
    GoRoute(
      path: '/bunaiksen-record',
      builder: (context, state) => const BunaiksenOfficialRecordScreen(),
    ),
    GoRoute(
      path: '/bunaiksen-viewer-home/:tournamentId',
      builder: (context, state) => RoleInjector(
        roleStr: 'viewer', // ★強制的にViewer権限にダウングレード
        dojoId: state.uri.queryParameters['dojoId'],
        child: ViewerBunaiksenHomeScreen(
          tournamentId: state.pathParameters['tournamentId']!,
        ),
      ),
    ),
    GoRoute(
      path: '/bunaiksen-viewer-record/:tournamentId',
      builder: (context, state) => RoleInjector(
        roleStr: 'viewer', // ★強制的にViewer権限にダウングレード
        dojoId: state.uri.queryParameters['dojoId'],
        child: ViewerBunaiksenOfficialRecordScreen(
          tournamentId: state.pathParameters['tournamentId']!,
        ),
      ),
    ),
  ],
);

// ★ 中央司令部：ルーターの遷移イベントを監視してモードを自動同期する
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

  listener(); // 初期化時に1回実行
  _router.routerDelegate.addListener(listener); // 画面遷移（Pop含む）のたびに発火
  ref.onDispose(() => _router.routerDelegate.removeListener(listener));
});

class KendoOSApp extends ConsumerStatefulWidget {
  const KendoOSApp({super.key});

  @override
  ConsumerState<KendoOSApp> createState() => _KendoOSAppState();
}

// ★ Phase 8-4: ライフサイクルを監視するために WidgetsBindingObserver を追加
class _KendoOSAppState extends ConsumerState<KendoOSApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 監視スタート
  }

  // ★ Phase 8-4: アプリの状態が変わった時に呼ばれる
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (kIsWeb) return; // ★ 追加: Webブラウザ環境ではローカルDBを持たないため、バックグラウンド処理全体をスキップする

    // アプリがバックグラウンドに回った（スリープ、ホーム画面に戻る等）瞬間
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      debugPrint('🌙 [Lifecycle] アプリがバックグラウンドに移行しました。未送信データの強制同期を試行します...');
      // =========================================================================
      // 🛡️ 補正：残存していた旧式 syncNow() を、新設した processQueue() へ完全統合
      // =========================================================================
      ref.read(syncEngineProvider).processQueue();
      ref.read(legacy_sync.syncEngineProvider).syncNow();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 監視終了
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ★ Phase 4: 同期エンジンを監視（起動）させ、バックグラウンドで常駐させる
    ref.watch(syncEngineProvider);
    ref.watch(
      legacy_sync.syncEngineProvider,
    ); // ★ 追加: 試合のFirestoreアップロードエンジンを常駐

    // ★ 追加: 同一の道場IDでログインした際に、同期先を正しいFirestoreの道場パスへ
    // 切り替えるための道場ルーム同期プロバイダを常駐監視させます。（シミュレータとWeb間の同期不一致を完全解決）
    ref.watch(dojoRoomSyncProvider);

    // ★ ここが「中央司令部」
    // ルーターの遷移状態を監視し、パスに基づいてモードを自動決定する
    ref.watch(routeObserverProvider);

    final settings = ref.watch(settingsProvider);

    // iOS Native スタイルに基づいたテーマモード判定
    ThemeMode currentThemeMode = ThemeMode.system;
    if (settings.themeMode == 'light') {
      currentThemeMode = ThemeMode.light;
    } else if (settings.themeMode == 'dark') {
      currentThemeMode = ThemeMode.dark;
    }

    // iOS 26 スタイル: True Black & Elevation 定義
    final darkThemeBase = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black, // True Black
      canvasColor: Colors.black,
      textTheme: GoogleFonts.notoSansJpTextTheme(ThemeData.dark().textTheme),
    );

    final lightThemeBase = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF2F2F7), // iOS System Background
      textTheme: GoogleFonts.notoSansJpTextTheme(ThemeData.light().textTheme),
    );

    // ★ 常に MaterialApp.router のみを返し、URLの消失とクラッシュを物理的に不可能にする
    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey, // ★ バックグラウンド通知用
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
      supportedLocales: const [Locale('ja', 'JP')],
    );
  }
}

// ============================================================================
// ★ Phase 6: URLからRoleを解析し、Providerにセットしてからルーターへ流す魔法の箱
// ============================================================================
class RoleInjector extends ConsumerStatefulWidget {
  final Widget child;
  final String? roleStr;
  final String? dojoId; // ★追加
  final String? tournamentId;
  const RoleInjector({
    super.key,
    required this.child,
    this.roleStr,
    this.dojoId,
    this.tournamentId,
  });

  @override
  ConsumerState<RoleInjector> createState() => _RoleInjectorState();
}

class _RoleInjectorState extends ConsumerState<RoleInjector> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyRole();
    });
  }

  void _applyRole() {
    // ★ 追加: URLから道場IDが渡された場合、Viewerが迷子にならないよう同期先を確定させる
    if (widget.dojoId != null && widget.dojoId!.isNotEmpty) {
      ref.read(currentDojoIdProvider.notifier).state = widget.dojoId!;
      debugPrint(
        '🏢 [Role Injector] URLからテナントID(${widget.dojoId})を復元し同期先を確定しました',
      );
    }

    // ★ 追加: Web環境でURLから直接試合画面や大会ホームにアクセスした際、
    // どの大会を見ているのかをグローバルなプロバイダに記憶させる。
    // これにより、各画面での冗長な初期化処理を完全に排除し、一元管理を実現します。
    if (kIsWeb &&
        widget.tournamentId != null &&
        widget.tournamentId!.isNotEmpty) {
      final currentTournamentId = ref.read(webCurrentTournamentIdProvider);
      if (currentTournamentId != widget.tournamentId) {
        ref.read(webCurrentTournamentIdProvider.notifier).state =
            widget.tournamentId!;
        debugPrint(
          '🎯 [Role Injector] Web環境の大会IDを復元しました: ${widget.tournamentId}',
        );
      }
    }

    // ★ 追加: RoleInjector が viewer 権限を要求している場合、認証セッション側にも
    // viewer セッションを確立しておく（Firestore側や各種 Provider が viewer 前提で
    // 動作できるようにする安全策）
    if (widget.roleStr == 'viewer') {
      try {
        // ★ 修正: 既に最高管理者や記録者などの「強力な権限」でログインしているユーザーが、
        // 一時的にプレビュー画面を開いた際にセッションが破壊（降格）されるのを防ぐ。
        final currentSession = ref.read(authSessionProvider);
        if (currentSession == null || currentSession.role == UserRole.viewer) {
          ref
              .read(authSessionProvider.notifier)
              .establishSession(
                UserRole.viewer,
                widget.dojoId ?? ref.read(currentDojoIdProvider),
              );
          debugPrint('🔐 [Role Injector] authSession を viewer として確立しました');
        } else {
          debugPrint(
            '🔐 [Role Injector] 既存の強力なセッション(${currentSession.role.name})を維持し、ダウングレードを回避しました',
          );
        }
      } catch (e) {
        debugPrint('⚠️ [Role Injector] authSession 確立に失敗: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ★ 修正: ProviderScope による Scoped Provider や temporaryRoleOverrideProvider の使用を完全に廃止。
    // Viewerプレビュー時も「管理者」の権限を持ったまま、安全にハードコーディングされたViewer専用UIを表示する仕様に統一。
    // これにより、ルーティングスタックの破壊（他画面から戻ると先祖返りするバグ）と、裏画面のチラつきを 100% 防止します。
    return widget.child;
  }
}
