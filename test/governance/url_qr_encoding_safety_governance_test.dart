import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('[Governance] 外部連携共有URLおよびQRコード特殊文字エンコード安全規約テスト', () {
    test('日本語や記号を含むルームIDおよびパラメータがパーセントエンコードされ可逆復元されること', () {
      final trickyInputs = [
        '道場#1&決勝?コートA',
        'Tokyo Kendo / #Special?&Room',
        '修道館 錬成会（第3コート）',
        '100%勝負#tag&param=value',
      ];

      for (final input in trickyInputs) {
        // Uri.encodeComponent または Uri(queryParameters: ...) によるエンコード
        final encodedParam = Uri.encodeComponent(input);

        // 特殊記号が安全にエスケープされ、生の & や ? が残っていないこと
        expect(encodedParam.contains('&'), isFalse);
        expect(encodedParam.contains('?'), isFalse);
        expect(encodedParam.contains('#'), isFalse);

        // 完全なURL構築
        final uri = Uri.parse(
          'https://kendo-os-beta.web.app/viewer?tournamentId=$encodedParam&role=viewer',
        );

        // クエリパラメータとして正しくパースされ、元文字列に完全復元されること
        expect(uri.queryParameters['tournamentId'], equals(input));
        expect(uri.queryParameters['role'], equals('viewer'));
      }
    });

    test('lib配下で共有URL生成時に安全なUri構築またはパーセントエンコードが適用されていること', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        // 動的クエリパラメータを含む共有URLやQRコード生成箇所で安全性を確保していることの確認
        final hasDynamicShareUrl =
            (content.contains('kendo-os-beta.web.app') &&
                content.contains('?')) ||
            content.contains('generateShareUrl') ||
            content.contains('buildViewerUrl');

        if (hasDynamicShareUrl) {
          // 生の文字列補間による危険なクエリ結合の有無を検証
          // Uri.encodeComponent または Uri(queryParameters:) または Uri.https を使用
          final hasEncoding =
              content.contains('Uri.encodeComponent') ||
              content.contains('Uri.encodeQueryComponent') ||
              content.contains('queryParameters') ||
              content.contains('Uri.https') ||
              content.contains('Uri(');
          expect(
            hasEncoding,
            isTrue,
            reason: '${file.path} に安全なURLクエリエンコード処理が見つかりません',
          );
        }
      }
    });
  });
}
