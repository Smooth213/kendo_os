import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';

/// 👑 大会管理者ホスト権限引き継ぎマネージャー
class AdminHostManager {
  String? currentAdminDeviceId;
  String masterHandoverPin;

  AdminHostManager({
    required String initialAdminDevice,
    required this.masterHandoverPin,
  }) : currentAdminDeviceId = initialAdminDevice;

  bool transferHostRole({
    required String newDeviceId,
    required String inputPin,
  }) {
    if (inputPin != masterHandoverPin) return false;
    currentAdminDeviceId = newDeviceId;
    return true;
  }

  Role getRoleForDevice(String deviceId) {
    if (deviceId == currentAdminDeviceId) {
      return Role.admin;
    }
    return Role.viewer; // 旧端末や第三者端末はViewerに降格
  }
}

void main() {
  group('🚀 【Phase 5-6/10】大会本部端末電池切れ サブ端末へのAdminホスト権限引き継ぎ E2Eテスト', () {
    test('1. 旧端末（iPad A）から新端末（iPad B）へPIN引き継ぎ実行後、旧端末が降格し新端末がAdminに昇格すること', () {
      final manager = AdminHostManager(
        initialAdminDevice: 'ipad_hq_primary',
        masterHandoverPin: '8899',
      );

      // 初期状態: iPad A が管理者
      expect(manager.getRoleForDevice('ipad_hq_primary'), Role.admin);
      expect(manager.getRoleForDevice('ipad_hq_backup'), Role.viewer);

      // 🪫 iPad A が電池切れ寸前！ サブの iPad B で引き継ぎPINを入力
      final success = manager.transferHostRole(
        newDeviceId: 'ipad_hq_backup',
        inputPin: '8899',
      );
      expect(success, isTrue);

      // 交代後: iPad B が真のAdminとなり、iPad A は安全にViewerへ降格
      expect(manager.getRoleForDevice('ipad_hq_backup'), Role.admin);
      expect(manager.getRoleForDevice('ipad_hq_primary'), Role.viewer);
    });

    test('2. 不正なPINでの乗っ取り試行が拒絶されること', () {
      final manager = AdminHostManager(
        initialAdminDevice: 'ipad_hq_primary',
        masterHandoverPin: '8899',
      );

      final failed = manager.transferHostRole(
        newDeviceId: 'attacker_phone',
        inputPin: '0000', // 誤ったPIN
      );

      expect(failed, isFalse);
      expect(manager.getRoleForDevice('attacker_phone'), Role.viewer);
      expect(manager.getRoleForDevice('ipad_hq_primary'), Role.admin);
    });
  });
}
