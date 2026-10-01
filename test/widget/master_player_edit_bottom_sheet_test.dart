import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/admin/presentation/components/master_player_edit_bottom_sheet.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  testWidgets('選手編集ボトムシートに選手登録フィールド群が正しく描画されること', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MasterPlayerEditBottomSheet(cloudDojoName: 'テスト道場'),
          ),
        ),
      ),
    );

    expect(find.text('新しい選手を登録'), findsOneWidget);
    expect(find.text('名字'), findsOneWidget);
    expect(find.text('名前'), findsOneWidget);
    expect(find.text('男子'), findsOneWidget);
    expect(find.text('女子'), findsOneWidget);
    expect(find.text('保存して登録'), findsOneWidget);
  });

  testWidgets('MasterPlayerEditBottomSheetにおいて 既存選手の情報とともに編集モードが表示されること', (
    tester,
  ) async {
    final player = PlayerModel(
      id: 'p1',
      lastName: '佐藤',
      firstName: '次郎',
      lastNameKana: 'サトウ',
      firstNameKana: 'ジロウ',
      grade: 2,
      gender: '男子',
      organization: 'テスト道場',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MasterPlayerEditBottomSheet(
              player: player,
              cloudDojoName: 'テスト道場',
            ),
          ),
        ),
      ),
    );

    expect(find.text('選手情報を編集'), findsOneWidget);
    expect(find.text('佐藤'), findsOneWidget);
    expect(find.text('次郎'), findsOneWidget);
  });
}
