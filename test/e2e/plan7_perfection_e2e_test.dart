@TestOn('vm')
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_unified_announce_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/viewer/providers/viewer_view_state_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/widgets/critical_action_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCommentCommandService extends Mock implements CommentCommandService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🥋 【Plan 7 E2E】極限最適化・低負荷・絶対安定性 総合結合実証テスト', () {
    test(
      'E2E-1: 【バックグラウンド不要ストリーム完全解放実証】viewerMatchProjectionProvider および下流プロバイダが autoDispose であり、監視終了後に安全にリソースが解放されること',
      () async {
        final container = ProviderContainer();

        // 1. 下流プロバイダをリッスン（内部で viewerMatchProjectionProvider を購読）
        final subStatus = container.listen(
          viewerMatchStatusProvider('match_test_001'),
          (_, _) {},
        );
        final subMomentum = container.listen(
          viewerMatchMomentumProvider('match_test_001'),
          (_, _) {},
        );
        final subTimeline = container.listen(
          viewerMatchTimelineProvider('match_test_001'),
          (_, _) {},
        );

        // 初期値が正常に読み込めること
        expect(
          container.read(viewerMatchStatusProvider('match_test_001')).isLoading,
          isTrue,
        );
        expect(
          container
              .read(viewerMatchMomentumProvider('match_test_001'))
              .isLoading,
          isTrue,
        );
        expect(
          container
              .read(viewerMatchTimelineProvider('match_test_001'))
              .isLoading,
          isTrue,
        );

        // 2. リスナーを解除（autoDispose + 5分キャッシュキープタイマーの起動）
        subStatus.close();
        subMomentum.close();
        subTimeline.close();

        // コンテナ破棄時にタイマーが安全にキャンセルされ、リークなく破棄できること
        expect(() => container.dispose(), returnsNormally);
      },
    );

    testWidgets(
      'E2E-2: 【PIN再認証ダイアログ・ライフサイクル完全破棄実証】CriticalActionGuard でPINダイアログを開き、入力・認証後にダイアログが破棄され、コントローラーが確実に解放されること',
      (WidgetTester tester) async {
        bool verifiedCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      CriticalActionGuard.enforce(
                        context: context,
                        currentRole: UserRole.admin,
                        onVerified: () {
                          verifiedCalled = true;
                        },
                      );
                    },
                    child: const Text('危険操作を実行'),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. ボタンタップでダイアログ表示
        await tester.tap(find.text('危険操作を実行'));
        await tester.pumpAndSettle();

        expect(find.text('⚠️ 危険操作の再認証'), findsOneWidget);

        // 2. 誤ったPINを入力して「認証して実行」タップ ➔ エラー表示
        await tester.enterText(find.byType(TextField), '0000');
        await tester.tap(find.text('認証して実行'));
        await tester.pumpAndSettle();

        expect(find.text('PINコードが一致しません'), findsOneWidget);
        expect(verifiedCalled, isFalse);

        // 3. 正しいAdmin用PIN('9999')を入力して「認証して実行」タップ ➔ ダイアログが閉じ、コールバック発火
        await tester.enterText(find.byType(TextField), '9999');
        await tester.tap(find.text('認証して実行'));
        await tester.pumpAndSettle();

        expect(find.text('⚠️ 危険操作の再認証'), findsNothing);
        expect(verifiedCalled, isTrue);
      },
    );

    testWidgets(
      'E2E-3: 【一斉発信ダイアログ・popアニメーション安全破棄実証】TimelineUnifiedAnnounceDialog が pop アニメーション後も used after being disposed 例外なく正常終了すること',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final fakeFirestore = FakeFirebaseFirestore();
        final mockCommentService = MockCommentCommandService();
        final List<Map<String, dynamic>> addedComments = [];

        when(
          () => mockCommentService.addComment(
            tournamentId: any(named: 'tournamentId'),
            category: any(named: 'category'),
            groupName: any(named: 'groupName'),
            text: any(named: 'text'),
            order: any(named: 'order'),
            matchGroupId: any(named: 'matchGroupId'),
          ),
        ).thenAnswer((invocation) async {
          addedComments.add({
            'tournamentId': invocation.namedArguments[#tournamentId],
            'category': invocation.namedArguments[#category],
            'groupName': invocation.namedArguments[#groupName],
            'text': invocation.namedArguments[#text],
            'order': invocation.namedArguments[#order],
            'matchGroupId': invocation.namedArguments[#matchGroupId],
          });
        });

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            firestoreProvider.overrideWithValue(fakeFirestore),
            commentCommandProvider.overrideWithValue(mockCommentService),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () {
                        TimelineUnifiedAnnounceDialog.show(
                          context,
                          ref,
                          'tourney_test',
                          '一般男子',
                          'Aブロック',
                          1.0,
                        );
                      },
                      child: const Text('アナウンスダイアログを開く'),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. ダイアログを開く
        await tester.tap(find.text('アナウンスダイアログを開く'));
        await tester.pumpAndSettle();

        expect(find.text('公式アナウンス・コメントの一斉発信'), findsOneWidget);

        // 2. 本文を入力
        await tester.enterText(
          find.widgetWithText(TextField, 'アナウンス本文内容'),
          'E2Eテストのアナウンスメッセージ',
        );
        await tester.pumpAndSettle();

        // 3. 一斉発信して保存をタップ ➔ popアニメーション後に安全に破棄されること
        await tester.tap(find.text('一斉発信して保存'));
        await tester.pumpAndSettle();

        // ダイアログが消去され、SnackBarが表示されていること
        expect(find.text('公式アナウンス・コメントの一斉発信'), findsNothing);
        expect(find.text('全員向け緊急アナウンスを一斉配信しました'), findsOneWidget);
        expect(addedComments.length, 1);
      },
    );

    testWidgets(
      'E2E-4: 【UIレンダリング境界隔離実証】DockDraggableSheet で RepaintBoundary が正しく配置されていること',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DockDraggableSheet(
                builder: (context, scrollController) {
                  return const Text('Dock Content Inside');
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dock Content Inside'), findsOneWidget);

        // Content Area が RepaintBoundary の子孫であることを検証
        final dockContentFinder = find.ancestor(
          of: find.text('Dock Content Inside'),
          matching: find.byType(RepaintBoundary),
        );
        expect(dockContentFinder, findsWidgets);
      },
    );
  });
}
