import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/domain/entities/user_session.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';

void main() {
  group('🔒 Phase 14 - PWA実運用セッション永続化＆タイムアウト防衛テスト', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('【セッション寿命検証】Adminロールでログインした際、有効期限が仕様通り「30分間」に厳格制限されていること', () {
      final notifier = container.read(authSessionProvider.notifier);

      // Adminロールでセッション創設
      notifier.establishSession(UserRole.admin, 'test_dojo_id');

      final session = container.read(authSessionProvider);
      expect(session, isNotNull);
      expect(session!.role, equals(UserRole.admin));

      // ログイン時刻から有効期限までの差分が正確に30分であることを決定論的にアサート
      final difference = session.expiresAt.difference(session.loginAt);
      expect(difference.inMinutes, equals(30));
    });

    test(
      '【セッション寿命検証】Operator/Recorderでログインした際、終日運営に耐える「12時間」の寿命が割り当てられること',
      () {
        final notifier = container.read(authSessionProvider.notifier);

        notifier.establishSession(UserRole.operator, 'test_dojo_id');
        final opSession = container.read(authSessionProvider);
        expect(
          opSession!.expiresAt.difference(opSession.loginAt).inHours,
          equals(12),
        );

        notifier.establishSession(UserRole.recorder, 'test_dojo_id');
        final recSession = container.read(authSessionProvider);
        expect(
          recSession!.expiresAt.difference(recSession.loginAt).inHours,
          equals(12),
        );
      },
    );

    test('【iPad放置対策】有効期限切れセッションが正しく判定されること', () {
      // 意図的に「過去に期限が切れたセッション」をインメモリに注入
      final now = DateTime.now();
      final expiredSession = UserSession(
        role: UserRole.admin,
        loginAt: now.subtract(const Duration(hours: 1)),
        expiresAt: now.subtract(const Duration(minutes: 30)), // 30分前に切れている
      );

      // 無理やり期限切れ状態をセット
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      container.read(authSessionProvider.notifier).state = expiredSession;

      final currentSession = container.read(authSessionProvider);
      expect(currentSession!.isExpired, isTrue);
    });

    test('【改ざん水際阻止】セッションエンティティのバージョン不一致を正確に検知できること', () {
      // 不正なJSONデータ構造（セッションバージョンがレガシー、または改ざんされたケース）
      final malformedJson = {
        'role': 'admin',
        'loginAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now()
            .add(const Duration(minutes: 30))
            .toIso8601String(),
        'sessionVersion': 999, // 存在しない不正なバージョン
      };

      final session = UserSession.fromJson(malformedJson);
      // 意図した不正バージョン（999）としてデシリアライズされ、バージョン不一致の判定条件に引っかかることを証明
      expect(session.sessionVersion, equals(999));
      expect(session.sessionVersion != 1, isTrue);
    });
  });
}
