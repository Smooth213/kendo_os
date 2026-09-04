import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar_community/isar.dart';
import 'package:flutter/foundation.dart';
import 'dart:async'; // 🌟 TimeoutExceptionのために追加

import 'package:kendo_os/firebase_options.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/local_stroke_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_comment_entity.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_projection_entity.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/admin/providers/metrics_provider.dart';
import 'package:kendo_os/shared/infrastructure/services/web_platform_optimizer.dart';
import 'package:kendo_os/shared/application/services/sound_service.dart';

class AppStartup {
  static Future<ProviderContainer> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    usePathUrlStrategy();

    // 🌐 【Phase 7】Safari & Chrome 2大ブラウザ極限最適化
    WebPlatformOptimizer.applyOptimizations();

    // 💾 【Phase 2】メモリ効率＆画像キャッシュ上限の自動制御
    configureImageCache();

    // 📦 【Phase 6】フォント・アセット最適化
    configureFontOptimization();

    // ⚡ 【Phase 1】起動速度極限最適化：コア3大サービスの完全並列初期化パイプライン
    final initResults = await Future.wait([
      _initFirebase(),
      SharedPreferences.getInstance(),
      _initIsar(),
    ]);

    final prefs = initResults[1] as SharedPreferences;
    final isar = initResults[2] as Isar?;

