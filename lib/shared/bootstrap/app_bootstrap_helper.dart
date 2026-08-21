import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:kendo_os/firebase_options.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/local_stroke_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_comment_entity.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_projection_entity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

final globalConnectivityProvider = StreamProvider.autoDispose<bool>((ref) {
  final controller = StreamController<bool>();

  Connectivity().checkConnectivity().then((result) {
    if (!controller.isClosed) {
      controller.add(result.contains(ConnectivityResult.none));
    }
  });

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

/// アプリ起動時初期化ヘルパー
class AppBootstrapHelper {
  static Future<({SharedPreferences prefs, Isar? isar})> initialize() async {
    SharedPreferences? prefs;
    Isar? isar;

    Future<void> run() async {
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
        }
      } catch (e) {
        debugPrint('⚠️ Firebase初期化のキャッチ: $e');
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
        run().catchError((_) {}),
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

    return (prefs: prefs ?? await SharedPreferences.getInstance(), isar: isar);
  }
}
