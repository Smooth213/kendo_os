import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kendo_os/features/tournament/presentation/operate/helpers/clipboard_program_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('📋 【大会プログラム】クリップボード吸い上げヘルパー検証テスト', () {
    test('有効なPDFのURLから正しく PlatformFile を生成できること', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString() ==
            'https://example.com/tournaments/program2026.pdf') {
          return http.Response.bytes(
            utf8.encode('%PDF-1.4 dummy pdf content'),
            200,
            headers: {'content-type': 'application/pdf'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final helper = ClipboardProgramHelper(httpClient: mockClient);
      final file = await helper.extractFileFromUrl(
        'https://example.com/tournaments/program2026.pdf',
      );

      expect(file, isNotNull);
      expect(file!.name, equals('program2026.pdf'));
      expect(file.bytes, isNotNull);
      expect(file.bytes!.length, greaterThan(0));
    });

    test('有効な画像URL (PNG) から正しく PlatformFile を生成できること', () async {
      final dummyPngBytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);
      final mockClient = MockClient((request) async {
        if (request.url.toString() ==
            'https://example.com/images/schedule.png') {
          return http.Response.bytes(
            dummyPngBytes,
            200,
            headers: {'content-type': 'image/png'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final helper = ClipboardProgramHelper(httpClient: mockClient);
      final file = await helper.extractFileFromUrl(
        'https://example.com/images/schedule.png',
      );

      expect(file, isNotNull);
      expect(file!.name, equals('schedule.png'));
      expect(file.bytes, equals(dummyPngBytes));
    });

    test('HTTPステータスが404または500の場合は null を返却すること', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Error', 500);
      });

      final helper = ClipboardProgramHelper(httpClient: mockClient);
      final file = await helper.extractFileFromUrl(
        'https://example.com/invalid.pdf',
      );

      expect(file, isNull);
    });

    test('HTMLなど非PDF・非画像ファイルが返却された場合は安全に null を返却すること', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '<html><body>Web Page</body></html>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });

      final helper = ClipboardProgramHelper(httpClient: mockClient);
      final file = await helper.extractFileFromUrl(
        'https://example.com/index.html',
      );

      expect(file, isNull);
    });

    test('Google Drive や Dropbox の共有URLを直接ダウンロードリンクへ正規化できること', () {
      final helper = ClipboardProgramHelper();

      // Google Drive
      final gDrive = helper.normalizeUrl(
        'https://drive.google.com/file/d/1A2B3C4D5E/view?usp=sharing',
      );
      expect(
        gDrive,
        equals('https://drive.google.com/uc?export=download&id=1A2B3C4D5E'),
      );

      // Dropbox
      final dropbox = helper.normalizeUrl(
        'https://www.dropbox.com/s/xyz123/program.pdf?dl=0',
      );
      expect(
        dropbox,
        equals('https://www.dropbox.com/s/xyz123/program.pdf?dl=1'),
      );
    });
  });
}
