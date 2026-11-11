import 'package:kendo_os/security/dojo_security_repository.dart';
import 'package:kendo_os/security/pin_hasher.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';

/// 現場での一般閲覧者による誤操作をランタイムレベルで水際防衛するPINガード。
///
/// 道場ごとのカスタムPIN（Firestore）が設定されている場合はそちらを優先検証し、
/// オフラインや未設定環境では従来の初期PIN（9999 / 2468 / 1357）へフォールバックする。
class PinGuard {
  static const Map<UserRole, String> _pinMap = PinHasher.defaultRolePins;

  /// 同期フォールバック検証（テスト環境・初期PIN照合用）
  /// ViewerモードはPINなしで通過。
  static bool validate(UserRole role, String input) {
    if (role == UserRole.viewer) return true;
    return _pinMap[role] == input.trim();
  }

  /// 道場ごとのロールPINを検証する（Firestore + Rules 検証）
  static Future<bool> validateForDojo({
    required UserRole role,
    required String input,
    required String dojoId,
    required String? joinPinHash,
    required String? uid,
    DojoSecurityRepository? repository,
  }) async {
    if (role == UserRole.viewer) return true;
    if (repository != null &&
        dojoId.isNotEmpty &&
        dojoId != 'default_dojo_room' &&
        uid != null &&
        uid.isNotEmpty) {
      return repository.authenticateRoleWithPin(
        dojoId: dojoId,
        role: role,
        rolePin: input,
        joinPinHash: joinPinHash,
        uid: uid,
      );
    }
    return validate(role, input);
  }
}
