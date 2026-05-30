import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/entities/program_model.dart' hide StrokeModel;
import 'package:kendo_os/presentation/public/operator/match_screen.dart';
import 'package:kendo_os/presentation/shared/widgets/timer_widget.dart';
import 'package:kendo_os/presentation/viewer/screens/viewer_team_scoreboard_screen.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/presentation/operate/screens/program_viewer_screen.dart';
import 'package:kendo_os/presentation/operate/screens/standings_screen.dart';
import 'package:kendo_os/presentation/operate/screens/kachinuki_scoreboard_screen.dart';
import '../helpers/test_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/presentation/operate/providers/settings_provider.dart';
import 'package:kendo_os/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/application/services/sound_service.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/application/usecases/match_application_service.dart';
import 'package:kendo_os/infrastructure/repository/stroke_repository.dart';
import 'package:kendo_os/domain/score/stroke_model.dart';
import 'package:kendo_os/infrastructure/repository/local_stroke_repository.dart';
import 'package:kendo_os/infrastructure/persistence/models/local_stroke_model.dart';

// 🛡️ 追加: StrokeRepositoryのダミーモッククラス
class FakeStrokeRepository implements StrokeRepository {
  @override
  Stream<List<StrokeModel>> watchStrokes(String programId) {
    return Stream.value(<StrokeModel>[]); // Null checkクラッシュを防ぐため空リストを流す
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// 🛡️ 追加: LocalStrokeRepositoryのダミーモッククラス
class FakeLocalStrokeRepository implements LocalStrokeRepository {
  @override
  Stream<List<LocalStrokeModel>> watchStrokes(String programId) {
    return Stream.value(<LocalStrokeModel>[]); 
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// 🛡️ 追加: SoundServiceのダミーモッククラス
class FakeSoundService implements SoundService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// 🛡️ 追加: MatchApplicationServiceのダミーモッククラス
class FakeMatchApplicationService implements MatchApplicationService {
  @override
  Future<bool> claimScorer(String matchId, String userId) async => true;
  @override
  Future<void> releaseScorer(String matchId, String userId) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({}); // モックの初期値を設定
    await setupTestFirebase();
  });

  group('🛡️ Page 2 — UI崩壊検知（多端末・ダークモード・DynamicType）包括テスト要塞', () {
    const testMatchId = 'phase2_gold_match_123';
    const testTournamentId = 'phase2_gold_tourney_456';
    const testGroupName = '一般の部_リーグ戦';

    final devices = {
      'iPhone_SE': const Size(375, 667),
      'iPhone_Pro_Max': const Size(428, 926),
      'iPad': const Size(768, 1024),
      'Web_Desktop': const Size(1920, 1080),
      'Web_Narrow': const Size(600, 1080),
    };

    final environments = [
      {'name': 'Light_Normal', 'dark': false, 'scale': 1.0},
      {'name': 'Dark_Normal', 'dark': true, 'scale': 1.0},
      {'name': 'Light_DynamicType_High', 'dark': false, 'scale': 2.0},
    ];

    late List<ProgramModel> mockPrograms;
    late SharedPreferences prefs;

    setUp(() async {
      prefs = await SharedPreferences.getInstance(); // テスト用のインスタンスを取得
      mockPrograms = [
        ProgramModel(
          id: 'prog_001',
          tournamentId: testTournamentId,
          title: '1日目 進行表',
          fileUrl: 'https://example.com/file.pdf',
          fileType: 'pdf',
          pageCount: 1,
          createdAt: DateTime(2026, 5, 29),
        ),
      ];
    });

    for (var device in devices.entries) {
      for (var env in environments) {
        final label = '【${device.key} - ${env['name']}】';

        testWidgets('$label 6大主要コンポーネント整合性検証', (WidgetTester tester) async {
          tester.view.physicalSize = device.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            createUnifiedTestableWidget(
              MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(env['scale'] as double)),
                child: Theme(
                  data: (env['dark'] as bool) ? ThemeData.dark() : ThemeData.light(),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 500,
                          child: const MatchScreen(matchId: testMatchId),
                        ),
                        const SizedBox(
                          height: 200,
                          child: TimerWidget(matchId: testMatchId, isInputLocked: false),
                        ),
                        const SizedBox(
                          height: 500,
                          child: ViewerTeamScoreboardScreen(groupName: testGroupName),
                        ),
                        SizedBox(
                          height: 500,
                          child: ProgramViewerScreen(programs: mockPrograms, initialIndex: 0),
                        ),
                        SizedBox(
                          height: 500,
                          child: const StandingsScreen(tournamentId: testTournamentId),
                        ),
                        SizedBox(
                          height: 500,
                          child: const KachinukiScoreboardScreen(groupName: testGroupName),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs), // プロバイダを安全にオーバーライド
                  matchStreamProvider.overrideWith((ref) => Stream<List<MatchModel>>.value([
                    MatchModel(id: testMatchId, tournamentId: testTournamentId, matchType: '個人戦', redName: '赤選手', whiteName: '白選手', groupName: testGroupName)
                  ])), // 🛡️ ダミーデータを流し込み、ローディング状態を解除
                  matchListProvider.overrideWith((ref) => [
                    MatchModel(id: testMatchId, tournamentId: testTournamentId, matchType: '個人戦', redName: '赤選手', whiteName: '白選手', groupName: testGroupName)
                  ]),  // 🛡️ ダミーデータを流し込み、ローディング状態を解除
                  soundServiceProvider.overrideWithValue(FakeSoundService()),  // 🛡️ Sound依存切断
                  isarProvider.overrideWithValue(null), // 🛡️ Isar未初期化エラーを解決
                  strokeRepositoryProvider.overrideWith((ref) => FakeStrokeRepository()), // 🛡️ FirebaseFirestore未初期化エラーを解決 (autoDispose対策)
                  localStrokeRepositoryProvider.overrideWith((ref) => FakeLocalStrokeRepository()), // 🛡️ Isar null checkエラーを解決
                  matchViewStateUserIdProvider.overrideWith((ref) => 'test_user_id'), // 🛡️ Firebase未初期化エラーを解決
                  activeRoleProvider.overrideWith((ref) => Role.admin), // 🛡️ Firebase未初期化エラーを解決
                  matchApplicationServiceProvider.overrideWithValue(FakeMatchApplicationService()), // 🛡️ Isar書き込みクラッシュを解決
              ],
            ),
          );

          await tester.pump();
          
          // ★ 修正: TimerWidgetの点滅や、CircularProgressIndicatorの無限アニメーションが回っていると
          // pumpAndSettle() はアニメーションが止まるまで永遠に待ち続け、タイムアウト(フリーズ)を引き起こします。
          // これを防ぐため、明示的に一定時間だけフレームを進める pump(Duration) に置き換えます。
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.byType(TimerWidget), findsWidgets); // 🛡️ TimerWidgetは MatchScreen と直接配置の2つが存在するため findsWidgets にする
        });
      }
    }
  });
}