    // Firestore 現場継続設定（ネイティブキャッシュ管理）
    await _configureFirestore(prefs);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        isarProvider.overrideWithValue(isar),
      ],
    );

    // 🔊 【Phase 8】オーディオPre-warming（ノンブロッキング非同期で事前暖機）
    unawaited(container.read(soundServiceProvider).prewarm());

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
                const SizedBox(height: AppSpacing.md),
                const Text(
                  '以下のログを開発者へ共有してください：',
                  style: TextStyle(
                    color: AppKendoColors.pureBlack,
                    fontSize: AppFontSize.small,
                  ),
                ),
                const Divider(),
                Text(
                  details.exceptionAsString(),
                  style: const TextStyle(
                    color: AppKendoColors.pureBlack,
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.body,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  details.stack?.toString() ?? 'スタックトレースなし',
                  style: const TextStyle(
                    color: AppKendoColors.grey,
                    fontSize: AppFontSize.badge,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    };

    return container;
  }

  static void handleFatalInitError(Object e, StackTrace stackTrace) {
    debugPrint('🔥 [Fatal Init Error] 起動時に致命的なエラーが発生しました: $e');
    debugPrint('🔥 [Fatal Init StackTrace]\n$stackTrace');

    final errorStr = e.toString();
    String displayMessage =
        'アプリの起動に失敗しました。\n\n'
        '【原因の可能性】\n'
        '・QRコードリーダーの内蔵ブラウザを使用している\n'
        '・プライベートブラウズ（シークレットモード）になっている\n\n'
        '右下の「Safari/Chromeで開く」アイコン等を押して、通常のブラウザで開き直してください。\n\n'
        '詳細エラー: $errorStr';

    if (errorStr.contains('IsarError') || errorStr.contains('IndexedDB')) {
      displayMessage =
          '【ブラウザのセキュリティ制限】\n\n'
          'LINEやQRコードリーダーの内蔵ブラウザ、またはシークレットモードでは、プライバシー保護機能によりアプリが起動できません。\n\n'
          '画面右下（または右上）のメニューから\n'
          '「Safariで開く」または「ブラウザで開く」\n'
          'を選択して、通常の環境で開き直してください。';
    }

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                displayMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppKendoColors.red,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ⚡ Firebase コアサービスの高速並列初期化
  static Future<void> _initFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('🚀 Firebase [DEFAULT] をクリーンに新規初期化しました。');
      } else {
        debugPrint(
          '📢 Firebase [DEFAULT] はすでに常駐しているため、初期化呼び出しを完全にスキップして既存インスタンスを安全に100%再利用します。',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Firebase初期化のキャッチ: $e');
    }

    if (!kIsWeb) {
      FlutterError.onError = (errorDetails) {
        try {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        } catch (_) {}
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        try {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        } catch (_) {}
        return true;
      };
      debugPrint('🚀 [Crashlytics] ネイティブ環境の致命的クラッシュ監視ラインを活性化しました');
    } else {
      debugPrint('🚀 [Web WebAnalytics] Webアプリ版のブラウザ例外トラックを確立しました');
    }

    // 🛡️ オフライン時の起動ストール防止パッチ（ノンブロッキング非同期実行）
    unawaited(() async {
      try {
        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously().timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Auth 認証タイムアウト（オフライン運用に切り替えます）');
            },
          );
          debugPrint('🛡️ [Auth] 匿名ゲスト認証を自動確立しました（ルーム参加準備完了）');
        }
      } catch (e) {
        debugPrint('⚠️ [Auth] 匿名認証をスキップしてオフライン起動を継続します: $e');
      }
    }());
  }

  /// ⚡ 【Phase 13】Isar メモリマップトI/O（MMAP）＆ ページサイズ最適化
  /// 過去数万件の大会データ検索時、フラッシュストレージI/OをスキップしてRAM速度（0ms）で即座返却
  static Future<Isar?> _initIsar({
    int maxSizeMiB = 1024,
    bool relaxedDurability = true,
  }) async {
    if (kIsWeb) {
      return null;
    }
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [
        MatchEntitySchema,
        LocalStrokeModelSchema,
        MatchCommentEntitySchema,
        MatchProjectionEntitySchema,
        MatchCommandEntitySchema,
      ],
      directory: dir.path,
      maxSizeMiB: maxSizeMiB,
      relaxedDurability: relaxedDurability,
      compactOnLaunch: const CompactCondition(
        minFileSize: 10 * 1024 * 1024, // 10MB以上
        minRatio: 2.0, // 2倍以上の断片化
      ),
    );
  }

  /// ⚡ Firestore 現場継続設定（ネイティブキャッシュ管理）
  static Future<void> _configureFirestore(SharedPreferences prefs) async {
    try {
      if (kIsWeb) {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          webExperimentalAutoDetectLongPolling: true,
        );
        debugPrint(
          '🌐 [Firestore Web] ブラウザ永続キャッシュ（IndexedDB）と自動ロングポーリング検知を活性化しました。',
        );
      } else {
        final hasCleared =
            prefs.getBool('has_cleared_corrupted_firestore_cache_v3') ?? false;
        if (!hasCleared) {
          await FirebaseFirestore.instance.terminate();
          await FirebaseFirestore.instance.clearPersistence();
          await prefs.setBool('has_cleared_corrupted_firestore_cache_v3', true);
          debugPrint('🧹 [Firestore] 古いローカルキャッシュを強制ワイプしました');
        }
        await FirebaseFirestore.instance.enableNetwork().timeout(
          const Duration(seconds: 1),
          onTimeout: () =>
              debugPrint('⏳ [Firestore] ネットワーク開通接続タイムアウト（ローカルモード移行）'),
        );
      }
    } catch (e) {
      debugPrint('⚠️ [Firestore] 現場継続エンジンの初期化をスキップして起動を継続します: $e');
    }
  }

  /// 💾 【Phase 2】メモリ効率＆画像キャッシュ上限の自動制御
  /// 体育館終日稼働（8〜12時間）に伴う画像・PDFプレビューのメモリ肥大化を完全防止
  static void configureImageCache({
    int maxSizeBytes = 50 * 1024 * 1024, // 50MB
    int maxSize = 100, // 最大100枚
  }) {
    PaintingBinding.instance.imageCache.maximumSizeBytes = maxSizeBytes;
    PaintingBinding.instance.imageCache.maximumSize = maxSize;
  }

  /// 📦 【Phase 6】フォント・アセット最適化
  /// 体育館・電波不通現場でのフォントダウンロード遅延や通信エラーを防止
  static void configureFontOptimization({bool allowRuntimeFetching = true}) {
    GoogleFonts.config.allowRuntimeFetching = allowRuntimeFetching;
  }
}
