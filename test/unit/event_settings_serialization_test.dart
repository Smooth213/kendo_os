import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/event_settings.dart';
import 'package:kendo_os/shared/domain/entities/member_role_model.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';

void main() {
  group('[Unit] 大会環境設定およびメンバーロールシリアライズ単体テスト', () {
    test('EventSettingsにおいてデフォルト値の完全性およびJSON変換の可逆性が保たれること', () {
      const defaultSettings = EventSettings();
      expect(defaultSettings.id, 'test_event_v2');
      expect(defaultSettings.name, '新規大会');
      expect(defaultSettings.defaultFormat, MatchFormat.individual);
      expect(defaultSettings.defaultDurationSeconds, 180);

      const customSettings = EventSettings(
        id: 'evt-custom-01',
        name: '夏季少年剣道大会',
        defaultFormat: MatchFormat.team,
        defaultDurationSeconds: 240,
      );

      final json = customSettings.toJson();
      expect(json['id'], 'evt-custom-01');
      expect(json['name'], '夏季少年剣道大会');
      expect(json['defaultDurationSeconds'], 240);

      final restored = EventSettings.fromJson(json);
      expect(restored.id, customSettings.id);
      expect(restored.name, customSettings.name);
      expect(restored.defaultFormat, MatchFormat.team);
      expect(restored.defaultDurationSeconds, 240);
    });

    test('MemberRoleModelにおいてロールと表示名が正しくシリアライズされ未知のロールは安全にフォールバックされること', () {
      final now = DateTime(2026, 10, 1, 9, 30);
      final member = MemberRoleModel(
        uid: 'user-op-123',
        role: UserRole.operator,
        displayName: 'コート主審端末',
        updatedAt: now,
      );

      final json = member.toJson();
      expect(json['role'], 'operator');
      expect(json['displayName'], 'コート主審端末');
      expect(json['updatedAt'], now.toIso8601String());

      final restored = MemberRoleModel.fromJson('user-op-123', json);
      expect(restored.uid, 'user-op-123');
      expect(restored.role, UserRole.operator);
      expect(restored.displayName, 'コート主審端末');

      // 未知の不正なロール名が渡された場合は安全に viewer にフォールバックすること
      final fallbackMember = MemberRoleModel.fromJson('user-unknown', {
        'role': 'super_ultra_admin',
        'displayName': '未知の端末',
      });
      expect(fallbackMember.role, UserRole.viewer);
    });
  });
}
