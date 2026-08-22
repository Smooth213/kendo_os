import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/admin/presentation/components/master_organization_header_bar.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('MasterManagement Components Tests', () {
    final player = PlayerModel(
      id: 'p1',
      lastName: '山田',
      firstName: '太郎',
      lastNameKana: 'ヤマダ',
      firstNameKana: 'タロウ',
      grade: 5,
      organization: '練馬道場',
    );

    testWidgets('MasterOrganizationHeaderBar renders correctly in light mode', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: MasterOrganizationHeaderBar(
              orgName: '練馬道場',
              players: [player],
              groupingMode: 0,
              isSelectionMode: false,
              isReadOnly: false,
              canManageMaster: true,
              isDark: false,
              primaryColor: AppKendoColors.indigo,
              onGroupingModeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('練馬道場'), findsOneWidget);
      expect(find.text('学年別'), findsOneWidget);
      expect(find.text('カテゴリ別'), findsOneWidget);
    });

    testWidgets('MasterOrganizationHeaderBar renders correctly in dark mode', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: MasterOrganizationHeaderBar(
              orgName: '練馬道場',
              players: [player],
              groupingMode: 1,
              isSelectionMode: false,
              isReadOnly: false,
              canManageMaster: true,
              isDark: true,
              primaryColor: AppKendoColors.purpleAccent,
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
