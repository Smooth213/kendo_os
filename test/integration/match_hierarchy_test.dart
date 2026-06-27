@TestOn('vm')
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_crashlytics_platform_interface/firebase_crashlytics_platform_interface.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_list.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart'
    show isarProvider;
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'
    show tournamentProvider;

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String _documentsPath;
  FakePathProviderPlatform(this._documentsPath);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return _documentsPath;
  }
}

class FakeFirebasePlatform extends FirebasePlatform {
  final Map<String, FirebaseAppPlatform> _apps = {};

  Map<dynamic, dynamic> get pluginConstants {
    return const {
      'isCrashlyticsCollectionEnabled': true,
      'firebase_crashlytics': {'isCrashlyticsCollectionEnabled': true},
      '[DEFAULT]': {
        'isCrashlyticsCollectionEnabled': true,
        'firebase_crashlytics': {'isCrashlyticsCollectionEnabled': true},
      },
    };
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    if (!_apps.containsKey(name)) {
      throw FirebaseException(
        plugin: 'core',
        code: 'no-app',
        message:
            "No Firebase App '$name' has been created - call Firebase.initializeApp()",
      );
    }
    return _apps[name]!;
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    final appName = name ?? defaultFirebaseAppName;
    final app = FakeFirebaseAppPlatform(
      appName,
      options ??
          const FirebaseOptions(
            apiKey: 'mock_key_123',
            appId: 'mock_app_123',
            messagingSenderId: 'mock_sender_123',
            projectId: 'mock_project_123',
          ),
    );
    _apps[appName] = app;
    return app;
  }

  @override
  List<FirebaseAppPlatform> get apps => _apps.values.toList();
}

class FakeFirebaseAppPlatform extends FirebaseAppPlatform {
  FakeFirebaseAppPlatform(super.name, super.options);

  Map<dynamic, dynamic> get pluginConstants => const {
    'isCrashlyticsCollectionEnabled': true,
    'firebase_crashlytics': {'isCrashlyticsCollectionEnabled': true},
  };
}

class FakeFirebaseCrashlyticsPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FirebaseCrashlyticsPlatform {
  @override
  bool get isCrashlyticsCollectionEnabled => false;

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future.value();
  }
}

void main() {
  group('🛡️ Match Accordion Hierarchy Integration Tests', () {
    setUpAll(() async {
      HttpOverrides.global = null;
      FirebasePlatform.instance = FakeFirebasePlatform();
      await Firebase.initializeApp();
      FirebaseCrashlyticsPlatform.instance = FakeFirebaseCrashlyticsPlatform();

      final tempDir = Directory.systemTemp.createTempSync(
        'path_provider_mock_',
      );
      PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    });

    testWidgets('Verify match hierarchy logic and accordion classification', (
      WidgetTester tester,
    ) async {
      final tournamentId = 'test_tournament_id';
      final category = '小学生の部';

      final mockMatches = [
        // 1. 勝ち抜き戦: 勝ち抜き戦グループのアコーディオン下に収まる
        MatchModel(
          id: 'match_kachinuki_1',
          tournamentId: tournamentId,
          category: category,
          groupName: 'KachinukiGroup',
          matchType: '選手',
          redName: 'A道場 : 先鋒A',
          whiteName: 'B道場 : 先鋒B',
          isKachinuki: true,
          order: 1.0,
        ),
        // 2. 通常団体戦: チーム単位のアコーディオン下に収まる
        MatchModel(
          id: 'match_team_1',
          tournamentId: tournamentId,
          category: category,
          groupName: 'TeamGroup',
          matchType: '先鋒',
          redName: 'C道場 : 先鋒C',
          whiteName: 'D道場 : 先鋒D',
          order: 2.0,
        ),
        MatchModel(
          id: 'match_team_2',
          tournamentId: tournamentId,
          category: category,
          groupName: 'TeamGroup',
          matchType: '中堅',
          redName: 'C道場 : 中堅C',
          whiteName: 'D道場 : 中堅D',
          order: 3.0,
        ),
        // 3. 通常個人戦: 個人戦専用のアコーディオン下に収まる
        MatchModel(
          id: 'match_ind_1',
          tournamentId: tournamentId,
          category: category,
          groupName: 'IndGroup',
          matchType: '個人戦',
          redName: 'A道場 : 個人A',
          whiteName: 'X道場 : 個人X',
          order: 4.0,
        ),
        // 4. リーグ団体戦: 「リーグ戦グループ」という親階層の下に、対戦カード(Matchup)単位で展開
        MatchModel(
          id: 'match_league_team_1',
          tournamentId: tournamentId,
          category: category,
          groupName: 'LeagueTeamGroup',
          matchType: '先鋒',
          redName: 'E道場 : 先鋒E',
          whiteName: 'F道場 : 先鋒F',
          note: '[リーグ戦]',
          order: 5.0,
        ),
        MatchModel(
          id: 'match_league_team_2',
          tournamentId: tournamentId,
          category: category,
          groupName: 'LeagueTeamGroup',
          matchType: '中堅',
          redName: 'E道場 : 中堅E',
          whiteName: 'F道場 : 中堅F',
          note: '[リーグ戦]',
          order: 6.0,
        ),
        // 5. リーグ個人戦: 「リーグ戦グループ」という親階層の下に、選手名単位で展開
        // (リーグ戦のため、個人戦アコーディオンにパージされずにグループ構造を維持する)
        MatchModel(
          id: 'match_league_ind_1',
          tournamentId: tournamentId,
          category: category,
          groupName: 'LeagueIndGroup',
          matchType: '個人戦',
          redName: 'G道場 : 選手G',
          whiteName: 'H道場 : 選手H',
          note: '[リーグ戦]',
          order: 7.0,
        ),
      ];

      // Build MatchTimelineList wrapped in ProviderScope overriding matches, isarProvider, and tournamentProvider
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isarProvider.overrideWithValue(null),
            tournamentProvider(
              tournamentId,
            ).overrideWith((ref) => Stream.value(null)),
            matchListProvider.overrideWithValue(mockMatches),
          ],
          child: MaterialApp(
            home: Scaffold(body: MatchTimelineList(tournamentId: tournamentId)),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assertions:
      // 1. 勝ち抜き戦: 「KachinukiGroup」のアコーディオンが存在すること
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is ExpansionTile &&
              w.key == const ValueKey('group_KachinukiGroup'),
        ),
        findsOneWidget,
      );

      // 2. 通常団体戦: 「TeamGroup」のアコーディオンが存在すること
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is ExpansionTile && w.key == const ValueKey('group_TeamGroup'),
        ),
        findsOneWidget,
      );

      // 3. 通常個人戦: 「IndGroup」のアコーディオンは存在せず、個人戦専用のアコーディオン（player_個人A）に分類されること
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is ExpansionTile && w.key == const ValueKey('group_IndGroup'),
        ),
        findsNothing,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is ExpansionTile && w.key == const ValueKey('player_個人A'),
        ),
        findsOneWidget,
      );

      // 4. リーグ団体戦: リーグ団体戦のアコーディオン「LeagueTeamGroup」が存在すること
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is ExpansionTile &&
              w.key == const ValueKey('group_LeagueTeamGroup'),
        ),
        findsOneWidget,
      );

      // 5. リーグ個人戦: 個人戦アコーディオンにパージされず、グループアコーディオン「LeagueIndGroup」が維持されること
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is ExpansionTile &&
              w.key == const ValueKey('group_LeagueIndGroup'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is ExpansionTile && w.key == const ValueKey('player_選手G'),
        ),
        findsNothing,
      );
    });
  });
}
