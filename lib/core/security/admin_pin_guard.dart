/// 管理者（Admin）領域へのアクセスを一時的に保護する内部テスト用のPINガード。
/// Stage2 β環境における現場での使いやすさと検証効率を最優先するため、
/// 複雑な暗号化通信を排除し、ローカルでの決定論的な平文照合を行う。
class AdminPinGuard {
  /// 内部テスト用固定PIN
  static const String pin = '1234';

  /// 入力されたPINが正しいか検証する
  static bool validate(String input) {
    return input == pin;
  }
}
