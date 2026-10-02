import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:documentation_runtime/manual_routes.dart';

void main() {
  group('[Governance] マニュアルルート整合性およびMarkdown実体存在静的保証テスト', () {
    test('ManualRouteに定義された全ルートの実体Markdownファイルが存在し見出し構文が正常であること', () {
      expect(ManualRoute.values.isNotEmpty, isTrue);

      for (final route in ManualRoute.values) {
        final file = File(route.path);
        // 実体ファイルが存在すること
        expect(
          file.existsSync(),
          isTrue,
          reason: 'ManualRoute.${route.name} の実体ファイル ${route.path} が存在しません',
        );

        final content = file.readAsStringSync();
        // ファイルが空でないこと
        expect(
          content.trim().isNotEmpty,
          isTrue,
          reason: '${route.path} の内容が空です',
        );

        // Markdown見出し構文（# または ##）が含まれていること
        final hasHeading = content
            .split('\n')
            .any((line) => line.trim().startsWith('#'));
        expect(
          hasHeading,
          isTrue,
          reason: '${route.path} に有効なMarkdown見出し（#）が存在しません',
        );

        // fromId で正しく逆引きできること
        expect(ManualRoute.fromId(route.id), equals(route));
      }
    });
  });
}
