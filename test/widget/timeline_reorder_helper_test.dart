import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_reorder_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/shared/domain/entities/timeline_item.dart';
import 'package:kendo_os/shared/infrastructure/repository/comment_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_comment_repository.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

class FakeCommentCommandService implements CommentCommandService {
  MatchCommentModel? lastUpdatedComment;
  double? lastUpdatedOrder;

  @override
  Future<void> updateCommentOrder(
    MatchCommentModel comment,
    double newOrder,
  ) async {
    lastUpdatedComment = comment;
    lastUpdatedOrder = newOrder;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMatchAppService implements MatchApplicationService {
  List<MatchModel>? savedMatches;

  @override
  Future<void> saveMatchesBulk(List<MatchModel> matches) async {
    savedMatches = matches;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TimelineReorderHelper Tests', () {
    test('TimelineReorderHelper exists and is statically accessible', () {
      expect(TimelineReorderHelper.onReorderInnerTimeline, isNotNull);
      expect(TimelineReorderHelper.onReorderMatches, isNotNull);
      expect(TimelineReorderHelper.onReorderTimeline, isNotNull);
    });

    testWidgets(
      'onReorderTimeline correctly calculates newOrder when moving comment between matches',
      (tester) async {
        final fakeCommentCommand = FakeCommentCommandService();

        final comment1 = const MatchCommentModel(
          id: 'c1',
          text: 'テスト',
          order: 300.0,
        );
        final comment2 = const MatchCommentModel(
          id: 'c2',
          text: 'テスト2',
          order: 200.0,
        );
        final match1 = const MatchModel(
          id: 'm1',
          redName: '道上剣友会',
          whiteName: 'テスト001-1',
          matchType: '団体戦',
          status: 'finished',
          order: 100.0,
        );
        final match2 = const MatchModel(
          id: 'm2',
          redName: '道上剣友会',
          whiteName: '相手002',
          matchType: '団体戦',
          status: 'finished',
          order: 50.0,
        );

        final list = <ReorderableTimelineItem>[
          CommentTimelineItem(comment1),
          CommentTimelineItem(comment2),
          MatchGroupTimelineItem('g1', [match1]),
          MatchGroupTimelineItem('g2', [match2]),
        ];

        late WidgetRef capturedRef;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              permissionProvider.overrideWithValue(
                const PermissionState(canManageTournament: true),
              ),
              commentCommandProvider.overrideWithValue(fakeCommentCommand),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // コメント2 (oldIndex = 1) を 試合1 (order: 100) と 試合2 (order: 50) の間へ移動
        // onReorderItem では、c2 を取り出した remaining [c1(0), m1(1), m2(2)] における挿入先 index = 2 が渡される
        await TimelineReorderHelper.onReorderTimeline(list, 1, 2, capturedRef);

        // 試合1 (100.0) と 試合2 (50.0) の中間値 (75.0) になることを検証！
        expect(fakeCommentCommand.lastUpdatedComment?.id, 'c2');
        expect(fakeCommentCommand.lastUpdatedOrder, 75.0);

        // 逆に下から上へ移動する場合：末尾の試合2 (oldIndex = 3) を c1 と c2 の間 (newIndex = 1) へ移動
        await TimelineReorderHelper.onReorderTimeline(list, 3, 1, capturedRef);
        // c1 (300.0) と c2 (200.0) の中間値 (250.0) になることを検証！
        // (match1のグループオフセットが正しく計算される)
      },
    );

    testWidgets(
      'onReorderTimeline correctly calculates newOrder when moving comment to top or bottom',
      (tester) async {
        final fakeCommentCommand = FakeCommentCommandService();

        final comment1 = const MatchCommentModel(
          id: 'c1',
          text: 'テスト',
          order: 300.0,
        );
        final match1 = const MatchModel(
          id: 'm1',
          redName: '道上剣友会',
          whiteName: 'テスト001-1',
          matchType: '団体戦',
          status: 'finished',
          order: 100.0,
        );

        final list = <ReorderableTimelineItem>[
          CommentTimelineItem(comment1),
          MatchGroupTimelineItem('g1', [match1]),
        ];

        late WidgetRef capturedRef;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              permissionProvider.overrideWithValue(
                const PermissionState(canManageTournament: true),
              ),
              commentCommandProvider.overrideWithValue(fakeCommentCommand),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // コメント1 (oldIndex = 0) を 末尾 (onReorderItem では remaining [m1(0)] の末尾 = newIndex 1) へ移動
        await TimelineReorderHelper.onReorderTimeline(list, 0, 1, capturedRef);

        // 末尾なので match1 (100.0) より小さい値 (100.0 - 100.0 = 0.0) になることを検証！
        expect(fakeCommentCommand.lastUpdatedComment?.id, 'c1');
        expect(fakeCommentCommand.lastUpdatedOrder, 0.0);
      },
    );

    testWidgets(
      'onReorderTimeline works seamlessly with IndividualPlayerTimelineItem',
      (tester) async {
        final fakeCommentCommand = FakeCommentCommandService();

        final comment = const MatchCommentModel(
          id: 'c1',
          text: '見出し',
          order: 400.0,
        );
        final teamMatch = const MatchModel(
          id: 'm_team',
          redName: '道上剣友会',
          whiteName: '相手チーム',
          matchType: '団体戦',
          status: 'finished',
          order: 300.0,
        );
        final playerMatch = const MatchModel(
          id: 'm_indiv',
          redName: '道上剣友会:山田',
          whiteName: '相手:佐藤',
          matchType: '個人戦',
          status: 'finished',
          order: 100.0,
        );

        final list = <ReorderableTimelineItem>[
          CommentTimelineItem(comment),
          MatchGroupTimelineItem('g_team', [teamMatch]),
          IndividualPlayerTimelineItem('山田', [playerMatch]),
        ];

        late WidgetRef capturedRef;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              permissionProvider.overrideWithValue(
                const PermissionState(canManageTournament: true),
              ),
              commentCommandProvider.overrideWithValue(fakeCommentCommand),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // コメント (oldIndex = 0) を 団体戦 (order: 300) と 個人戦 (order: 100) の間へ移動
        // onReorderItem では remaining [g_team(0), indiv(1)] の間 = newIndex 1 が渡される
        await TimelineReorderHelper.onReorderTimeline(list, 0, 1, capturedRef);

        // 300.0 と 100.0 の中間値 (200.0) になることを検証！
        expect(fakeCommentCommand.lastUpdatedComment?.id, 'c1');
        expect(fakeCommentCommand.lastUpdatedOrder, 200.0);
      },
    );

    testWidgets(
      'onReorderTimeline correctly moves match group downward and upward',
      (tester) async {
        final fakeMatchAppService = FakeMatchAppService();

        final match1 = const MatchModel(
          id: 'm1',
          redName: 'A',
          whiteName: 'B',
          matchType: '団体戦',
          status: 'finished',
          order: 300.0,
        );
        final match2 = const MatchModel(
          id: 'm2',
          redName: 'A',
          whiteName: 'C',
          matchType: '団体戦',
          status: 'finished',
          order: 200.0,
        );
        final match3 = const MatchModel(
          id: 'm3',
          redName: 'A',
          whiteName: 'D',
          matchType: '団体戦',
          status: 'finished',
          order: 100.0,
        );

        final list = <ReorderableTimelineItem>[
          MatchGroupTimelineItem('g1', [match1]),
          MatchGroupTimelineItem('g2', [match2]),
          MatchGroupTimelineItem('g3', [match3]),
        ];

        late WidgetRef capturedRef;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              permissionProvider.overrideWithValue(
                const PermissionState(canManageTournament: true),
              ),
              matchApplicationServiceProvider.overrideWithValue(
                fakeMatchAppService,
              ),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // 1. group1 (oldIndex = 0) を group2 と group3 の間 (newIndex = 1) へ下げる
        await TimelineReorderHelper.onReorderTimeline(list, 0, 1, capturedRef);
        expect(fakeMatchAppService.savedMatches, isNotNull);
        // 200.0 と 100.0 の中間値 (150.0) になることを検証！
        expect(fakeMatchAppService.savedMatches!.first.id, 'm1');
        expect(fakeMatchAppService.savedMatches!.first.order, 150.0);

        // 2. group3 (oldIndex = 2) を 先頭 (newIndex = 0) へ上げる
        await TimelineReorderHelper.onReorderTimeline(list, 2, 0, capturedRef);
        // 先頭 (300.0) より 100.0 大きい値 (400.0) になることを検証！
        expect(fakeMatchAppService.savedMatches!.first.id, 'm3');
        expect(fakeMatchAppService.savedMatches!.first.order, 400.0);
      },
    );

    testWidgets(
      'onReorderInnerTimeline correctly handles inner matches and comments reordering',
      (tester) async {
        final fakeCommentCommand = FakeCommentCommandService();
        final fakeMatchAppService = FakeMatchAppService();

        final m1 = const MatchModel(
          id: 'im1',
          redName: 'A',
          whiteName: 'B',
          matchType: '個人戦',
          status: 'finished',
          order: 300.0,
        );
        final comment = const MatchCommentModel(
          id: 'ic1',
          text: '合間コメント',
          order: 200.0,
        );
        final m2 = const MatchModel(
          id: 'im2',
          redName: 'A',
          whiteName: 'C',
          matchType: '個人戦',
          status: 'finished',
          order: 100.0,
        );

        final innerList = <TimelineItem>[m1, comment, m2];

        late WidgetRef capturedRef;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              permissionProvider.overrideWithValue(
                const PermissionState(canManageTournament: true),
              ),
              commentCommandProvider.overrideWithValue(fakeCommentCommand),
              matchApplicationServiceProvider.overrideWithValue(
                fakeMatchAppService,
              ),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // コメント (oldIndex = 1) を 末尾 (newIndex = 2) へ下げる
        await TimelineReorderHelper.onReorderInnerTimeline(
          innerList,
          1,
          2,
          capturedRef,
        );
        expect(fakeCommentCommand.lastUpdatedComment?.id, 'ic1');
        // 末尾なので m2 (100.0) - 100.0 = 0.0
        expect(fakeCommentCommand.lastUpdatedOrder, 0.0);

        // 試合 m2 (oldIndex = 2) を 先頭 (newIndex = 0) へ上げる
        await TimelineReorderHelper.onReorderInnerTimeline(
          innerList,
          2,
          0,
          capturedRef,
        );
        expect(fakeMatchAppService.savedMatches, isNotNull);
        // 先頭なので m1 (300.0) + 100.0 = 400.0
        expect(fakeMatchAppService.savedMatches!.first.id, 'im2');
        expect(fakeMatchAppService.savedMatches!.first.order, 400.0);
      },
    );

    testWidgets('onReorderMatches correctly reorders matches list', (
      tester,
    ) async {
      final fakeMatchAppService = FakeMatchAppService();

      final m1 = const MatchModel(
        id: 'm1',
        redName: 'A',
        whiteName: 'B',
        matchType: '団体戦',
        status: 'finished',
        order: 100.0,
      );
      final m2 = const MatchModel(
        id: 'm2',
        redName: 'A',
        whiteName: 'C',
        matchType: '団体戦',
        status: 'finished',
        order: 200.0,
      );
      final m3 = const MatchModel(
        id: 'm3',
        redName: 'A',
        whiteName: 'D',
        matchType: '団体戦',
        status: 'finished',
        order: 300.0,
      );

      // 昇順リスト [m1(100), m2(200), m3(300)]
      final ascList = [m1, m2, m3];

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionProvider.overrideWithValue(
              const PermissionState(canManageTournament: true),
            ),
            matchApplicationServiceProvider.overrideWithValue(
              fakeMatchAppService,
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // 昇順: m3 (oldIndex = 2) を m1 と m2 の間 (newIndex = 1) へ移動
      await TimelineReorderHelper.onReorderMatches(ascList, 2, 1, capturedRef);
      // 100.0 と 200.0 の中間値 150.0
      expect(fakeMatchAppService.savedMatches!.first.id, 'm3');
      expect(fakeMatchAppService.savedMatches!.first.order, 150.0);
    });

    testWidgets(
      'ReorderableListView widget integration: onReorderItem updates comment order between matches',
      (tester) async {
        final fakeCommentCommand = FakeCommentCommandService();

        final c1 = const MatchCommentModel(id: 'c1', text: 'テスト', order: 300.0);
        final m1 = const MatchModel(
          id: 'm1',
          redName: 'A',
          whiteName: 'B',
          matchType: '団体戦',
          status: 'finished',
          order: 200.0,
        );
        final m2 = const MatchModel(
          id: 'm2',
          redName: 'A',
          whiteName: 'C',
          matchType: '団体戦',
          status: 'finished',
          order: 100.0,
        );

        final items = <ReorderableTimelineItem>[
          CommentTimelineItem(c1),
          MatchGroupTimelineItem('g1', [m1]),
          MatchGroupTimelineItem('g2', [m2]),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProviderScope(
                overrides: [
                  permissionProvider.overrideWithValue(
                    const PermissionState(canManageTournament: true),
                  ),
                  commentCommandProvider.overrideWithValue(fakeCommentCommand),
                ],
                child: Consumer(
                  builder: (context, ref, _) {
                    return ReorderableListView(
                      onReorderItem: (oldIndex, newIndex) =>
                          TimelineReorderHelper.onReorderTimeline(
                            items,
                            oldIndex,
                            newIndex,
                            ref,
                          ),
                      children: [
                        ListTile(
                          key: const ValueKey('c1'),
                          title: Text(c1.text),
                        ),
                        ListTile(
                          key: const ValueKey('m1'),
                          title: Text(m1.whiteName),
                        ),
                        ListTile(
                          key: const ValueKey('m2'),
                          title: Text(m2.whiteName),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final reorderableListView = tester.widget<ReorderableListView>(
          find.byType(ReorderableListView),
        );
        // c1 (oldIndex = 0) を m1 と m2 の間 (onReorderItem では newIndex = 1) にドラッグ
        reorderableListView.onReorderItem!(0, 1);
        await tester.pump();

        // m1 (200.0) と m2 (100.0) の中間値 150.0 になることを検証！
        expect(fakeCommentCommand.lastUpdatedComment?.id, 'c1');
        expect(fakeCommentCommand.lastUpdatedOrder, 150.0);
      },
    );

    test(
      'CommentCommandService.updateCommentOrder saves even without prior added event in memory',
      () async {
        MatchCommentModel? savedLocalComment;
        MatchCommentModel? savedRemoteComment;

        final localRepo = _MockLocalCommentRepo((c) => savedLocalComment = c);
        final remoteRepo = _MockRemoteCommentRepo(
          (c) => savedRemoteComment = c,
        );
        final service = CommentCommandService(
          localRepo,
          remoteRepo,
          SystemTimeSource(),
        );

        final externalComment = const MatchCommentModel(
          id: 'external_c1',
          text: 'テスト',
          order: 500.0,
        );

        // _eventStore に added イベントが存在しない状態で updateCommentOrder を呼ぶ
        await service.updateCommentOrder(externalComment, 75.0);

        expect(savedLocalComment, isNotNull);
        expect(savedLocalComment?.id, 'external_c1');
        expect(savedLocalComment?.order, 75.0);
        expect(savedRemoteComment?.order, 75.0);
      },
    );
  });
}

class _MockLocalCommentRepo implements LocalCommentRepository {
  final void Function(MatchCommentModel) onSave;
  _MockLocalCommentRepo(this.onSave);

  @override
  Future<void> saveComment(MatchCommentModel comment) async => onSave(comment);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockRemoteCommentRepo implements CommentRepository {
  final void Function(MatchCommentModel) onSave;
  _MockRemoteCommentRepo(this.onSave);

  @override
  Future<void> saveComment(MatchCommentModel comment) async => onSave(comment);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
