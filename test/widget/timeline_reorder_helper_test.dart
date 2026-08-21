import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_reorder_helper.dart';

void main() {
  group('TimelineReorderHelper Tests', () {
    test('TimelineReorderHelper exists and is statically accessible', () {
      expect(TimelineReorderHelper.onReorderInnerTimeline, isNotNull);
      expect(TimelineReorderHelper.onReorderMatches, isNotNull);
      expect(TimelineReorderHelper.onReorderTimeline, isNotNull);
    });
  });
}
