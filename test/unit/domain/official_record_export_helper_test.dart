import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_export_helper.dart';

void main() {
  group('[Unit] 公式記録エクスポート多重制御および遅延ロードヘルパー単体テスト', () {
    testWidgets('handleExportにおいて二重タップが抑止され処理中フラグが適切に管理されること', (
      WidgetTester tester,
    ) async {
      late BuildContext capturedContext;
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedContext = context;
                  capturedRef = ref;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      final isExportingController = StateController<bool>(true); // 既に処理中状態
      final exportingTypeController = StateController<String?>(null);

      final match = MatchModel(
        id: 'm-export-1',
        tournamentId: 't-1',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
      );

      // 既に処理中フラグが立っている場合、即時リターンして処理が進行しないこと
      await OfficialRecordExportHelper.handleExport(
        context: capturedContext,
        ref: capturedRef,
        isExportingController: isExportingController,
        exportingTypeController: exportingTypeController,
        sortedGroupKeys: ['グループ1'],
        mergedGroups: {
          'グループ1': [match],
        },
        cat: '一般の部',
        type: 'csv',
        isBottomSheet: true,
      );

      // タイプがセットされず早期リターンしたこと
      expect(exportingTypeController.state, isNull);
    });
  });
}
