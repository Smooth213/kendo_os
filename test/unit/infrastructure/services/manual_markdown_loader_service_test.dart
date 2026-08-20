import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/infrastructure/services/manual_markdown_loader_service.dart';

void main() {
  group('🛡️ ManualMarkdownLoaderService Tests', () {
    const service = ManualMarkdownLoaderService();

    test('resolvePath correctly rewrites legacy and shorthand paths', () {
      expect(
        service.resolvePath('docs/manuals/guide.md'),
        'packages/documentation_runtime/manuals/guide.md',
      );
      expect(
        service.resolvePath('viewer_faq.md'),
        'packages/documentation_runtime/manuals/faq/viewer_faq.md',
      );
      expect(
        service.resolvePath('operator_faq.md'),
        'packages/documentation_runtime/manuals/faq/operator_faq.md',
      );
      expect(
        service.resolvePath(
          'packages/documentation_runtime/manuals/quickstart.md',
        ),
        'packages/documentation_runtime/manuals/quickstart.md',
      );
    });
  });
}
