import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_material_placeholder.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';

void main() {
  testWidgets(
    'ProgramViewerMaterialPlaceholder renders title and material info text',
    (WidgetTester tester) async {
      final program = ProgramModel(
        id: 'prog1',
        tournamentId: 't1',
        title: '大会パンフレット 表紙',
        fileUrl: '',
        fileType: 'pdf',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgramViewerMaterialPlaceholder(
              program: program,
              isDark: false,
            ),
          ),
        ),
      );

      // Verify title and material text
      expect(find.text('大会パンフレット 表紙'), findsOneWidget);
      expect(find.textContaining('材料データ同期済み'), findsOneWidget);
    },
  );
}
