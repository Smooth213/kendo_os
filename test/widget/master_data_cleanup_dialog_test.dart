import 'dart:convert';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import 'package:kendo_os/admin/presentation/components/master_data_cleanup_dialog.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/security/security_level.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/security_level_provider.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String _documentsPath;
  FakePathProviderPlatform(this._documentsPath);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return _documentsPath;
  }
}

class FakeSharePlatform extends Fake
    with MockPlatformInterfaceMixin
    implements SharePlatform {
  ShareParams? lastParams;

  @override
  Future<ShareResult> share(ShareParams params) async {
    lastParams = params;
    return const ShareResult('success', ShareResultStatus.success);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late FakeSharePlatform fakeShare;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cleanup_dialog_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);

    // MethodChannelのモック（macOS/iOS両方のチャンネルに対応）
    for (final channelName in [
      'plugins.flutter.io/path_provider',
      'plugins.flutter.io/path_provider_macos',
      'plugins.flutter.io/path_provider_foundation',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channelName), (call) async {
            return tempDir.path;
          });
    }

    fakeShare = FakeSharePlatform();
    SharePlatform.instance = fakeShare;

    fakeFirestore = FakeFirebaseFirestore();
    MasterDataCleanupDialog.customDirectory = tempDir;
  });

  tearDown(() async {
    MasterDataCleanupDialog.customDirectory = null;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> openDialog(
    WidgetTester tester, {
    List<MatchModel> matches = const [],
    UserRole role = UserRole.admin,
    TournamentRepository? tournamentRepo,
  }) async {
    final repo =
        tournamentRepo ??
        TournamentRepository(dojoId: 'test-dojo', firestore: fakeFirestore);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matchListProvider.overrideWith((ref) => matches),
          currentUserRoleProvider.overrideWithValue(role),
          securityLevelProvider.overrideWith((ref) => SecurityLevel.open),
          tournamentRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: ctx,
                      builder: (_) => const MasterDataCleanupDialog(),
                    );
                  },
                  child: const Text('ダイアログを開く'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('ダイアログを開く'));
    await tester.pumpAndSettle();
  }

  group('MasterDataCleanupDialog 動作保証テスト要塞', () {
    testWidgets('1. ダイアログ表示: タイトルおよび3つの管理オプションが表示されること', (tester) async {
      await openDialog(tester);

      expect(find.text('データとストレージ管理'), findsOneWidget);
      expect(find.text('一時キャッシュをクリア'), findsOneWidget);
      expect(find.text('全データをJSONでバックアップ'), findsOneWidget);
      expect(find.text('1年以上前の大会を削除'), findsOneWidget);
      expect(find.text('閉じる'), findsOneWidget);
    });

    testWidgets('2. キャッシュの削除: 実行タップで画像キャッシュがクリアされ成功通知が表示されること', (tester) async {
      await openDialog(tester);

      // キャッシュクリアの「実行」ボタンを検索
      final executeButton = find.widgetWithText(ElevatedButton, '実行');
      expect(executeButton, findsOneWidget);

      await tester.tap(executeButton);
      await tester.pumpAndSettle();

      // スナックバーの通知メッセージが表示されることを確認
      expect(find.text('キャッシュをクリアし、メモリを解放しました ✨'), findsOneWidget);
      // ダイアログが閉じていること
      expect(find.text('データとストレージ管理'), findsNothing);
    });

    testWidgets('3. JSON書き出し: 試合データがJSONファイルとして正しく保存・共有されること', (tester) async {
      final dummyMatch = MatchModel(
        id: 'test-match-123',
        matchType: 'individual',
        tournamentId: 'tour-001',
        category: '一般の部',
        redName: '道上: 山田太郎',
        whiteName: '道上: 鈴木次郎',
        status: 'completed',
        redScore: 2,
        whiteScore: 1,
      );

      await openDialog(tester, matches: [dummyMatch]);

      final exportButton = find.widgetWithText(ElevatedButton, '書き出し');
      await tester.tap(exportButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. スナックバーで成功メッセージが表示されること
      expect(find.textContaining('バックアップ完了'), findsOneWidget);

      // 2. モックディレクトリ内にファイルが実際に生成されたこと
      final files = tempDir.listSync().whereType<File>().toList();
      expect(files.length, 1);
      final backupFile = files.first;
      expect(backupFile.path, contains('kendo_backup_'));
      expect(backupFile.path, endsWith('.json'));

      // 3. ファイル内容のJSONを検証
      final content = backupFile.readAsStringSync();
      final decoded = jsonDecode(content) as List<dynamic>;
      expect(decoded.length, 1);
      expect(decoded.first['id'], 'test-match-123');
      expect(decoded.first['redName'], '道上: 山田太郎');

      // SnackBar消去
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('4. 古いデータの削除: 警告モーダルを経て1年以上前の大会・試合のみが削除されること', (tester) async {
      final repo = TournamentRepository(
        dojoId: 'test-dojo',
        firestore: fakeFirestore,
      );

      // 400日前（1年以上前）の古い大会と試合データを事前作成
      final oldDate = DateTime.now().subtract(const Duration(days: 400));
      final oldTourId = await repo.saveTournament(
        TournamentModel(
          id: 'old-tour-1',
          organizationId: 'test-dojo',
          name: '第1回 過去大会',
          date: oldDate,
          venue: '旧武道館',
        ),
      );
      // 古い大会に紐づく試合データ
      await fakeFirestore
          .collection('organizations')
          .doc('test-dojo')
          .collection('tournaments')
          .doc(oldTourId)
          .collection('matches')
          .doc('old-match-1')
          .set({'id': 'old-match-1', 'redScore': 1});

      // 30日前（最近）の大会と試合データを作成
      final recentDate = DateTime.now().subtract(const Duration(days: 30));
      final recentTourId = await repo.saveTournament(
        TournamentModel(
          id: 'recent-tour-1',
          organizationId: 'test-dojo',
          name: '最新大会',
          date: recentDate,
          venue: '新武道館',
        ),
      );
      await fakeFirestore
          .collection('organizations')
          .doc('test-dojo')
          .collection('tournaments')
          .doc(recentTourId)
          .collection('matches')
          .doc('recent-match-1')
          .set({'id': 'recent-match-1', 'redScore': 2});

      await openDialog(tester, tournamentRepo: repo);

      // 「削除」ボタンをタップ
      final deleteButton = find.widgetWithText(ElevatedButton, '削除');
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // 警告ダイアログが表示されること
      expect(find.text('警告'), findsOneWidget);
      expect(
        find.textContaining('1年以上前の「大会」と「試合データ」をすべて完全に削除します'),
        findsOneWidget,
      );

      // 「完全に削除する」ボタンをタップ
      final confirmButton = find.widgetWithText(ElevatedButton, '完全に削除する');
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // スナックバーで1件削除完了メッセージが表示されること
      expect(
        find.textContaining('1年以上前の大会 1 件とその全試合データを完全に削除しました'),
        findsOneWidget,
      );

      // アニメーションを消化
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Firestoreのデータを直接検証:
      // 1. 古い大会本体が削除されていること
      final oldDoc = await fakeFirestore
          .collection('organizations')
          .doc('test-dojo')
          .collection('tournaments')
          .doc(oldTourId)
          .get();
      expect(oldDoc.exists, isFalse);

      // 2. 古い大会の試合データも削除されていること
      final oldMatchDoc = await fakeFirestore
          .collection('organizations')
          .doc('test-dojo')
          .collection('tournaments')
          .doc(oldTourId)
          .collection('matches')
          .doc('old-match-1')
          .get();
      expect(oldMatchDoc.exists, isFalse);

      // 3. 最近の大会およびその試合データは削除されずに残っていること
      final recentDoc = await fakeFirestore
          .collection('organizations')
          .doc('test-dojo')
          .collection('tournaments')
          .doc(recentTourId)
          .get();
      expect(recentDoc.exists, isTrue);

      final recentMatchDoc = await fakeFirestore
          .collection('organizations')
          .doc('test-dojo')
          .collection('tournaments')
          .doc(recentTourId)
          .collection('matches')
          .doc('recent-match-1')
          .get();
      expect(recentMatchDoc.exists, isTrue);
    });

    testWidgets('5. 古いデータの削除: 対象がない場合は「見つかりませんでした」と表示されること', (tester) async {
      final repo = TournamentRepository(
        dojoId: 'test-dojo',
        firestore: fakeFirestore,
      );

      // 10日前（最近）の大会のみ作成
      await repo.saveTournament(
        TournamentModel(
          id: 'recent-tour-only',
          organizationId: 'test-dojo',
          name: '先週の大会',
          date: DateTime.now().subtract(const Duration(days: 10)),
          venue: '武道館',
        ),
      );

      await openDialog(tester, tournamentRepo: repo);

      await tester.tap(find.widgetWithText(ElevatedButton, '削除'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, '完全に削除する'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1年以上前の大会データは見つかりませんでした ℹ️'), findsOneWidget);
    });
  });
}
