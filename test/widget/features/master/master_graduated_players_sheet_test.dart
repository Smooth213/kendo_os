import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/safe_pump_helper.dart';
import 'package:kendo_os/admin/presentation/components/master_graduated_players_sheet.dart';
import 'package:kendo_os/admin/presentation/components/master_menu_bottom_sheet.dart';
import 'package:kendo_os/admin/presentation/screens/master_management_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] MasterGraduatedPlayersSheet 卒業・OB/OG名簿シートテスト', () {
    testWidgets('卒業生が卒業年度ごとにグループ表示され、現役復帰で名簿から移動すること', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      const dojoId = 'test_dojo';
      await fakeFirestore
          .collection('organizations')
          .doc(dojoId)
          .collection('players')
          .doc('ob_1')
          .set(
            PlayerModel(
              id: 'ob_1',
              lastName: '先輩',
              firstName: '太郎',
              lastNameKana: 'センパイ',
              firstNameKana: 'タロウ',
              grade: 9,
              status: PlayerModel.statusGraduated,
              graduatedFiscalYear: 2026,
            ).toMap(),
          );
      await fakeFirestore
          .collection('organizations')
          .doc(dojoId)
          .collection('players')
          .doc('active_1')
          .set(
            PlayerModel(
              id: 'active_1',
              lastName: '現役',
              firstName: '花子',
              lastNameKana: 'ゲンエキ',
              firstNameKana: 'ハナコ',
              grade: 8,
            ).toMap(),
          );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreProvider.overrideWithValue(fakeFirestore),
            currentDojoIdProvider.overrideWith((ref) => dojoId),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: const Scaffold(body: MasterGraduatedPlayersSheet()),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.text('卒業・OB/OG名簿'), findsOneWidget);
      expect(find.text('2026年度卒'), findsNWidgets(2));
      expect(find.text('先輩 太郎'), findsOneWidget);
      expect(find.text('現役 花子'), findsNothing);

      // 左スワイプで「復帰」アクションを表示してタップ
      await tester.drag(find.text('先輩 太郎'), const Offset(-300, 0));
      await tester.safePumpAndSettle();

      expect(find.text('復帰'), findsOneWidget);
      await tester.tap(find.text('復帰'));
      await tester.safePumpAndSettle();

      expect(find.text('現役への復帰'), findsOneWidget);
      await tester.tap(find.text('高校1年 で復帰'));
      await tester.safePumpAndSettle();

      final restoredDoc = await fakeFirestore
          .collection('organizations')
          .doc(dojoId)
          .collection('players')
          .doc('ob_1')
          .get();
      expect(restoredDoc.data()?['status'], equals(PlayerModel.statusActive));
      expect(restoredDoc.data()?['grade'], equals(10));
      expect(find.text('先輩 太郎'), findsNothing);
    });

    testWidgets('MasterMenuBottomSheetから卒業・OB/OG名簿シートへ遷移できること', (tester) async {
      final players = [
        PlayerModel(
          id: 'ob_1',
          lastName: '先輩',
          firstName: '一郎',
          lastNameKana: 'センパイ',
          firstNameKana: 'イチロウ',
          grade: 9,
          status: PlayerModel.statusGraduated,
          graduatedFiscalYear: 2025,
        ),
      ];
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerListProvider.overrideWith((ref) => Stream.value(players)),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => MasterMenuBottomSheet.show(context, ref),
                  child: const Text('メニュー開く'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('メニュー開く'));
      await tester.safePumpAndSettle();

      expect(find.text('卒業・OB/OG名簿（1名）'), findsOneWidget);
      await tester.tap(find.text('卒業・OB/OG名簿（1名）'));
      await tester.safePumpAndSettle();

      expect(find.text('先輩 一郎'), findsOneWidget);
      expect(find.text('2025年度卒'), findsNWidgets(2));
    });
  });
}
