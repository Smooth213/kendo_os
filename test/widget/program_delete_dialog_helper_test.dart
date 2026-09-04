import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_delete_dialog_helper.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/program_repository.dart';

class MockProgramRepository extends Fake implements ProgramRepository {
  final List<String> deletedIds = [];

  @override
  Future<void> deleteProgram(ProgramModel program) async {
    deletedIds.add(program.id);
  }
}

void main() {
  group('🛡️ ProgramDeleteDialogHelper Tests', () {
    final programs = [
      ProgramModel(
        id: 'p1',
        tournamentId: 't1',
        title: '進行表1',
        fileUrl: 'https://example.com/1.pdf',
        fileType: 'pdf',
        createdAt: DateTime.now(),
      ),
      ProgramModel(
        id: 'p2',
        tournamentId: 't1',
        title: '進行表2',
        fileUrl: 'https://example.com/2.pdf',
        fileType: 'pdf',
        createdAt: DateTime.now(),
      ),
    ];

    testWidgets('confirmSingleDelete shows dialog and executes on confirm', (
      tester,
    ) async {
      final mockRepo = MockProgramRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [programRepositoryProvider.overrideWithValue(mockRepo)],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () {
                      ProgramDeleteDialogHelper.confirmSingleDelete(
                        context: context,
                        ref: ref,
                        program: programs[0],
                      );
                    },
                    child: const Text('削除ボタン'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('削除ボタン'));
      await tester.pumpAndSettle();

      expect(find.text('プログラムの削除'), findsOneWidget);
      expect(find.text('「進行表1」を削除しますか？\nこの操作は取り消せません。'), findsOneWidget);

      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      expect(mockRepo.deletedIds, contains('p1'));
    });

    testWidgets(
      'confirmBulkDelete shows dialog and deletes selected items on confirm',
      (tester) async {
        final mockRepo = MockProgramRepository();
        bool onDeletedCalled = false;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [programRepositoryProvider.overrideWithValue(mockRepo)],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: () {
                        ProgramDeleteDialogHelper.confirmBulkDelete(
                          context: context,
                          ref: ref,
                          allPrograms: programs,
                          selectedProgramIds: {'p1', 'p2'},
                          onDeleted: () {
                            onDeletedCalled = true;
                          },
                        );
                      },
                      child: const Text('一括削除ボタン'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('一括削除ボタン'));
        await tester.pumpAndSettle();

        expect(find.text('プログラムの一括削除'), findsOneWidget);
        expect(
          find.text('選択した 2件のプログラムを削除しますか？\nこの操作は取り消せません。'),
          findsOneWidget,
        );

        await tester.tap(find.text('すべて削除'));
        await tester.pumpAndSettle();

        expect(mockRepo.deletedIds, containsAll(['p1', 'p2']));
        expect(onDeletedCalled, isTrue);
      },
    );
  });
}
