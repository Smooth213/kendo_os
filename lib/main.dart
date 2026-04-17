import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/team_registration_screen.dart'; // ★ 追加：チーム登録画面
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/start_screen.dart';
import 'screens/home_screen.dart';
import 'screens/tournament_list_screen.dart'; // ★ 新しい画面を読み込む！
import 'screens/match_screen.dart';
import 'screens/master_management_screen.dart';
import 'screens/create_tournament_screen.dart';
import 'screens/setup_match_format_screen.dart';
import 'screens/order_setup_screen.dart'; 
import 'screens/team_scoreboard_screen.dart'; // ★ これだけでOK！
import 'screens/login_screen.dart'; // ★ 追加：ログイン画面を読み込む
import 'package:shared_preferences/shared_preferences.dart'; // ★ Phase 1: 設定保存用
import 'screens/settings_screen.dart'; // ★ Phase 2: 設定画面を読み込む

import 'providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // ★ 追加：エラーキャッチの仕組みを使うための部品
import 'package:flutter/foundation.dart'; // ★ 追加：裏側にエラーログを残すための部品
import 'providers/settings_provider.dart'; // ★ Phase 1: プロバイダーの読み込み
import 'package:path_provider/path_provider.dart';
import 'package:isar_community/isar.dart';
import 'models/local/match_entity.dart';
import 'repositories/local_match_repository.dart';

void main() async {
  // Flutterのエンジンを初期化（非同期処理を行う前に必須）
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebaseの初期化
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ★ 修正：SharedPreferences のインスタンスをここで確実に取得する
  final prefs = await SharedPreferences.getInstance();

  // ★ Phase 1-4: Isar（ローカルDB）の起動
  // 端末内の安全な保存場所を取得し、そこにデータベースファイルを作成・展開します
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [MatchEntitySchema], // Step 1-2 で自動生成されたテーブル設計図
    directory: dir.path,
  );

  // ★ 1. 描画やUI関連のエラーをキャッチしてフリーズを防ぐ
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('⚠️ UIエラー: ${details.exception}');
  };

  // ★ 2. 非同期処理や裏側のエラーをキャッチしてアプリのクラッシュを防ぐ
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('⚠️ 裏側エラー: $error');
    return true; 
  };

  // ★ 3. 恐ろしい「赤いエラー画面（本番は真っ白）」を優しい画面に差し替える
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '予期せぬエラーが発生しました。\n左上の「戻る」ボタンを押すか、アプリを再起動してください。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  };

  // ProviderScopeに確実に読み込み済みの prefs と isar を注入してアプリを起動！
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        isarProvider.overrideWithValue(isar), // ★ アプリ全体にローカル金庫の鍵を渡す
      ],
      child: const KendoOSApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const StartScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()), // ★ Phase 2: 設定画面へのルート
    GoRoute(
      path: '/tournament-list', 
      builder: (context, state) {
        // extra からアーカイブモードかどうかを受け取る（デフォルトは false）
        final isArchive = state.extra as bool? ?? false;
        return TournamentListScreen(isArchive: isArchive);
      }
    ),
    // ★ 大会IDを受け取る専用のホーム画面に変更！
    GoRoute(path: '/home/:tournamentId', builder: (context, state) => HomeScreen(tournamentId: state.pathParameters['tournamentId']!)),
    GoRoute(path: '/match/:id', builder: (context, state) => MatchScreen(matchId: state.pathParameters['id']!)),
    GoRoute(path: '/master', builder: (context, state) => const MasterManagementScreen()),
    GoRoute(path: '/create-tournament', builder: (context, state) => const CreateTournamentScreen()),
    GoRoute(path: '/setup-match/:id', builder: (context, state) => SetupMatchFormatScreen(tournamentId: state.pathParameters['id']!)),
    
    GoRoute(
      path: '/order-setup/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        // ★ バケツリレー（extra）を完全に廃止し、大会IDだけを渡す！
        return OrderSetupScreen(tournamentId: id); 
      },
    ),
    GoRoute(
      path: '/team-registration/:id',
      builder: (context, state) => TeamRegistrationScreen(tournamentId: state.pathParameters['id']!),
    ),

    GoRoute(
      path: '/team-scoreboard/:groupName',
      builder: (context, state) => TeamScoreboardScreen(groupName: state.pathParameters['groupName']!),
    ),
  ],
);

class KendoOSApp extends ConsumerWidget {
  const KendoOSApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
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

    return authState.when(
      data: (user) {
        if (user == null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: currentThemeMode,
            theme: lightThemeBase,
            darkTheme: darkThemeBase,
            home: const LoginScreen(),
          );
        }

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
          supportedLocales: const [Locale('ja', 'JP')],
          themeMode: currentThemeMode,
          
          // 【iOS Native Light Theme】
          theme: lightThemeBase.copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.light,
              surface: const Color(0xFFF2F2F7),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.indigo),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          
          // 【iOS Native Dark Theme (True Black)】
          darkTheme: darkThemeBase.copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.dark,
              surface: Colors.black,
              onSurface: Colors.white,
              // iOS Elevation: 背景(Black)に対してカードは #1C1C1E
              surfaceContainerLowest: const Color(0xFF1C1C1E), 
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1C1C1E), // Elevationグレー
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            // DividerもiOS風に細く暗く
            dividerTheme: const DividerThemeData(color: Color(0xFF38383A), thickness: 0.5),
          ),
          routerConfig: _router,
        );
      },
      loading: () => const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator()))),
      error: (err, stack) => MaterialApp(home: Scaffold(body: Center(child: Text('エラー: $err')))),
    );
  }
}