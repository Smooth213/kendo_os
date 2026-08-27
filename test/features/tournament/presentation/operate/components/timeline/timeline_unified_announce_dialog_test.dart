import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_unified_announce_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_comment_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/comment_repository.dart';

class MockLocalCommentRepository extends Mock
    implements LocalCommentRepository {}

class MockCommentRepository extends Mock implements CommentRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const MatchCommentModel(id: '', text: ''));
  });
  group('📢 TimelineUnifiedAnnounceDialog Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockLocalCommentRepository mockLocalCommentRepo;
    late MockCommentRepository mockCommentRepo;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockLocalCommentRepo = MockLocalCommentRepository();
      mockCommentRepo = MockCommentRepository();

      when(
        () => mockLocalCommentRepo.saveComment(any()),
      ).thenAnswer((_) => Future.value());
      when(
        () => mockCommentRepo.saveComment(any()),
      ).thenAnswer((_) => Future.value());
    });

    testWidgets(
      '1. 「🔕 通知なし」を選択して保存した場合、Firestoreの announcements には追加されずコメントのみが保存されること',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              firestoreProvider.overrideWithValue(fakeFirestore),
              localCommentRepositoryProvider.overrideWithValue(
                mockLocalCommentRepo,
              ),
              commentRepositoryProvider.overrideWithValue(mockCommentRepo),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: () {
                        TimelineUnifiedAnnounceDialog.show(
                          context,
                          ref,
                          'test_tournament_1',
                          '小学生の部',
                          'リーグA',
                          1.0,
                        );
                      },
                      child: const Text('ダイアログを開く'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // ダイアログを開く
        await tester.tap(find.text('ダイアログを開く'));
        await tester.pumpAndSettle();

        // 3つの選択肢チップが存在することを確認
        expect(find.text('全員に通知'), findsOneWidget);
        expect(find.text('スタッフ限定'), findsOneWidget);
        expect(find.text('通知なし'), findsOneWidget);

        // テキストを入力
        await tester.enterText(
          find.widgetWithText(TextField, 'タイトル（例：【緊急】会場変更）'),
          '第3コート移動',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'アナウンス本文内容'),
          '順延のため第3コートで開始します',
        );
        await tester.pumpAndSettle();

        // 「🔕 通知なし」チップを選択
        await tester.tap(find.byKey(const Key('timeline_target_none_chip')));
        await tester.pumpAndSettle();

        // ボタンの文言が「コメントを保存」に切り替わること
        expect(find.text('コメントを保存'), findsOneWidget);

        // 「コメントを保存」ボタンをタップ
        await tester.tap(
          find.byKey(const Key('timeline_submit_announce_button')),
        );
        await tester.pumpAndSettle();

        // ダイアログが閉じること
        expect(find.text('公式アナウンス・コメントの一斉発信'), findsNothing);

        // Firestoreの announcements コレクションには追加されていないこと（通知なし）
        final announceDocs = await fakeFirestore
            .collection('announcements')
            .get();
        expect(announceDocs.docs.isEmpty, isTrue);

        // コメントリポジトリの saveComment は呼ばれていること
        verify(() => mockLocalCommentRepo.saveComment(any())).called(1);
      },
    );

    testWidgets(
      '2. 「📢 全員」または「🔒 スタッフ」を選択して保存した場合は、Firestoreの announcements とコメントの双方が作成されること',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              firestoreProvider.overrideWithValue(fakeFirestore),
              localCommentRepositoryProvider.overrideWithValue(
                mockLocalCommentRepo,
              ),
              commentRepositoryProvider.overrideWithValue(mockCommentRepo),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: () {
                        TimelineUnifiedAnnounceDialog.show(
                          context,
                          ref,
                          'test_tournament_1',
                          '小学生の部',
                          'リーグA',
                          1.0,
                        );
                      },
                      child: const Text('ダイアログを開く'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // ダイアログを開く
        await tester.tap(find.text('ダイアログを開く'));
        await tester.pumpAndSettle();

        // デフォルトは「一斉発信して保存」
        expect(find.text('一斉発信して保存'), findsOneWidget);

        // テキストを入力
        await tester.enterText(
          find.widgetWithText(TextField, 'タイトル（例：【緊急】会場変更）'),
          '【緊急】全員集合',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'アナウンス本文内容'),
          '開会式のため本部前へ集合してください',
        );
        await tester.pumpAndSettle();

        // 「一斉発信して保存」ボタンをタップ
        await tester.tap(
          find.byKey(const Key('timeline_submit_announce_button')),
        );
        await tester.pumpAndSettle();

        // Firestoreの announcements コレクションに発信データが保存されていること
        final announceDocs = await fakeFirestore
            .collection('announcements')
            .get();
        expect(announceDocs.docs.length, 1);
        expect(announceDocs.docs.first.data()['title'], '【緊急】全員集合');
        expect(announceDocs.docs.first.data()['body'], '開会式のため本部前へ集合してください');
        expect(announceDocs.docs.first.data()['target'], 'all');

        // コメントリポジトリの saveComment も呼ばれていること
        verify(() => mockLocalCommentRepo.saveComment(any())).called(1);
      },
    );

    testWidgets(
      '3. 「🔒 スタッフ限定」を選択して保存した場合は、target: "staff" として Firestore に保存されること',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              firestoreProvider.overrideWithValue(fakeFirestore),
              localCommentRepositoryProvider.overrideWithValue(
                mockLocalCommentRepo,
              ),
              commentRepositoryProvider.overrideWithValue(mockCommentRepo),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: () {
                        TimelineUnifiedAnnounceDialog.show(
                          context,
                          ref,
                          'test_tournament_1',
                          '一般の部',
                          'リーグB',
                          2.0,
                        );
                      },
                      child: const Text('ダイアログを開く'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('ダイアログを開く'));
        await tester.pumpAndSettle();

        // 「スタッフ限定」チップを選択
        await tester.tap(find.byKey(const Key('timeline_target_staff_chip')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'アナウンス本文内容'),
          '審判員は本部へ集合してください',
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('timeline_submit_announce_button')),
        );
        await tester.pumpAndSettle();

        final announceDocs = await fakeFirestore
            .collection('announcements')
            .get();
        expect(announceDocs.docs.length, 1);
        expect(announceDocs.docs.first.data()['target'], 'staff');
        expect(announceDocs.docs.first.data()['title'], '大会本部からのお知らせ');
        expect(announceDocs.docs.first.data()['body'], '審判員は本部へ集合してください');

        verify(() => mockLocalCommentRepo.saveComment(any())).called(1);
      },
    );

    testWidgets(
      '4. 【文字切れ・はみ出しゼロ保証】 320x568 の小型端末サイズでも3つの選択肢がOverflowなく完全に描画されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              firestoreProvider.overrideWithValue(fakeFirestore),
              localCommentRepositoryProvider.overrideWithValue(
                mockLocalCommentRepo,
              ),
              commentRepositoryProvider.overrideWithValue(mockCommentRepo),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: () {
                        TimelineUnifiedAnnounceDialog.show(
                          context,
                          ref,
                          'test_tournament_1',
                          '小学生の部',
                          'リーグA',
                          1.0,
                        );
                      },
                      child: const Text('ダイアログを開く'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('ダイアログを開く'));
        await tester.pumpAndSettle();

        // 全てのチップとボタンが表示され、例外(Overflow等)が一切発生しないこと
        expect(find.text('全員に通知'), findsOneWidget);
        expect(find.text('スタッフ限定'), findsOneWidget);
        expect(find.text('通知なし'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
