import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:kendo_os/shared/infrastructure/services/manual_download_service.dart';

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

void main() {
  late Directory tempDir;
  late ManualDownloadService downloadService;
  const String testFileName = 'test_manual.pdf';
  const String testUrl = 'https://example.com/test_manual.pdf';

  setUp(() async {
    // 1. テスト用の一時ディレクトリを作成
    tempDir = await Directory.systemTemp.createTemp('manual_test');

    // 2. path_provider をモック
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);

    // 3. サービスを初期化
    downloadService = ManualDownloadService();
  });

  tearDown(() async {
    // 一時ディレクトリのクリーンアップ
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ManualDownloadService Tests', () {
    test(
      'isFileDownloaded should return false when file does not exist',
      () async {
        final exists = await downloadService.isFileDownloaded(testFileName);
        expect(exists, isFalse);
      },
    );

    test(
      'downloadManual should download file and trigger onProgress',
      () async {
        // 1. モックデータを作成 (100バイト)
        final dummyData = List<int>.generate(100, (i) => i);

        // 2. HTTPクライアントをモック
        // http.runWithClient を使ってモッククライアントを注入します
        final mockClient = MockClient((request) async {
          return http.Response.bytes(dummyData, 200);
        });

        final List<double> progressLog = [];

        // 3. モッククライアントを用いて実行 (http.runWithClient)
        final downloadedFile = await http.runWithClient(() async {
          return await downloadService.downloadManual(testFileName, testUrl, (
            progress,
          ) {
            progressLog.add(progress);
          });
        }, () => mockClient);

        // 4. 検証
        expect(downloadedFile, isNotNull);
        expect(await downloadedFile!.exists(), isTrue);
        expect(
          await downloadedFile.readAsBytes(),
          Uint8List.fromList(dummyData),
        );

        // 進捗コールバックが呼ばれたことを検証
        expect(progressLog, isNotEmpty);
        expect(progressLog.last, closeTo(1.0, 0.01));

        // isFileDownloaded が true に変わることを検証
        final exists = await downloadService.isFileDownloaded(testFileName);
        expect(exists, isTrue);
      },
    );

    test(
      'getLocalFile should return File when downloaded, and null otherwise',
      () async {
        // ダウンロード前
        var file = await downloadService.getLocalFile(testFileName);
        expect(file, isNull);

        // 手動でファイルを置いてダウンロード済みに見せかける
        final localFile = File('${tempDir.path}/$testFileName');
        await localFile.writeAsString('dummy content');

        // ダウンロード後
        file = await downloadService.getLocalFile(testFileName);
        expect(file, isNotNull);
        expect(await file!.readAsString(), 'dummy content');
      },
    );

    test('deleteLocalFile should delete the file from storage', () async {
      // 手動でファイルを配置
      final localFile = File('${tempDir.path}/$testFileName');
      await localFile.writeAsString('dummy content');
      expect(await localFile.exists(), isTrue);

      // 削除実行
      await downloadService.deleteLocalFile(testFileName);
      expect(await localFile.exists(), isFalse);
    });
  });
}
