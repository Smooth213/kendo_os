import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 🥋 剣道遠征現場特化：階層化ハプティクス（触覚フィードバック）サービス
///
/// 体育館の寒さや緊張で手元が狂いやすい環境下でも、
/// 指先の「重さ・リズム」だけで操作の成功を100%確信できるように設計されています。
class KendoHaptics {
  KendoHaptics._();

  /// 触覚フィードバック全体の有効/無効フラグ（設定画面と連動）
  static bool isEnabled = true;

  /// タイマーの開始/停止
  /// - 開始: 軽快なタップ感 (lightImpact)
  /// - 停止: カチッとしたクリック感 (selectionClick)
  static Future<void> timerToggle({required bool isStarting}) async {
    if (kIsWeb || !isEnabled) return;
    try {
      if (isStarting) {
        await HapticFeedback.lightImpact();
      } else {
        await HapticFeedback.selectionClick();
      }
    } catch (_) {}
  }

  /// 有効打突（面・小手・胴・突き）
  /// - ズシッと重く明確な手応え (heavyImpact)
  static Future<void> scorePoint() async {
    if (kIsWeb || !isEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// 反則
  /// - 警告・ペナルティを連想させる「ト・トン」という2連振動
  static Future<void> foulHansoku() async {
    if (kIsWeb || !isEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// 取消（Undo）
  /// - 直前の操作が確実に巻き戻ったことを示す長めの振動 (vibrate)
  static Future<void> undoEvent() async {
    if (kIsWeb || !isEnabled) return;
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  /// 視点反転・モード切替
  /// - スイッチがカチッと切り替わる感触 (mediumImpact)
  static Future<void> viewFlip() async {
    if (kIsWeb || !isEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
