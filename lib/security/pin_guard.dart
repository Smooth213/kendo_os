import 'package:kendo_os/shared/domain/entities/user_role.dart';

/// 現場での一般閲覧者による誤操作をランタイムレベルで水際防衛する簡易PINガード。
class PinGuard {
  // ★ Fumiakiさん指定のマスターPINコード
  static const Map<UserRole, String> _pinMap = {
    UserRole.admin: '9999',
    UserRole.operator: '2468',
    UserRole.recorder: '1357',
  };

  /// 入力されたPINコードが選択ロールのマスター値と一致するか検証する。
  /// ViewerモードはPINなしで完全通過。
  static bool validate(UserRole role, String input) {
    if (role == UserRole.viewer) return true;
    return _pinMap[role] == input;
  }
}
