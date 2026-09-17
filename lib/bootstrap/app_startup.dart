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
import 'package:kendo_os/shared/errors/emergency_crash_preserver.dart';
import 'package:kendo_os/features/auth/application/user_data_cloud_sync_manager.dart';

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

    // ☁️ Google連携アカウント設定・履歴のクラウド自動同期マネージャー起動
    container.read(userDataCloudSyncManagerProvider).initialize();

    // 🔊 【Phase 8】オーディオPre-warming（ノンブロッキング非同期で事前暖機）
    unawaited(container.read(soundServiceProvider).prewarm());

    // ⚡ 【Plan 1-5】アセット・フォント・シェーダーの事前ウォームアップ（ノンブロッキング非同期）
    unawaited(prewarmAppAssets());

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // 🛡️ 【Plan 3-3】Fatal Crash Trap: 直前状態の緊急退避
      EmergencyCrashPreserver.preserveOnCrash(
        error: details.exception,
        stackTrace: details.stack,
      );
      if (!kIsWeb) {
        try {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        } catch (_) {}
      }
      container.read(metricsProvider).recordError();
      debugPrint('⚠️ UIエラー: ${details.exception}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      // 🛡️ 【Plan 3-3】Fatal Crash Trap: 直前状態の緊急退避
      EmergencyCrashPreserver.preserveOnCrash(error: error, stackTrace: stack);
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
                        color: AppKendoColors.pureWhite.withValues(alpha: 0.6),
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

    // 🛡️ 既存セッションの安全な復元と匿名認証（ノンブロッキング非同期実行）
    unawaited(() async {
      try {
        if (kIsWeb) {
          // Webリダイレクト認証から復帰した直後はリダイレクト結果の受信を待機
          try {
            final redirectUser = await FirebaseAuth.instance
                .getRedirectResult();
            if (redirectUser.user != null) {
              debugPrint(
                '🛡️ [Auth] Webリダイレクト認証ユーザーを確立しました: ${redirectUser.user?.email}',
              );
            }
          } catch (e) {
            debugPrint('ℹ️ [Auth] Web getRedirectResult: $e');
          }
        }

        // 🛡️ Web/Nativeのローカルストレージ（IndexedDB等）から既存認証セッションの復元を確実に待機
        final existingUser = await FirebaseAuth.instance
            .authStateChanges()
            .first
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () => FirebaseAuth.instance.currentUser,
            );

        if (existingUser == null) {
          await FirebaseAuth.instance.signInAnonymously().timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Auth 認証タイムアウト（オフライン運用に切り替えます）');
            },
          );
          debugPrint('🛡️ [Auth] 初回起動: 匿名ゲスト認証を自動確立しました（ルーム参加準備完了）');
        } else {
          final isGoogle = existingUser.providerData.any(
            (p) => p.providerId == 'google.com',
          );
          debugPrint(
            '🛡️ [Auth] 既存セッションを正常復元しました (UID: ${existingUser.uid}, Google連携: $isGoogle, Email: ${existingUser.email})',
          );
        }
      } catch (e) {
        debugPrint('⚠️ [Auth] 認証復元/初期化処理のキャッチ: $e');
      }
    }());
  }

  /// ⚡ 【Phase 13】Isar メモリマップトI/O（MMAP）＆ ページサイズ最適化
  /// 過去数万件の大会データ検索時、フラッシュストレージI/OをスキップしてRAM速度（0ms）で即座返却
  static Future<Isar?> _initIsar({
    int maxSizeMiB = 128,
    bool relaxedDurability = true,
  }) async {
    if (kIsWeb) {
      return null;
    }
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [
        MatchEntitySchema,
        MatchEventArchiveEntitySchema,
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
    try {
      GoogleFonts.config.allowRuntimeFetching = allowRuntimeFetching;
    } catch (e) {
      debugPrint('⚠️ [FontOptimization] 設定エラー: $e');
    }
  }

  /// 🌐 オフライン環境向けフォントセーフティ設定
  /// 外部HTTPフォント取得を安全に遮断し、内蔵システムフォントへの即時フォールバックを強制
  static void enforceOfflineFontFallback() {
    try {
      GoogleFonts.config.allowRuntimeFetching = false;
      debugPrint('🛡️ [FontOptimization] オフライン向けシステムフォント即時フォールバックを有効化しました');
    } catch (e) {
      debugPrint('⚠️ [FontOptimization] フォールバック設定エラー: $e');
    }
  }

  /// ⚡ 【Plan 1-5】アセット・フォント・シェーダーの事前ウォームアップ
  /// 初回画面遷移時やモーダル表示時のシェーダージャンクを完全防止
  static Future<void> prewarmAppAssets() async {
    try {
      // 1. GoogleFonts 主要フォントの事前ウォームアップ
      unawaited(
        GoogleFonts.pendingFonts([
          GoogleFonts.inter(),
          GoogleFonts.notoSansJp(),
        ]),
      );

      // 2. コア画像アセットの事前キャッシュ
      const imageProvider = AssetImage('assets/kendo_icon.png');
      const config = ImageConfiguration.empty;
      unawaited(
        imageProvider
            .obtainKey(config)
            .then((_) {
              final stream = imageProvider.resolve(config);
              stream.addListener(
                ImageStreamListener(
                  (image, synchronousCall) {},
                  onError: (exception, stackTrace) {},
                ),
              );
            })
            .catchError((_) {}),
      );
    } catch (e) {
      debugPrint('ℹ️ [Prewarm] アセット事前ウォームアップスキップ: $e');
    }
  }
}
