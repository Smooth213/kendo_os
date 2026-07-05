import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

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
}

/// 🌟 アプリ全体へ供給するための通知サービスプロバイダ
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
