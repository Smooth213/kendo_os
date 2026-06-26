@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_crashlytics_platform_interface/firebase_crashlytics_platform_interface.dart';

import 'package:kendo_os/main.dart' show globalConnectivityProvider;
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';

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

// ==========================================
// 🛡️ PlatformInterface モックによる Firebase の完全同期モック
// ==========================================
class FakeFirebasePlatform extends FirebasePlatform {
  final Map<String, FirebaseAppPlatform> _apps = {};

  Map<dynamic, dynamic> get pluginConstants {
    return const {
      'isCrashlyticsCollectionEnabled': true,
      'firebase_crashlytics': {'isCrashlyticsCollectionEnabled': true},
      '[DEFAULT]': {
        'isCrashlyticsCollectionEnabled': true,
        'firebase_crashlytics': {'isCrashlyticsCollectionEnabled': true},
      },
    };
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    if (!_apps.containsKey(name)) {
      throw FirebaseException(
        plugin: 'core',
        code: 'no-app',
        message:
            "No Firebase App '$name' has been created - call Firebase.initializeApp()",
      );
    }
    return _apps[name]!;
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    final appName = name ?? defaultFirebaseAppName;
    final app = FakeFirebaseAppPlatform(
      appName,
      options ??
          const FirebaseOptions(
            apiKey: 'mock_key_123',
            appId: 'mock_app_123',
            messagingSenderId: 'mock_sender_123',
            projectId: 'mock_project_123',
          ),
    );
    _apps[appName] = app;
    return app;
  }

  @override
  List<FirebaseAppPlatform> get apps => _apps.values.toList();
}

class FakeFirebaseAppPlatform extends FirebaseAppPlatform {
  FakeFirebaseAppPlatform(super.name, super.options);

  Map<dynamic, dynamic> get pluginConstants => const {
    'isCrashlyticsCollectionEnabled': true,
    'firebase_crashlytics': {'isCrashlyticsCollectionEnabled': true},
  };
}

class FakeFirebaseCrashlyticsPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FirebaseCrashlyticsPlatform {
  @override
  bool get isCrashlyticsCollectionEnabled => false;

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future.value();
  }
}

