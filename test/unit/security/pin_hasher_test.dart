import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/security/pin_hasher.dart';
import 'package:kendo_os/security/viewer_share_models.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';

void main() {
  group('[Unit] PinHasher & ViewerShareExpiryPreset', () {
    test('道場入室PINの入力ルール（案B: 4〜20文字半角英数字・-・_、6文字以上推奨）を正しく判定すること', () {
      expect(PinHasher.validateJoinPinFormat('').isValid, isFalse);
      expect(PinHasher.validateJoinPinFormat('abc').isValid, isFalse);
      expect(PinHasher.validateJoinPinFormat('a' * 21).isValid, isFalse);
      expect(PinHasher.validateJoinPinFormat('dojo@2026').isValid, isFalse);
      expect(PinHasher.validateJoinPinFormat('剣道1234').isValid, isFalse);

      final minValid = PinHasher.validateJoinPinFormat('1234');
      expect(minValid.isValid, isTrue);
      expect(minValid.isRecommendedLength, isFalse);

      final recommendedValid = PinHasher.validateJoinPinFormat('dojo_2026-a');
      expect(recommendedValid.isValid, isTrue);
      expect(recommendedValid.isRecommendedLength, isTrue);
    });

    test('ロールPINは4桁数字のみ有効と判定すること', () {
      expect(PinHasher.isValidRolePinFormat('9999'), isTrue);
      expect(PinHasher.isValidRolePinFormat('0123'), isTrue);
      expect(PinHasher.isValidRolePinFormat('123'), isFalse);
      expect(PinHasher.isValidRolePinFormat('12345'), isFalse);
      expect(PinHasher.isValidRolePinFormat('abcd'), isFalse);
    });

    test('同じPINでも道場IDやロールが異なればソルト分離によりハッシュ値が変わること', () {
      final h1 = PinHasher.hashJoinPin('Tokyo_Dojo', 'dojo2026');
      final h2 = PinHasher.hashJoinPin('tokyo_dojo', 'dojo2026');
      final h3 = PinHasher.hashJoinPin('osaka_dojo', 'dojo2026');
      expect(h1, equals(h2));
      expect(h1, isNot(equals(h3)));

      final rAdmin = PinHasher.hashRolePin(
        'tokyo_dojo',
        UserRole.admin,
        '9999',
      );
      final rOp = PinHasher.hashRolePin(
        'tokyo_dojo',
        UserRole.operator,
        '9999',
      );
      expect(rAdmin, isNot(equals(rOp)));
    });

    test('ViewerShareExpiryPreset が 24時間 / 7日間 / 無期限 / 停止 を正しく算出すること', () {
      final base = DateTime.utc(2026, 11, 11, 12, 0, 0);

      expect(
        ViewerShareExpiryPreset.hours24.computeExpiresAt(now: base),
        equals(DateTime.utc(2026, 11, 12, 12, 0, 0)),
      );
      expect(
        ViewerShareExpiryPreset.days7.computeExpiresAt(now: base),
        equals(DateTime.utc(2026, 11, 18, 12, 0, 0)),
      );
      expect(
        ViewerShareExpiryPreset.unlimited.computeExpiresAt(now: base),
        isNull,
      );
      final revokedAt = ViewerShareExpiryPreset.revoked.computeExpiresAt(
        now: base,
      );
      expect(revokedAt != null && revokedAt.isBefore(base), isTrue);
    });

    test('generateShareToken が衝突しにくい32文字HEXトークンを生成すること', () {
      final t1 = PinHasher.generateShareToken();
      final t2 = PinHasher.generateShareToken();
      expect(t1.length, 32);
      expect(t2.length, 32);
      expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(t1), isTrue);
      expect(t1, isNot(equals(t2)));
    });
  });
}
