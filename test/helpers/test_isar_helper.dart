import 'dart:ffi';
import 'dart:io';
import 'package:isar_community/isar.dart';

/// 🛡️ Isarテスト用コンテキスト
/// Isarインスタンスと一時ディレクトリを安全にペア管理し、
/// クローズおよびディレクトリ削除の完全性と二次例外の防止を保証します。
class TestIsarContext {
  final Isar isar;
  final Directory directory;

  TestIsarContext({required this.isar, required this.directory});

  /// データベースと関連ファイルリソースを完全に破棄します。
  /// 例外が発生しても上位に漏洩せず、tearDown/tearDownAll の破綻を防ぎます。
  Future<void> dispose() async {
    try {
      if (isar.isOpen) {
        await isar.close(deleteFromDisk: true);
      }
    } catch (_) {
      // クローズ時の例外は安全に吸収
    }

    try {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    } catch (_) {
      // ディレクトリ削除時の例外は安全に吸収
    }
  }

  /// データベース内の全コレクションをクリアします。
  /// 各テストケース実行前の初期化（setUp）に便利です。
  Future<void> clear() async {
    if (isar.isOpen) {
      await isar.writeTxn(() => isar.clear());
    }
  }
}

/// 🛡️ Isarテスト共通ヘルパー
/// Linux CI（GitHub Actions）やローカルテスト環境におけるバイナリDL問題、
/// ポート衝突、ディレクトリ衝突、LateInitializationError を根絶します。
class TestIsarHelper {
  TestIsarHelper._();

  static bool _isCoreInitialized = false;

  /// IsarCoreバイナリのロードを確実に保証します。
  /// Linux CI（GitHub Actions）やローカルテスト環境におけるバイナリDL問題、
  /// 動的リンク探索パス不一致、LateInitializationError を根絶します。
  static Future<void> ensureInitialized() async {
    if (_isCoreInitialized) return;

    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    try {
      if (Platform.isLinux) {
        final currentDir = Directory.current.path;
        final candidatePaths = [
          '$currentDir/libisar.so',
          '$currentDir/libisar_linux_x64.so',
          '/usr/lib/x86_64-linux-gnu/libisar.so',
          '/usr/lib/x86_64-linux-gnu/libisar_linux_x64.so',
          '/usr/lib/libisar.so',
          '/usr/lib/libisar_linux_x64.so',
          '/usr/local/lib/libisar.so',
        ];

        String? validPath;
        for (final p in candidatePaths) {
          if (File(p).existsSync()) {
            validPath = p;
            break;
          }
        }

        if (validPath != null) {
          await Isar.initializeIsarCore(
            libraries: {Abi.linuxX64: validPath},
            download: false,
          );
          _isCoreInitialized = true;
          return;
        }

        // バイナリがローカルにない場合、カレントディレクトリへ直接DLを試行
        try {
          final fallbackFile = File('$currentDir/libisar.so');
          final client = HttpClient();
          final request = await client.getUrl(
            Uri.parse(
              'https://binaries.isar-community.dev/3.3.2/libisar_linux_x64.so',
            ),
          );
          final response = await request.close();
          if (response.statusCode == 200) {
            await response.pipe(fallbackFile.openWrite());
            await Isar.initializeIsarCore(
              libraries: {Abi.linuxX64: fallbackFile.path},
              download: false,
            );
            _isCoreInitialized = true;
            return;
          }
        } catch (_) {
          // 直接DL失敗時は標準初期化へフォールバック
        }
      }

      await Isar.initializeIsarCore(download: true);
      _isCoreInitialized = true;
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [TestIsarHelper] initializeIsarCore warning: $e');
    } finally {
      HttpOverrides.global = previousOverrides;
    }
  }

  /// テスト用の独立したIsarコンテキストをオープンします。
  ///
  /// - ユニークな一時ディレクトリを作成
  /// - インスペクターを無効化（ポート衝突防止）
  /// - カスタムMMAP設定やコンパクション設定に対応
  static Future<TestIsarContext> openContext({
    required List<CollectionSchema<dynamic>> schemas,
    String prefix = 'test_isar',
    String? name,
    int? maxSizeMiB,
    bool? relaxedDurability,
    CompactCondition? compactOnLaunch,
  }) async {
    await ensureInitialized();

    final tempDir = Directory.systemTemp.createTempSync('${prefix}_');
    final dbName = name ?? '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

    final isar = await Isar.open(
      schemas,
      directory: tempDir.path,
      name: dbName,
      inspector: false,
      maxSizeMiB: maxSizeMiB ?? Isar.defaultMaxSizeMiB,
      relaxedDurability: relaxedDurability ?? true,
      compactOnLaunch: compactOnLaunch,
    );

    return TestIsarContext(isar: isar, directory: tempDir);
  }
}
