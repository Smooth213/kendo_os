import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 🌐 ディープリンク404セーフティルーター
class DeepLinkSafetyRouter extends StatelessWidget {
  final String requestedTournamentId;
  final bool Function(String id) tournamentExistsChecker;

  const DeepLinkSafetyRouter({
    super.key,
    required this.requestedTournamentId,
    required this.tournamentExistsChecker,
  });

  @override
  Widget build(BuildContext context) {
    final exists = tournamentExistsChecker(requestedTournamentId);

    if (!exists) {
      // 404安全フォールバック画面
      return Scaffold(
        appBar: AppBar(title: const Text('Kendo OS')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                '指定された大会が見つかりません',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('ID: $requestedTournamentId は削除されたかURLが無効です。'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                key: const Key('return_to_home_btn'),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/');
                },
                icon: const Icon(Icons.home),
                label: const Text('トップ画面に戻る'),
              ),
            ],
          ),
        ),
      );
    }

    // 正常な大会画面
    return Scaffold(body: Center(child: Text('大会画面: $requestedTournamentId')));
  }
}

void main() {
  group('🌐 【Phase 4-3/11】ディープリンク無効ID・404安全リカバリ Widgetテスト', () {
    testWidgets('1. 存在しない大会IDアクセス時に404フォールバック画面が表示され、トップへ戻れること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/tournament/invalid_id_999',
          routes: {
            '/': (context) => const Scaffold(body: Text('ホーム画面')),
            '/tournament/invalid_id_999': (context) => DeepLinkSafetyRouter(
              requestedTournamentId: 'invalid_id_999',
              tournamentExistsChecker: (id) => false, // 存在しない
            ),
          },
        ),
      );

      // ホワイトアウトせず、丁寧なエラー画面が表示されること
      expect(find.text('指定された大会が見つかりません'), findsOneWidget);
      expect(find.text('ID: invalid_id_999 は削除されたかURLが無効です。'), findsOneWidget);
      expect(find.byKey(const Key('return_to_home_btn')), findsOneWidget);

      // 「トップ画面に戻る」ボタンをタップ
      await tester.tap(find.byKey(const Key('return_to_home_btn')));
      await tester.pumpAndSettle();

      // ホーム画面へ安全に復帰すること
      expect(find.text('ホーム画面'), findsOneWidget);
    });
  });
}
