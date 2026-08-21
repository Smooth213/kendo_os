import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/admin/presentation/components/master_organization_header_bar.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  group('MasterManagement Components Tests', () {
    testWidgets('MasterOrganizationHeaderBar renders correctly', (
      tester,
    ) async {
      final player = PlayerModel(
        id: 'p1',
        lastName: '山田',
        firstName: '太郎',
        lastNameKana: 'ヤマダ',
        firstNameKana: 'タロウ',
        grade: 5,
        organization: '練馬道場',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MasterOrganizationHeaderBar(
              orgName: '練馬道場',
              players: [player],
              groupingMode: 0,
              isSelectionMode: false,
              isReadOnly: false,
              canManageMaster: true,
              isDark: false,
              primaryColor: Colors.purple,
              onGroupingModeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('練馬道場'), findsOneWidget);
      expect(find.text('学年別'), findsOneWidget);
      expect(find.text('カテゴリ別'), findsOneWidget);
    });
  });
}
