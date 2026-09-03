import 'package:flutter_test/flutter_test.dart';

/// 🖨️ Wi-Fiプリンタ（AirPrint）印刷障害ハンドラ
class PrinterErrorHandler {
  static String handlePrintingError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('offline') ||
        message.contains('unreachable') ||
        message.contains('socket')) {
      return 'プリンターが見つかりません。Wi-Fi接続を確認してください。';
    } else if (message.contains('paper') || message.contains('jam')) {
      return '用紙切れまたは紙詰まりが発生しています。';
    } else if (message.contains('cancel')) {
      return '印刷がキャンセルされました。';
    }
    return '印刷中にエラーが発生しました。PDF保存をお試しください。';
  }
}

void main() {
  group('📱 【Phase 2-4/10】AirPrint/Wi-Fiプリンタ オフライン・紙詰まり障害リカバリテスト', () {
    test('1. プリンタ電源断・オフラインエラー時の適切なガイダンス案内', () {
      final error = Exception(
        'Printer is offline or unreachable on local network',
      );
      final guidance = PrinterErrorHandler.handlePrintingError(error);
      expect(guidance, contains('プリンターが見つかりません'));
    });

    test('2. 用紙切れ・紙詰まり（Paper Jam）検知時のガイダンス案内', () {
      final error = Exception('Paper jam in tray 1');
      final guidance = PrinterErrorHandler.handlePrintingError(error);
      expect(guidance, contains('用紙切れまたは紙詰まり'));
    });

    test('3. ユーザーキャンセル時の安全な終了ハンドリング', () {
      final error = Exception('User canceled print job');
      final guidance = PrinterErrorHandler.handlePrintingError(error);
      expect(guidance, contains('印刷がキャンセルされました'));
    });

    test('4. 未知の通信例外時のPDFファイル直接保存フォールバック案内', () {
      final error = Exception('Unknown I/O hardware failure 0x80004005');
      final guidance = PrinterErrorHandler.handlePrintingError(error);
      expect(guidance, contains('PDF保存をお試しください'));
    });
  });
}
