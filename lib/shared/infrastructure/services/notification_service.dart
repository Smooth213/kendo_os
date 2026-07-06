import 'package:kendo_os/shared/infrastructure/services/web_notification_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart'; // firestoreProvider
import 'package:firebase_core/firebase_core.dart';

/// 🌟 アプリがバックグラウンドや完全に閉じている時にFCMを受信した際のトップレベルハンドラ
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // バックグラウンド時は完全にOS管理下となるため、最低限のパケット解析ログのみを残します
  debugPrint('🛡️ [NotificationService] バックグラウンドFCMを受信: ${message.messageId}');
}

class NotificationService {
  final Ref _ref;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  /// 🌟 通知インフラ（FCM & ローカル通知）の初期化とリスナー開始
  Future<void> initializeNotification() async {
    try {
      if (kIsWeb) {
        // Web環境（Chrome/Safari）での通知パーミッション要求
        triggerWebNotificationPermission();
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        _setupFcmListeners();
        return;
      }

      // ネイティブ環境（iOS/Android）の初期化設定
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(settings: initSettings);

      // バックグラウンドハンドラのアタッチ
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 通知権限の要求
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      _setupFcmListeners();
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Initialization skipped: $e');
    }
  }

  /// 🌟 受信したFCMパケットが、ユーザーのカスタム設定および送り分け条件を満たしているか選別するフィルタリング壁
  void _setupFcmListeners() {
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('📩 [NotificationService] フォアグラウンドFCMを受信しました。');

        final data = message.data;
        final String type = data['type'] as String? ?? 'emergency';
        final String target = data['target'] as String? ?? 'all';

        // ステップ2で拡張したSettingsState（ユーザーのiPhone風カスタム設定）を最新読込
        final settings = _ref.read(settingsProvider);

        // 🛡️ 第1防衛線：スタッフ限定通知（staff）の場合、閲覧者（PINなし環境）ならバナー通知を全自動破棄
        // ※簡易判定として、ここでは settingsProvider が存在する一般環境ベースでフィルタリングします
        final bool isStaffRoom = data['isStaffRoom'] == 'true'; // パケット側の属性
        if (target == 'staff' && !isStaffRoom) {
          debugPrint('🛡️ [Filter] スタッフ限定通知のため、一般閲覧者の端末でのバナー発火を拒否（パージ）しました。');
          return;
        }

        // 🛡️ 第2防衛線：イベント種別ごとのユーザー設定ON/OFFフィルター
        bool isAllowedByUserSettings = true;
        if (type == 'emergency' && !settings.notifyOnEmergency) {
          isAllowedByUserSettings = false;
        }
        if (type == 'matchAdded' && !settings.notifyOnMatchAdded) {
          isAllowedByUserSettings = false;
        }
        if (type == 'matchStarted' && !settings.notifyOnMatchStarted) {
          isAllowedByUserSettings = false;
        }
        if (type == 'result' && !settings.notifyOnResult) {
          isAllowedByUserSettings = false;
        }

        if (!isAllowedByUserSettings) {
          debugPrint(
            '🛡️ [Filter] ユーザー設定によってこの通知タイプ（$type）はOFFにされているため、バナー出力をブロックしました。',
          );
          return;
        }

        // 🌟 すべての防衛線を突破したものだけを、iPhone標準バナーとして「ピコン」と画面上部に降らせる
        final notification = message.notification;
        if (notification != null && !kIsWeb) {
          await _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'kendo_os_channel',
                '大会進行アナウンス',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Failed to set up FCM listener: $e');
    }
  }

  /// 🌟 端末のプッシュ通知受信用にトピック購読（Native）またはFCMトークン保存（Web）を行う
  Future<void> registerPushNotification({
    required String tournamentId,
    required bool isStaff,
  }) async {
    // 🛡️ テスト環境などFirebase未初期化時のクラッシュを水際で防止
    if (Firebase.apps.isEmpty) {
      debugPrint(
        '⚠️ [NotificationService] Firebase is not initialized. Skipping push registration.',
      );
      return;
    }

    FirebaseFirestore firestore;
    try {
      firestore = _ref.read(firestoreProvider);
    } catch (_) {
      firestore = FirebaseFirestore.instance;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      if (kIsWeb) {
        // Web/PWA環境: Web Push用のFCMトークンを取得してFirestoreに保存
        // 🌟 開発者ビルド時以外の環境でも動作可能にするため、VAPIDキーをFirestoreの /fcm_config/web ドキュメントから動的に取得します
        String vapidKey = const String.fromEnvironment(
          'FCM_VAPID_KEY',
          defaultValue: '',
        );
        if (vapidKey.isEmpty) {
          try {
            final configDoc = await firestore
                .collection('fcm_config')
                .doc('web')
                .get();
            final dbKey = configDoc.data()?['vapidKey'] as String?;
            if (dbKey != null && dbKey.isNotEmpty) {
              vapidKey = dbKey;
              debugPrint(
                '🔔 [NotificationService] Loaded VAPID Key from Firestore: $vapidKey',
              );
            }
          } catch (e) {
            debugPrint(
              '⚠️ [NotificationService] Failed to load VAPID Key from Firestore: $e',
            );
          }
        }

        final String? token = await messaging
            .getToken(vapidKey: vapidKey.isNotEmpty ? vapidKey : null)
            .catchError((e) {
              debugPrint(
                '⚠️ [NotificationService] Failed to get Web FCM Token: $e',
              );
              // Firestoreにエラーを記録
              firestore.collection('client_logs').add({
                'action': 'getToken',
                'error': e.toString(),
                'platform': 'web',
                'timestamp': FieldValue.serverTimestamp(),
              });
              return null;
            });

        if (token != null && token.isNotEmpty) {
          await firestore.collection('fcm_tokens').doc(token).set({
            'token': token,
            'tournamentId': tournamentId,
            'isStaff': isStaff,
            'platform': 'web',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint(
            '🔔 [NotificationService] Web FCM Token registered successfully on Firestore',
          );
        }
      } else {
        // ネイティブ環境 (iOS/Android): FCMトピックの購読を実行
        // 全員向けのアナウンス用トピックを購読
        await messaging.subscribeToTopic('tournament_${tournamentId}_all');

        // スタッフ限定のアナウンス用トピックの購読制御
        if (isStaff) {
          await messaging.subscribeToTopic('tournament_${tournamentId}_staff');
        } else {
          await messaging.unsubscribeFromTopic(
            'tournament_${tournamentId}_staff',
          );
        }
        debugPrint(
          '🔔 [NotificationService] Subscribed to Native FCM topics for tournament: $tournamentId (isStaff: $isStaff)',
        );
      }
    } catch (e) {
      debugPrint(
        '⚠️ [NotificationService] Failed to register push notification: $e',
      );
      try {
        await firestore.collection('client_logs').add({
          'action': 'registerPushNotification',
          'error': e.toString(),
          'platform': kIsWeb ? 'web' : 'native',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }
}

/// 🌟 アプリ全体へ供給するための通知サービスプロバイダ
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