void main() {
  group('🛡️ Offline Resilience & Data Persistence Integration Tests', () {
    // ==========================================
    // 1. UI Test: オフラインバナーの即時点火・消失の完全性 (testWidgetsを使用)
    // ==========================================
    testWidgets('UI Test: オフライン警告バナーの即時点火・消失の完全性検証', (
      WidgetTester tester,
    ) async {
      final connectivityStreamController = StreamController<bool>();

      // MaterialApp の builder と同等のウィジェットをテスト
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            globalConnectivityProvider.overrideWith(
              (ref) => connectivityStreamController.stream,
            ),
          ],
          child: MaterialApp(
            builder: (context, child) {
              if (child == null) return const SizedBox.shrink();
              return Consumer(
                builder: (context, ref, _) {
                  final isOffline =
                      ref.watch(globalConnectivityProvider).value ?? false;
                  return Scaffold(
                    backgroundColor: Colors.black,
                    body: Column(
                      children: [
                        if (isOffline)
                          Container(
                            key: const Key('offline_banner'),
                            width: double.infinity,
                            color: Colors.amber.shade900,
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top + 8,
                              bottom: 8,
                              left: 16,
                              right: 16,
                            ),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.wifi_off_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '⚠️ 体育館オフライン運営モード：ローカルDB（Isar）へ即時保存中',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(child: child),
                      ],
                    ),
                  );
                },
              );
            },
            home: const Scaffold(body: Text('メインコンテンツ')),
          ),
        ),
      );

      // 初期状態：バナーは非表示
      await tester.pump();
      expect(find.byKey(const Key('offline_banner')), findsNothing);

      // [切断状態へモック] 0.5秒以内にバナーが表示されることを検証
      connectivityStreamController.add(true);
      await tester.pump(const Duration(milliseconds: 100)); // 0.1秒進める
      expect(find.byKey(const Key('offline_banner')), findsOneWidget);
      expect(find.textContaining('体育館オフライン運営モード'), findsOneWidget);

      // [接続状態へ復旧] 0.5秒以内にバナーが消失することを検証
      connectivityStreamController.add(false);
      await tester.pump(const Duration(milliseconds: 100)); // 0.1秒進める
      expect(find.byKey(const Key('offline_banner')), findsNothing);

      await connectivityStreamController.close();
    });

    // ==========================================
    // 2. Data Persistence Test: Isar保存確約と緊急バックアップ (通常のtestを使用しハングを根治)
    // ==========================================
    group('Data Persistence Tests', () {
      late Isar isar;
      late LocalMatchRepository repository;
      late Directory tempDir;
      late Directory documentsDir;

      setUpAll(() async {
        // ネットワーク通信をシミュレートする場合、HttpOverridesをnullにするか、
        // 特定のMockクライアントを用意してください。
        HttpOverrides.global = null; // 物理通信をシミュレート可能にする

        // Firebase Platform の差し替えを行い、initializeApp() を安全に成功させる
        FirebasePlatform.instance = FakeFirebasePlatform();
        await Firebase.initializeApp();

        // Crashlytics プラットフォームを Fake に差し替える
        FirebaseCrashlyticsPlatform.instance =
            FakeFirebaseCrashlyticsPlatform();
      });

      setUp(() async {
        try {
          await Isar.initializeIsarCore(download: true);
        } catch (_) {}

        tempDir = Directory.systemTemp.createTempSync(
          'isar_offline_persistence_test_',
        );
        documentsDir = Directory.systemTemp.createTempSync('documents_mock_');

        // path_provider を FakePathProviderPlatform でモックする
        PathProviderPlatform.instance = FakePathProviderPlatform(
          documentsDir.path,
        );

        isar = await Isar.open(
          [MatchEntitySchema],
          directory: tempDir.path,
          name:
              'offline_resilience_test_db_${DateTime.now().microsecondsSinceEpoch}',
          inspector: false,
        );
        repository = LocalMatchRepository(isar);
      });

      tearDown(() async {
        if (isar.isOpen) {
          await isar.close(deleteFromDisk: true);
        }
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
        if (documentsDir.existsSync()) {
          documentsDir.deleteSync(recursive: true);
        }
      });

      test('Isar保存確約テスト（正常系）: オフライン保存されPending状態としてDB内に存在する', () async {
        final match = const MatchModel(
          id: 'test_persistence_success_1',
          tournamentId: 'test_tournament_1',
          redName: '赤選手',
          whiteName: '白選手',
          matchType: '個人戦',
          status: 'in_progress',
          syncState: SyncState.localOnly, // 未同期（Pending）状態を指定
        );

        // 保存を実行
        await repository.saveMatch(match);

        // 直接Isarをクエリしてデータが存在することを確認
        final entityInIsar = await isar.matchEntitys
            .filter()
            .firestoreIdEqualTo('test_persistence_success_1')
            .findFirst();

        expect(entityInIsar, isNotNull);
        expect(entityInIsar!.redName, '赤選手');
        expect(
          entityInIsar.syncState,
          SyncState.localOnly,
        ); // Pending状態であることをアサート
      });

      test(
        '緊急JSONバックアップ生成テスト（異常系）: DB保存失敗時に緊急JSONバックアップファイルが物理ディスク上に生成される',
        () async {
          final match = const MatchModel(
            id: 'test_persistence_failure_1',
            tournamentId: 'test_tournament_1',
            redName: '赤選手',
            whiteName: '白選手',
            matchType: '個人戦',
            status: 'in_progress',
            syncState: SyncState.localOnly,
          );

          // Isar インスタンスを意図的にクローズして保存エラーを誘発させる
          await isar.close();

          // 保存実行が失敗し、例外がスローされることを確認
          bool hasThrown = false;
          try {
            await repository.saveMatch(match);
          } catch (e) {
            hasThrown = true;
            debugPrint(
              '🔥 [DEBUG TEST] FirebasePlatform.instance type during exception: ${FirebasePlatform.instance.runtimeType}',
            );
            debugPrint('🔥 [DEBUG TEST] CAUGHT EXCEPTION: $e');
          }
          expect(hasThrown, true, reason: 'ローカルDBクローズのため例外がスローされること');

          // documentsDir 内に緊急バックアップファイルが生成されているかチェック
          final files = documentsDir.listSync();
          final emergencyBackupFiles = files.where((file) {
            return file is File &&
                file.path.contains(
                  'emergency_backup_test_persistence_failure_1',
                );
          }).toList();

          expect(
            emergencyBackupFiles.isNotEmpty,
            true,
            reason: '緊急JSONバックアップファイルが物理ディスク上に作成されていること',
          );

          // 生成されたバックアップファイルの整合性を検証
          final backupFile = emergencyBackupFiles.first as File;
          final fileContent = await backupFile.readAsString();
          final backupJson = jsonDecode(fileContent) as Map<String, dynamic>;

          expect(backupJson['id'], 'test_persistence_failure_1');
          expect(backupJson['redName'], '赤選手');
          expect(backupJson['syncState'], 'localOnly');
        },
      );
    });
  });
}
