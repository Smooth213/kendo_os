import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_record_export_helper.dart';

void main() {
  group('[Unit] BunaiksenRecordExportHelper 単体テスト', () {
    testWidgets('多重実行抑止フラグがtrueの場合は即時リターンし処理を行わないこと', (tester) async {
      late BuildContext capturedContext;
      late WidgetRef capturedRef;
      final exportingController = StateController<bool>(true);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedContext = context;
                capturedRef = ref;
                return const Scaffold(body: Text('テスト'));
              },
            ),
          ),
        ),
      );

      await BunaiksenRecordExportHelper.handleExport(
        context: capturedContext,
        ref: capturedRef,
        isExportingController: exportingController,
        cat: '一般の部',
        groupsMap: {},
        sortedGroupKeys: [],
        isPdf: true,
      );

      // stateはtrueのまま変更されない
      expect(exportingController.state, isTrue);
    });

    testWidgets('handleExport実行時に進行ダイアログが表示され完了後に状態復元とダイアログ消滅が保証されること', (
      tester,
    ) async {
      late BuildContext capturedContext;
      late WidgetRef capturedRef;
      final exportingController = StateController<bool>(false);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedContext = context;
                capturedRef = ref;
                return const Scaffold(body: Text('ホーム'));
              },
            ),
          ),
        ),
      );

      const matchA = MatchModel(
        id: 'm1',
        matchType: 'individual',
        redName: '選手1',
        whiteName: '選手2',
        order: 2,
      );
      const matchB = MatchModel(
        id: 'm2',
        matchType: 'individual',
        redName: '選手3',
        whiteName: '選手4',
        order: 1,
      );

      // handleExportを開始
      final exportFuture = BunaiksenRecordExportHelper.handleExport(
        context: capturedContext,
        ref: capturedRef,
        isExportingController: exportingController,
        cat: '小学生の部',
        groupsMap: {
          'Aリーグ': [matchA, matchB],
        },
        sortedGroupKeys: ['Aリーグ'],
        isPdf: false,
      );

      await tester.pump();
      // プログレスインジケータが表示されている
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      await exportFuture;

      // 処理完了後、状態がfalseに復帰しダイアログが閉じている
      expect(exportingController.state, isFalse);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
