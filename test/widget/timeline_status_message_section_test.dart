import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_status_message_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';

void main() {
  group('TimelineStatusMessageSection Tests', () {
    testWidgets('shows error state when hasError is true', (tester) async {
      const SafeTimelineResult result = (
        entries: [],
        isLoading: false,
        hasError: true,
        errorMessage: 'Network error',
        matchedMatchIds: {},
        matchedGroupNames: {},
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimelineStatusMessageSection(
              timelineResult: result,
              sanitizedQuery: '',
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('データの取得に失敗しました'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
    });

    testWidgets('shows empty search query result', (tester) async {
      const SafeTimelineResult result = (
        entries: [],
        isLoading: false,
        hasError: false,
        errorMessage: null,
        matchedMatchIds: {},
        matchedGroupNames: {},
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimelineStatusMessageSection(
              timelineResult: result,
              sanitizedQuery: 'test_query',
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('該当する試合が見つかりません'), findsOneWidget);
    });
  });
}
