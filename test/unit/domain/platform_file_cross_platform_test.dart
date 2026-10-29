import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/platform/platform_file.dart';
import 'package:kendo_os/shared/platform/platform_file_stub.dart' as stub;

void main() {
  group('[Unit] PlatformFile クロスプラットフォーム抽象レイヤー検証テスト', () {
    test('ネイティブ実行環境においてPlatformFileがioのFileとしてパスと基本機能を保持すること', () async {
      final tempDir = await io.Directory.systemTemp.createTemp(
        'platform_file_test',
      );
      final testFilePath = '${tempDir.path}/test_sample.txt';
      final file = PlatformFile(testFilePath);

      expect(file.path, equals(testFilePath));
      expect(await file.exists(), isFalse);

      final realIoFile = io.File(testFilePath);
      await realIoFile.writeAsBytes(Uint8List.fromList([1, 2, 3, 4]));
      expect(await file.exists(), isTrue);

      final bytes = await file.readAsBytes();
      expect(bytes, equals(Uint8List.fromList([1, 2, 3, 4])));

      await tempDir.delete(recursive: true);
    });

    test('Webスタブ環境向けPlatformFileが安全に空データと存在偽を非同期で返却すること', () async {
      final stubFile = stub.PlatformFile('/virtual/path/mock_export.pdf');

      expect(stubFile.path, equals('/virtual/path/mock_export.pdf'));

      final exists = await stubFile.exists();
      expect(exists, isFalse);

      final bytes = await stubFile.readAsBytes();
      expect(bytes, isEmpty);
      expect(bytes, isA<Uint8List>());
    });

    test('空文字パスや特殊文字を含むパスでも例外なく安全にインスタンス生成できること', () {
      final emptyStub = stub.PlatformFile('');
      expect(emptyStub.path, isEmpty);

      const specialPath =
          '/var/mobile/Containers/Data/Application/123-ABC/tmp/全角漢字_100%_#&.csv';
      final specialStub = stub.PlatformFile(specialPath);
      expect(specialStub.path, equals(specialPath));
    });
  });
}
