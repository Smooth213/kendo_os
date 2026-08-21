import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/admin/presentation/components/master_edit_organization_bottom_sheet.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  testWidgets(
    'MasterEditOrganizationBottomSheet displays fields and update button',
    (tester) async {
      final samplePlayer = PlayerModel(
        id: 'p1',
        lastName: '山田',
        firstName: '太郎',
        lastNameKana: 'ヤマダ',
        firstNameKana: 'タロウ',
        grade: 1,
        organization: '旧道場',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MasterEditOrganizationBottomSheet(
                currentName: '旧道場',
                players: [samplePlayer],
              ),
            ),
          ),
        ),
      );

      expect(find.text('所属名の変更'), findsOneWidget);
      expect(find.text('新しい道場名・学校名'), findsOneWidget);
      expect(find.text('一括更新'), findsOneWidget);
    },
  );
}
