import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_save_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_name_history_provider.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockTeamRepository implements TeamRepository {
  TeamModel? savedTeam;

  @override
  String get dojoId => 'test_dojo';

  @override
  Future<String> saveTeam(TeamModel team) async {
    savedTeam = team;
    return team.id.isEmpty ? 'generated_id' : team.id;
  }

  @override
  Future<void> deleteTeam(String id) async {}

  @override
  Stream<List<TeamModel>> watchTeamsByTournament(String tournamentId) =>
      const Stream.empty();
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('[Unit] TeamRegistrationSaveHelper 単体テスト', () {
    testWidgets('チーム情報がサニタイズされ選手リスト構築と履歴追加が正常に行われること', (tester) async {
      late WidgetRef capturedRef;
      final mockRepo = MockTeamRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            teamRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const Scaffold(body: Text('テスト'));
              },
            ),
          ),
        ),
      );

      await TeamRegistrationSaveHelper.saveTeamWithHistory(
        ref: capturedRef,
        editingTeamId: 'existing-team-id',
        tournamentId: 'tournament-99',
        category: '中学生男子',
        rawTeamName: '  洗心道場　Ａチーム  ',
        matchType: '5人戦',
        playerCount: 3,
        tempSelectedPlayers: {0: '先鋒選手', 1: '中堅選手', 2: '大将選手'},
      );

      expect(mockRepo.savedTeam, isNotNull);
      final saved = mockRepo.savedTeam!;
      expect(saved.id, 'existing-team-id');
      expect(saved.tournamentId, 'tournament-99');
      expect(saved.category, '中学生男子');
      // 全角スペースおよび全角Ａがサニタイズされ半角スペースなしに統一されること
      expect(saved.teamName, '洗心道場Aチーム');
      expect(saved.playerNames, ['先鋒選手', '中堅選手', '大将選手']);

      final history = capturedRef.read(teamNameHistoryProvider);
      expect(history.any((h) => h.contains('洗心道場')), isTrue);
    });

    testWidgets('editingTeamIdがnullの際に空文字IDで新規保存されること', (tester) async {
      late WidgetRef capturedRef;
      final mockRepo = MockTeamRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            teamRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const Scaffold(body: Text('テスト'));
              },
            ),
          ),
        ),
      );

      await TeamRegistrationSaveHelper.saveTeamWithHistory(
        ref: capturedRef,
        editingTeamId: null,
        tournamentId: 'tournament-new',
        category: '小学生',
        rawTeamName: '若鷲旗チーム',
        matchType: '3人戦',
        playerCount: 1,
        tempSelectedPlayers: {0: '選手1'},
      );

      expect(mockRepo.savedTeam?.id, '');
    });
  });
}
