import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_management_content_views.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ ProgramManagement Extracted Components Tests', () {
    final programs = [
      ProgramModel(
        id: 'p1',
        tournamentId: 't1',
        title: '進行表',
        fileUrl: 'https://example.com/file.pdf',
        fileType: 'pdf',
        createdAt: DateTime.now(),
      ),
    ];

    testWidgets('1. ProgramManagementContentViews renders list view', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ProgramManagementContentViews.buildListView(
                context: context,
                programs: programs,
                getSafeUrl: (url) => url,
                onDelete: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('進行表'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('2. ProgramManagementContentViews renders grid view', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ProgramManagementContentViews.buildGridView(
                context: context,
                programs: programs,
                getSafeUrl: (url) => url,
                onDelete: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('進行表'), findsOneWidget);
    });
  });
}
