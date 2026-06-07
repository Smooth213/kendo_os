import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart'
    hide StrokeModel;
import 'package:kendo_os/features/tournament/presentation/operate/match_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/program_viewer_screen.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/program_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/application/services/sound_service.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_app.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/stroke_repository.dart';
import 'package:kendo_os/features/match/domain/score/stroke_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_stroke_repository.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/local_stroke_model.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';

class FakeProgramRepository implements ProgramRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSoundService implements SoundService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStrokeRepository implements StrokeRepository {
  @override
  Stream<List<StrokeModel>> watchStrokes(String programId) {
    return Stream.value(<StrokeModel>[]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocalStrokeRepository implements LocalStrokeRepository {
  @override
  Stream<List<LocalStrokeModel>> watchStrokes(String programId) {
    return Stream.value(<LocalStrokeModel>[]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMatchApplicationService implements MatchApplicationService {
  @override
  Future<bool> claimScorer(String matchId, String userId) async => true;
  @override
  Future<void> releaseScorer(String matchId, String userId) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('🛡️ PHASE 15 — リアル端末マルチOS・物理境界エミュレーションテスト要塞', () {
    const testMatchId = 'phase15_device_match_123';

    final devices = {
      'iPhone_SE_Variant': {
        'size': const Size(375, 667),
        'padding': const EdgeInsets.only(top: 20, bottom: 0),
        'insets': EdgeInsets.zero,
        'isKeyboard': false,
      },
      'iPhone_15_Variant': {
        'size': const Size(393, 852),
        'padding': const EdgeInsets.only(top: 59, bottom: 34),
        'insets': EdgeInsets.zero,
        'isKeyboard': false,
      },
      'iPhone_17_Pro_Variant': {
        'size': const Size(402, 874),
        'padding': const EdgeInsets.only(top: 62, bottom: 34),
        'insets': EdgeInsets.zero,
        'isKeyboard': false,
      },
      'Android_Pixel_Variant': {
        'size': const Size(412, 915),
        'padding': const EdgeInsets.only(top: 24, bottom: 0),
        'insets': EdgeInsets.zero,
        'isKeyboard': false,
      },
      'Android_Galaxy_Variant': {
        'size': const Size(360, 800),
        'padding': const EdgeInsets.only(top: 24, bottom: 0),
        'insets': EdgeInsets.zero,
        'isKeyboard': false,
      },
      'iPhone_15_Keyboard_Active': {
        'size': const Size(393, 852),
        'padding': const EdgeInsets.only(top: 59, bottom: 34),
        'insets': const EdgeInsets.only(bottom: 336),
        'isKeyboard': true,
      },
      'iPad_Mini_Variant': {
        'size': const Size(768, 1024),
        'padding': const EdgeInsets.only(top: 20, bottom: 0),
        'insets': EdgeInsets.zero,
        'isKeyboard': false,
      },
      'iPad_Pro_11_Variant': {
        'size': const Size(834, 1194),
        'padding': const EdgeInsets.only(top: 24, bottom: 20),
        'insets': EdgeInsets.zero,
        'isKeyboard': false,
      },
      'iPad_Pro_12.9_Variant': {
        'size': const Size(1024, 1366),
        'padding': const EdgeInsets.only(top: 24, bottom: 20),
        'insets': EdgeInsets.zero,
        'isKeyboard': false,
      },
      'Samsung_Tab_S8_Variant': {
        'size': const Size(800, 1280),
        'padding': const EdgeInsets.only(top: 24, bottom: 0),
        'insets': EdgeInsets.zero,
        'isKeyboard': false,
      },
      'Pixel_Tablet_Variant': {
        'size': const Size(800, 1280),
        'padding': const EdgeInsets.only(top: 24, bottom: 0),
        'insets': EdgeInsets.zero,
        'isKeyboard': false,
      },
      'Desktop_FHD_Variant': {
        'size': const Size(1920, 1080),
        'padding': EdgeInsets.zero,
        'insets': EdgeInsets.zero,
        'isKeyboard': false,
      },
    };

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await setupTestFirebase();
    });

    for (var device in devices.entries) {
      final config = device.value;
      testWidgets('${device.key} 監査', (WidgetTester tester) async {
        tester.view.physicalSize = config['size'] as Size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          createUnifiedTestableWidget(
            MediaQuery(
              data: MediaQueryData(
                size: config['size'] as Size,
                padding: config['padding'] as EdgeInsets,
                viewInsets: config['insets'] as EdgeInsets,
                textScaler: const TextScaler.linear(1.0),
              ),
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 400,
                        child: const MatchScreen(matchId: testMatchId),
                      ),
                      SizedBox(
                        height: 400,
                        child: ProgramViewerScreen(
                          programs: [
                            ProgramModel(
                              id: 'dummy_p1',
                              tournamentId: 'dummy_t1',
                              title: 'Dummy Program',
                              fileUrl: 'dummy.pdf',
                              fileType: 'pdf',
                              pageCount: 1,
                              createdAt: DateTime.now(),
                            ),
                          ],
                          initialIndex: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            overrides: [
              isarProvider.overrideWithValue(null), // 🛡️ 実DB依存によるI/Oデッドロックを防止
              programRepositoryProvider.overrideWithValue(
                FakeProgramRepository(),
              ),
              activeRoleProvider.overrideWith((ref) => Role.admin),
              currentUserRoleProvider.overrideWith((ref) => UserRole.operator),
              soundServiceProvider.overrideWith((ref) => FakeSoundService()),
              sharedPreferencesProvider.overrideWithValue(prefs),
              matchStreamProvider.overrideWith(
                (ref) => Stream<List<MatchModel>>.value([
                  MatchModel(
                    id: testMatchId,
                    tournamentId: 'dummy_t1',
                    matchType: '個人戦',
                    redName: '赤選手',
                    whiteName: '白選手',
                    groupName: '一般の部',
                    status: 'waiting',
                  ),
                ]),
              ),
              matchListProvider.overrideWith(
                (ref) => [
                  MatchModel(
                    id: testMatchId,
                    tournamentId: 'dummy_t1',
                    matchType: '個人戦',
                    redName: '赤選手',
                    whiteName: '白選手',
                    groupName: '一般の部',
                    status: 'waiting',
                  ),
                ],
              ),
              strokeRepositoryProvider.overrideWith(
                (ref) => FakeStrokeRepository(),
              ),
              localStrokeRepositoryProvider.overrideWith(
                (ref) => FakeLocalStrokeRepository(),
              ),
              matchViewStateUserIdProvider.overrideWith(
                (ref) => 'test_user_id',
              ),
              matchApplicationServiceProvider.overrideWithValue(
                FakeMatchApplicationService(),
              ),
            ],
          ),
        );
        await tester.pump(
          const Duration(milliseconds: 500),
        ); // 🛡️ 無限アニメーション待ちを回避し、安全に終了させる
        expect(tester.takeException(), isNull);
      });
    }
  });
}
