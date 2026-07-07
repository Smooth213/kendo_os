import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';

class FakeSyncEngine implements SyncEngine {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Widget _baseRouterTestApp(Widget child, List<Override> overrides) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [GoRoute(path: '/', builder: (context, state) => child)],
  );

  final defaultOverrides = [
    syncEngineProvider.overrideWithValue(FakeSyncEngine()),
  ];

  return ProviderScope(
    overrides: [...defaultOverrides, ...overrides],
    child: MaterialApp.router(routerConfig: router),
  );
}

Widget createTestApp(Widget child, {List<Override> overrides = const []}) {
  return _baseRouterTestApp(child, overrides);
}

Widget createGoldenTestApp(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return _baseRouterTestApp(Scaffold(body: child), overrides);
}

Widget createOfflineTestApp(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return _baseRouterTestApp(child, overrides);
}

Widget createTournamentSimulationApp(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return _baseRouterTestApp(child, overrides);
}

Widget createUnifiedTestableWidget(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return createTestApp(child, overrides: overrides);
}

Future<void> setupTestFirebase() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/firebase_core'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'Firebase#initializeCore') {
            return [
              {
                'name': '[DEFAULT]',
                'options': {
                  'apiKey': 'mock_key_123',
                  'appId': 'mock_app_123',
                  'messagingSenderId': 'mock_sender_123',
                  'projectId': 'mock_project_123',
                },
                'pluginConstants': {},
              },
            ];
          }
          if (methodCall.method == 'Firebase#initializeApp') {
            return {
              'name': '[DEFAULT]',
              'options': {
                'apiKey': 'mock_key_123',
                'appId': 'mock_app_123',
                'messagingSenderId': 'mock_sender_123',
                'projectId': 'mock_project_123',
              },
              'pluginConstants': {},
            };
          }
          return null;
        },
      );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/firebase_auth'),
        (MethodCall methodCall) async {
          return null;
        },
      );

  try {
    // 🛡️ 修正: ダミーのオプションを渡して、確実に[DEFAULT]アプリを初期化させることで
    // activeRoleProvider などの FirebaseAuth.instance 呼び出しクラッシュを全滅させます
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'mock_key_123',
        appId: 'mock_app_123',
        messagingSenderId: 'mock_sender_123',
        projectId: 'mock_project_123',
      ),
    );
  } catch (_) {}
}
