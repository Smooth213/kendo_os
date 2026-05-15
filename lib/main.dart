import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // ★ Phase 9-3: インポート追加
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar_community/isar.dart';
import 'dart:ui'; 
import 'package:flutter/foundation.dart'; 
import 'package:flutter_web_plugins/url_strategy.dart'; // ★ 追加: URLの#を消すためのプラグイン

import 'firebase_options.dart';
import 'presentation/operate/screens/team_registration_screen.dart'; 
import 'presentation/operate/screens/start_screen.dart';
import 'presentation/operate/screens/home_screen.dart';
import 'presentation/operate/screens/program_management_screen.dart';
import 'presentation/operate/screens/program_viewer_screen.dart';
import 'domain/entities/program_model.dart';
import 'presentation/operate/screens/tournament_list_screen.dart'; 
import 'presentation/match_router.dart'; // ★ Phase 5: ルーターを追加
import 'presentation/viewer/screens/viewer_match_screen.dart';
// ==========================================
// ★ Phase 6: Stage 2 限定化
// リリース版に不要な高度機能(内部監査等)を物理的に切断(パージ)します。
// ==========================================
import 'presentation/operate/screens/master_management_screen.dart'; // ★ 復旧: マスタ画面へのインポートを再開通
// import 'presentation/operate/screens/audit_log_screen.dart'; 
// import 'presentation/operate/screens/observability_dashboard_screen.dart'; 
import 'presentation/operate/screens/create_tournament_screen.dart';
import 'presentation/operate/screens/setup_match_format_screen.dart';
import 'presentation/operate/screens/order_setup_screen.dart'; 
import 'presentation/operate/screens/team_scoreboard_screen.dart'; 
import 'presentation/operate/screens/kachinuki_scoreboard_screen.dart'; // ★ Phase 6: 勝ち抜き戦のルーティング用に追加
import 'presentation/operate/screens/login_screen.dart'; // ★ 復旧: Zero Trust Routerで再び使用
import 'presentation/operate/screens/settings_screen.dart'; 
import 'presentation/operate/screens/standings_screen.dart'; // ★ 追加: Phase 8-3 自チーム成績画面
import 'presentation/operate/screens/official_record_screen.dart'; // ★ 追加: Phase 8-3 出力用スコア画面
import 'presentation/operate/providers/auth_provider.dart';
import 'presentation/operate/providers/settings_provider.dart'; 
import 'presentation/operate/providers/sync_provider.dart'; 
import 'infrastructure/persistence/models/match_entity.dart';
import 'infrastructure/repository/local_match_repository.dart';
import 'infrastructure/persistence/models/local_stroke_model.dart'; // ★ これを追加
import 'presentation/operate/screens/bunaiksen_home_screen.dart';
import 'presentation/operate/screens/bunaiksen_setup_screen.dart';
import 'presentation/operate/screens/bunaiksen_official_record_screen.dart';
import 'presentation/viewer/screens/viewer_home_screen.dart';
import 'presentation/viewer/screens/viewer_official_record_screen.dart';
import 'presentation/viewer/screens/viewer_team_scoreboard_screen.dart';
import 'presentation/viewer/screens/viewer_kachinuki_scoreboard_screen.dart';
import 'presentation/viewer/screens/viewer_bunaiksen_home_screen.dart';
import 'presentation/viewer/screens/viewer_bunaiksen_official_record_screen.dart';

import 'presentation/operate/providers/role_provider.dart';
import 'presentation/operate/providers/metrics_provider.dart'; // ★ 追加: グローバルエラーをメトリクスへ流す

// ★ 追加: 画面のNavigatorをどこからでも取得するためのグローバルキー
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

