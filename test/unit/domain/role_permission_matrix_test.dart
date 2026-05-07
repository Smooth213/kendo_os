import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/entities/role_permission.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';

void main() {
  group('🛡️ Phase 3-4: セキュリティテスト拡張 (Role/Permission Matrix)', () {
    late PermissionService permissionService;

    setUp(() {
      permissionService = PermissionService();
    });

    // テスト用の各権限ユーザー
    final viewer = const User(id: 'v1', role: Role.viewer, organizationId: 'org1');
    final scorer = const User(id: 's1', role: Role.scorer, organizationId: 'org1');
    final admin = const User(id: 'a1', role: Role.admin, organizationId: 'org1');

    // テスト用のダミーイベント
    final dummyEvent = ScoreEventLegacyAdapter.fromLegacy(
      side: Side.red, type: PointType.men, sequence: 1, userId: 'test',
    );

    test('Viewer (観客) は、いかなる試合進行の書き込み操作も【拒否】されること', () {
      expect(permissionService.canAppend(viewer, dummyEvent), isFalse, reason: 'Viewerがスコアを追加できてしまっています');
      expect(permissionService.canUndo(viewer), isFalse, reason: 'ViewerがUndoできてしまっています');
      expect(permissionService.canTimeUp(viewer), isFalse, reason: 'Viewerが時間切れ操作を行えてしまっています');
    });

    test('Scorer (記録係) は、担当範囲の試合進行操作が【許可】されること', () {
      expect(permissionService.canAppend(scorer, dummyEvent), isTrue, reason: 'Scorerがスコアを追加できません');
      expect(permissionService.canUndo(scorer), isTrue, reason: 'ScorerがUndoできません');
      expect(permissionService.canTimeUp(scorer), isTrue, reason: 'Scorerが時間切れ操作を行えません');
    });

    test('Admin (管理者) は、すべての操作が【許可】されること', () {
      expect(permissionService.canAppend(admin, dummyEvent), isTrue, reason: 'Adminがスコアを追加できません');
      expect(permissionService.canUndo(admin), isTrue, reason: 'AdminがUndoできません');
      expect(permissionService.canTimeUp(admin), isTrue, reason: 'Adminが時間切れ操作を行えません');
    });
  });
}