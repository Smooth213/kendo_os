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
  /// TestWidgetsFlutterBinding 有効化環境でも HttpOverrides を一時解除し、
  /// CI Linux 環境でのバイナリ自動ダウンロード (400 Bad Request) を回避します。
  static Future<void> ensureInitialized() async {
    if (_isCoreInitialized) return;

    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    try {
      await Isar.initializeIsarCore(download: true);
      _isCoreInitialized = true;
    } catch (_) {
      // 既にバイナリが存在する場合やロード失敗は安全に吸収
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