// ★ Step 5-2: アプリ全体でバックグラウンド通知を表示するための「どこでもドア」キー
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  // Flutterのエンジンを初期化（非同期処理を行う前に必須）
  WidgetsFlutterBinding.ensureInitialized();
  
  // ★ URLパスから「#」を取り除き、Webのディープリンクを正常に処理させる（ホワイトアウト対策1）
  usePathUrlStrategy();
  
  try {
    // Firebaseの初期化
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // ★ 修正：SharedPreferences のインスタンスをここで確実に取得する
    final prefs = await SharedPreferences.getInstance();

    // ★ Phase 1-4: Isar（ローカルDB）の起動
    Isar? isar;
    if (kIsWeb) {
      // ★ 修正: Isarのv3系はWeb環境を公式サポートしていないため、
      // Webアクセス時（ブラウザ）はIsarを初期化せずnullとし、Viewer(観客)専用として動作させます。
      isar = null;
    } else {
      // ★ iOS/Android環境の場合：従来通り端末内のDocumentsフォルダを取得
      final dir = await getApplicationDocumentsDirectory();
      isar = await Isar.open(
        [
          MatchEntitySchema,
          MatchCommandEntitySchema, 
          LocalStrokeModelSchema, 
        ],
        directory: dir.path,
      );
    }

    // ★ Phase 2-4: ProviderContainer を自前で作成し、システム全体からアクセス可能にする
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // ★ 修正: Web環境で isar が null の場合でも正しくオーバーライドし、UnimplementedErrorを防ぐ
        isarProvider.overrideWithValue(isar),
      ],
    );

    // ★ 1. 描画やUI関連のエラーをキャッチしてフリーズを防ぐ
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details); // ★ Phase 9-3: 致命的なUIエラーをFirebaseへ送信
      container.read(metricsProvider).recordError(); // ★ UIエラーをメトリクスのエラー率に加算
      debugPrint('⚠️ UIエラー: ${details.exception}');
    };

    // ★ 2. 非同期処理や裏側のエラーをキャッチしてアプリのクラッシュを防ぐ
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true); // ★ Phase 9-3: 裏側のクラッシュもFirebaseへ送信
      container.read(metricsProvider).recordError(); // ★ 裏側エラーをメトリクスのエラー率に加算
      debugPrint('⚠️ 裏側エラー: $error');
      return true; 
    };

    // ★ 3. 恐ろしい「赤いエラー画面（本番は真っ白）」を最強のデバッガー（X線画面）に進化させる
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️ UIレンダリング・エラー発生', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                const Text('以下のログを開発者へ共有してください：', style: TextStyle(color: Colors.black87, fontSize: 12)),
                const Divider(),
                Text(
                  details.exceptionAsString(),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
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
    String displayMessage = 'アプリの起動に失敗しました。\n\n'
        '【原因の可能性】\n'
        '・QRコードリーダーの内蔵ブラウザを使用している\n'
        '・プライベートブラウズ（シークレットモード）になっている\n\n'
        '右下の「Safari/Chromeで開く」アイコン等を押して、通常のブラウザで開き直してください。\n\n'
        '詳細エラー: $errorStr';

    // データベース制限（アプリ内ブラウザ等）の場合、英語のエラー文を隠して優しい案内に差し替え
    if (errorStr.contains('IsarError') || errorStr.contains('IndexedDB')) {
      displayMessage = '【ブラウザのセキュリティ制限】\n\n'
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
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ),
      ),
    );
    return; // 処理を終了
  }
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
    return authState.when(
      data: (user) {
        // 未ログインなら、要求された画面の「代わりに」ログイン画面をそのまま表示する
        if (user == null) return const LoginScreen(); 
        return child;
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('エラー: $e'))),
    );
  }
}

