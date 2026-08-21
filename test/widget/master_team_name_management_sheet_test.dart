import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/admin/presentation/components/master_team_name_management_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_name_history_provider.dart';

void main() {
  testWidgets(
    'MasterTeamNameManagementSheet displays team names and input field',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamNameHistoryProvider.overrideWith(
              () => MockTeamNameNotifier(['道場A', '道場B']),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MasterTeamNameManagementSheet(orgName: 'テスト組織'),
            ),
          ),
        ),
      );

      expect(find.text('チーム名の管理'), findsOneWidget);
      expect(find.text('道場A'), findsOneWidget);
      expect(find.text('道場B'), findsOneWidget);
      expect(find.text('追加'), findsOneWidget);
    },
  );
}

class MockTeamNameNotifier extends TeamNameHistoryNotifier {
  final List<String> initial;
  MockTeamNameNotifier(this.initial) : super();

  @override
  List<String> build() => initial;

  @override
  Future<void> addName(String name, String orgName) async {
    state = [...state, name];
  }

  @override
  Future<void> deleteName(String name, String orgName) async {
    state = state.where((item) => item != name).toList();
  }
}
