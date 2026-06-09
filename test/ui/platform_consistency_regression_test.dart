import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kendo_os/features/tournament/presentation/operate/components/home/operator_action_buttons.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';

void main() {
  group('🛡️ Platform Consistency & Zero Trust Regression Tests', () {
    testWidgets(
      '✅ [Web/Native共通] ローカルキャッシュ(SharedPreferences)が空の環境でも、PIN認証済みのAdminセッションがあればフル機能のUIが描画されること',
      (WidgetTester tester) async {
        // Webブラウザでの初回アクセスや、シークレットモードを模倣するため、ローカルキャッシュを完全に空にする
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    // テスト内で動的にAdminセッションを確立 (PINログイン成功をシミュレート)
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final currentSession = ref.read(authSessionProvider);
                      if (currentSession?.role != UserRole.admin) {
                        ref
                            .read(authSessionProvider.notifier)
                            .establishSession(UserRole.admin, 'test_dojo');
                      }
                    });

                    return const OperatorActionButtons(
                      tournamentId: 'test_tourney',
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // セッション確立の非同期処理とUIの再描画を待つ
        await tester.pumpAndSettle();

        // 管理者(Admin)専用の「試合開始（新しく作成）」ボタンが確実に画面に存在することを検証
        // 過去の不具合（キャッシュ依存）が再発した場合、ここはViewerに降格してしまいボタンが見つからずFailする
        expect(
          find.textContaining('試合開始'),
          findsOneWidget,
          reason:
              'ローカルキャッシュが存在しないWeb環境であっても、Adminセッションが確立されていれば管理者用ボタンが表示されなければならない',
        );
      },
    );

    testWidgets(
      '✅ [Web/Native共通] Viewerセッションの場合は、管理者ボタンが完全に秘匿され、観客用UIのみが提供されること(Zero Trust)',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              permissionProvider.overrideWith(
                (ref) => const AppPermissions(
                  isReadOnly: true,
                  canManageTournament: false,
                  canCreateMatch: false,
                  canChangeSettings: false,
                  canDeleteData: false,
                ),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: OperatorActionButtons(tournamentId: 'test_tourney'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 未ログイン状態（Viewer降格状態）では管理者ボタンが存在しないことを厳密に検証
        expect(find.textContaining('試合開始'), findsNothing);
        expect(
          find.textContaining('観客・保護者側の画面を確認'),
          findsOneWidget,
        ); // 共通で公開されているボタンは見える
      },
    );
  });
}
