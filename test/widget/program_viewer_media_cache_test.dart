import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_media_cache.dart';

void main() {
  group('[Widget] ProgramViewerMediaCache 単体テスト', () {
    test(
      'ProgramViewerMediaCache handles placeholder image sizesであること',
      () async {
        final cache = ProgramViewerMediaCache();
        final size = await cache.getCachedImageSize(
          'https://placehold.co/400x600',
        );
        expect(size, const Size(400, 600));
      },
    );

    test('ProgramViewerMediaCache handles empty URLであること', () async {
      final cache = ProgramViewerMediaCache();
      final size = await cache.getCachedImageSize('');
      expect(size, const Size(400, 600));
    });
  });
}
