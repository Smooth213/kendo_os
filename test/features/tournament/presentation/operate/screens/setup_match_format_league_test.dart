import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/setup_match_format_screen.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] 試合形式設定画面 リーグ戦モードおよび代表戦設定描画テスト', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    testWidgets('リーグ戦モードで詳細な同点代表戦設定と勝ち点が正しく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const testTeam = TeamModel(
        id: 'team_1',
        tournamentId: 'test_tournament',
        category: '小学生の部',
        teamName: '千代田チーム',
        matchType: 'リーグ団体戦',
        playerNames: ['山田', '佐藤', '鈴木'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
            playerRepositoryProvider.overrideWith((ref) {
              final dojoId = ref.watch(currentDojoIdProvider);
              return PlayerRepository(dojoId: dojoId, firestore: fakeFirestore);
            }),
            teamRepositoryProvider.overrideWith((ref) {
              final dojoId = ref.watch(currentDojoIdProvider);
              return TeamRepository(dojoId: dojoId, firestore: fakeFirestore);
            }),
            registeredTeamsProvider('test_tournament').overrideWith((ref) {
              return Stream.value([testTeam]);
            }),
          ],
          child: const MaterialApp(
            home: SetupMatchFormatScreen(tournamentId: 'test_tournament'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('千代田チーム'), findsOneWidget);

      await tester.tap(find.text('千代田チーム'));
      await tester.pumpAndSettle();

      expect(find.text('次へ進む'), findsOneWidget);
      await tester.tap(find.text('次へ進む'));
      await tester.pumpAndSettle();

      expect(find.text('試合方式'), findsOneWidget);
      expect(find.text('リーグ団体戦'), findsAtLeast(1));

      expect(find.text('同点代表戦'), findsOneWidget);
      expect(find.text('勝ち点'), findsOneWidget);
    });
  });
}