// ==========================================
// ★ 静的ルーター（クラッシュとURL消失を完全防止）
// ==========================================
final _router = GoRouter(
    navigatorKey: rootNavigatorKey, // ★ 追加: ルーターキーを登録
    initialLocation: '/',
    // ★ 存在しないURLやルーティングエラー時に真っ白になるのを防ぐ（ホワイトアウト対策3）
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('ページが見つかりません: ${state.uri}\nURLが間違っているか、削除された可能性があります。', textAlign: TextAlign.center),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/',
        // ★ 管理者ホームは AuthGuard で守る（未ログインならURLは/のままLoginScreenが出る）
        builder: (context, state) => const AuthGuard(child: StartScreen()),
      ),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()), // ★ Phase 2: 設定画面へのルート
      
      // ==========================================
      // ★ Phase 6: Stage 2 限定化 (ルーティングの切断)
      // ==========================================
      // GoRoute(path: '/audit-log', builder: (context, state) => const AuditLogScreen()), 
      // GoRoute(path: '/dashboard', builder: (context, state) => const ObservabilityDashboardScreen()), 
      
      // ★ 復旧: 選手マスタ管理画面へのルートを再開通
      GoRoute(path: '/master', builder: (context, state) => const MasterManagementScreen()),
      
      GoRoute(
        path: '/tournament-list', 
        builder: (context, state) {
          // extra からアーカイブモードかどうかを受け取る（デフォルトは false）
          final isArchive = state.extra as bool? ?? false;
          return TournamentListScreen(isArchive: isArchive);
        }
      ),
      GoRoute(
        path: '/viewer/:id',
        builder: (context, state) => ViewerMatchScreen(matchId: state.pathParameters['id']!),
      ),
      // ★ Phase 6: 全ての共有可能画面を RoleInjector で包み、URLからViewer権限を適用できるようにする
      GoRoute(
        path: '/home/:tournamentId', 
        builder: (context, state) => RoleInjector(roleStr: state.uri.queryParameters['role'], child: HomeScreen(tournamentId: state.pathParameters['tournamentId']!))
      ),
      GoRoute(
        path: '/tournament/:id/programs',
        builder: (context, state) => ProgramManagementScreen(tournamentId: state.pathParameters['id']!),
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
        builder: (context, state) => RoleInjector(roleStr: state.uri.queryParameters['role'], child: MatchRouter(matchId: state.pathParameters['id']!))
      ),
      GoRoute(
        path: '/team-scoreboard/:groupName',
        builder: (context, state) => RoleInjector(roleStr: state.uri.queryParameters['role'], child: TeamScoreboardScreen(groupName: state.pathParameters['groupName']!))
      ),
      GoRoute(
        path: '/viewer-home/:tournamentId',
        builder: (context, state) => RoleInjector(
          roleStr: state.uri.queryParameters['role'], 
          child: ViewerHomeScreen(tournamentId: state.pathParameters['tournamentId']!)
        ),
      ),
      GoRoute(
        path: '/viewer-record/:tournamentId',
        builder: (context, state) => RoleInjector(
          roleStr: state.uri.queryParameters['role'], 
          child: ViewerOfficialRecordScreen(tournamentId: state.pathParameters['tournamentId']!)
        ),
      ),
      GoRoute(
        path: '/viewer-team/:groupName',
        builder: (context, state) => RoleInjector(
          roleStr: state.uri.queryParameters['role'], 
          child: ViewerTeamScoreboardScreen(groupName: state.pathParameters['groupName']!)
        ),
      ),
      GoRoute(
        path: '/viewer-kachinuki/:groupName',
        builder: (context, state) => RoleInjector(
          roleStr: state.uri.queryParameters['role'], 
          child: ViewerKachinukiScoreboardScreen(groupName: state.pathParameters['groupName']!)
        ),
      ),
      GoRoute(
        path: '/kachinuki-scoreboard/:groupName',
        builder: (context, state) => RoleInjector(roleStr: state.uri.queryParameters['role'], child: KachinukiScoreboardScreen(groupName: state.pathParameters['groupName']!))
      ),
  
      GoRoute(path: '/create-tournament', builder: (context, state) => const CreateTournamentScreen()),
      GoRoute(path: '/setup-match/:id', builder: (context, state) => SetupMatchFormatScreen(tournamentId: state.pathParameters['id']!)),
      GoRoute(
        path: '/order-setup/:id',
        builder: (context, state) => OrderSetupScreen(tournamentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/team-registration/:id',
        builder: (context, state) => TeamRegistrationScreen(tournamentId: state.pathParameters['id']!),
      ),
      // ★ Phase 8-3: 自チーム成績と出力用スコアのルーター設定を追加
      GoRoute(
        path: '/standings/:id',
        builder: (context, state) => StandingsScreen(tournamentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/official-record/:id',
        builder: (context, state) => OfficialRecordScreen(tournamentId: state.pathParameters['id']!),
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
          child: ViewerBunaiksenHomeScreen(tournamentId: state.pathParameters['tournamentId']!),
        ),
      ),
      GoRoute(
        path: '/bunaiksen-viewer-record/:tournamentId',
        builder: (context, state) => RoleInjector(
          roleStr: 'viewer', // ★強制的にViewer権限にダウングレード
          child: ViewerBunaiksenOfficialRecordScreen(tournamentId: state.pathParameters['tournamentId']!),
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
class _KendoOSAppState extends ConsumerState<KendoOSApp> with WidgetsBindingObserver {

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
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      debugPrint('🌙 [Lifecycle] アプリがバックグラウンドに移行しました。未送信データの強制同期を試行します...');
      // SyncEngineの syncNow() を呼び出して残った仕事を終わらせる
      ref.read(syncEngineProvider).syncNow();
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
        GlobalCupertinoLocalizations.delegate
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
  const RoleInjector({super.key, required this.child, this.roleStr});

  @override
  ConsumerState<RoleInjector> createState() => _RoleInjectorState();
}

class _RoleInjectorState extends ConsumerState<RoleInjector> {
  bool _isReady = false;
  late final ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    // ★ 初期化時にコンテナを安全に確保しておく（破棄時の復元用）
    _container = ProviderScope.containerOf(context, listen: false);
    _applyRole();
  }

  void _applyRole() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetRole = widget.roleStr == 'viewer' ? Role.viewer : null;
      final currentRole = ref.read(temporaryRoleOverrideProvider);

      if (currentRole != targetRole) {
        ref.read(temporaryRoleOverrideProvider.notifier).state = targetRole;
        debugPrint('🎭 [Role Injector] 権限を同期的に切り替えました: ${targetRole?.label ?? "通常モード"}');
      }
      setState(() {
        _isReady = true;
      });
    });
  }

  @override
  void dispose() {
    // ★ 画面が閉じられた時（戻るボタン等）、自分がViewer権限にしていたなら通常モード(null)に戻す
    final wasViewer = widget.roleStr == 'viewer';
    if (wasViewer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _container.read(temporaryRoleOverrideProvider.notifier).state = null;
        debugPrint('🎭 [Role Injector] 権限を 通常モード に安全に復元しました');
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ★ 真犯人対策：ref.watch を使わないことで、裏画面との状態の奪い合い（無限ループ）を物理的に遮断
    if (!_isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.child;
  }
}