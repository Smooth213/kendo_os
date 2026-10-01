import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/security/feature_gate.dart';
import 'package:kendo_os/security/security_level.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';

void main() {
  group('[Unit] 機能ゲートウェイおよびセキュリティレベル複合判定テスト', () {
    test('機能確保メソッドにおいて無効フラグ時に例外を送出し有効時に正常通過すること', () {
      expect(() => FeatureGate.ensure(false), throwsA(isA<UnsupportedError>()));
      expect(() => FeatureGate.ensure(true), returnsNormally);
    });

    test('特権機能において管理者ロールのみ許可され他ロールが完全遮断されること', () {
      for (final role in UserRole.values) {
        final isAdmin = role == UserRole.admin;
        expect(FeatureGate.canUseAI(role), equals(isAdmin));
        expect(FeatureGate.canManageReplay(role), equals(isAdmin));
        expect(FeatureGate.canAccessObservability(role), equals(isAdmin));
        expect(FeatureGate.canAccessMetrics(role), equals(isAdmin));
        expect(FeatureGate.canExecuteGovernance(role), equals(isAdmin));
      }
    });

    test('試合作成権限においてロック時は全ロール遮断され通常時は管理者と監督のみ許可されること', () {
      // ロック時: 全ロール完全遮断
      for (final role in UserRole.values) {
        expect(FeatureGate.canCreateMatch(role, SecurityLevel.locked), isFalse);
      }

      // イベント運用時
      expect(
        FeatureGate.canCreateMatch(UserRole.admin, SecurityLevel.event),
        isTrue,
      );
      expect(
        FeatureGate.canCreateMatch(UserRole.operator, SecurityLevel.event),
        isTrue,
      );
      expect(
        FeatureGate.canCreateMatch(UserRole.recorder, SecurityLevel.event),
        isFalse,
      );
      expect(
        FeatureGate.canCreateMatch(UserRole.viewer, SecurityLevel.event),
        isFalse,
      );

      // オープン時
      expect(
        FeatureGate.canCreateMatch(UserRole.admin, SecurityLevel.open),
        isTrue,
      );
      expect(
        FeatureGate.canCreateMatch(UserRole.operator, SecurityLevel.open),
        isTrue,
      );
      expect(
        FeatureGate.canCreateMatch(UserRole.recorder, SecurityLevel.open),
        isFalse,
      );
      expect(
        FeatureGate.canCreateMatch(UserRole.viewer, SecurityLevel.open),
        isFalse,
      );
    });

    test('試合操作権限においてロック時は遮断されオープン時は全開放されイベント時はロール準拠となること', () {
      // ロック時: 全ロール遮断
      for (final role in UserRole.values) {
        expect(
          FeatureGate.canOperateMatch(role, SecurityLevel.locked),
          isFalse,
        );
      }

      // オープン時: 緊急全開放（閲覧専用含む全端末で入力許可）
      for (final role in UserRole.values) {
        expect(FeatureGate.canOperateMatch(role, SecurityLevel.open), isTrue);
      }

      // イベント時: ロール権限準拠
      expect(
        FeatureGate.canOperateMatch(UserRole.admin, SecurityLevel.event),
        isTrue,
      );
      expect(
        FeatureGate.canOperateMatch(UserRole.operator, SecurityLevel.event),
        isTrue,
      );
      expect(
        FeatureGate.canOperateMatch(UserRole.recorder, SecurityLevel.event),
        isTrue,
      );
      expect(
        FeatureGate.canOperateMatch(UserRole.viewer, SecurityLevel.event),
        isFalse,
      );
    });

    test('マスター管理権限においてロック時は遮断され通常時は管理者のみ許可されること', () {
      // ロック時: 全ロール遮断
      for (final role in UserRole.values) {
        expect(
          FeatureGate.canManageMaster(role, SecurityLevel.locked),
          isFalse,
        );
      }

      // 通常時: 管理者のみ許可
      expect(
        FeatureGate.canManageMaster(UserRole.admin, SecurityLevel.event),
        isTrue,
      );
      expect(
        FeatureGate.canManageMaster(UserRole.operator, SecurityLevel.event),
        isFalse,
      );
      expect(
        FeatureGate.canManageMaster(UserRole.recorder, SecurityLevel.event),
        isFalse,
      );
      expect(
        FeatureGate.canManageMaster(UserRole.viewer, SecurityLevel.event),
        isFalse,
      );
    });
  });
}
