import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/start_screen.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

void main() {
  group('🔒 Stage2 β - 画面要素のロール別露出規制テスト', () {
    late SharedPreferences prefs;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget createTestWidget(UserRole role) {
      return ProviderScope(
        overrides: [
          currentUserRoleProvider.overrideWith((ref) => role),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: StartScreen()),
      );
    }

    testWidgets('Viewerモード時、新規作成ボタンが画面上から物理排除されていること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(UserRole.viewer));
      await tester.pumpAndSettle();
      expect(find.text('新しい大会\nを作る'), findsNothing);
    });

    testWidgets('Operatorモード時、新規作成ボタンが正しく画面に露出すること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(UserRole.operator));
      await tester.pumpAndSettle();
      expect(find.text('新しい大会\nを作る'), findsOneWidget);
    });

    testWidgets('Recorder（記録者）モード時、システム設定へのアクセス経路（歯車）が物理排除されていること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(UserRole.recorder));
      await tester.pumpAndSettle();
      // 設定進入アイコンが出ないことを厳格に検証
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
    });

    testWidgets(
      'Operator（運営者）モード時、Admin特権である一括破棄（delete_sweep）などの危険機能が露出しないこと',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(UserRole.operator));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.delete_sweep), findsNothing);
      },
    );
  });
}
