import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_media_cache.dart';

void main() {
  group('🛡️ ProgramViewerMediaCache Unit Tests', () {
    test(
      '1. ProgramViewerMediaCache handles placeholder image sizes',
      () async {
        final cache = ProgramViewerMediaCache();
        final size = await cache.getCachedImageSize(
          'https://placehold.co/400x600',
        );
        expect(size, const Size(400, 600));
      },
    );

    test('2. ProgramViewerMediaCache handles empty URL', () async {
      final cache = ProgramViewerMediaCache();
      final size = await cache.getCachedImageSize('');
      expect(size, const Size(400, 600));
    });
  });
}
