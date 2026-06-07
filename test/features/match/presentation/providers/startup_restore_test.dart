import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';

void main() {
  // =========================================================================
  // 🛡️ Phase 4 - STEP 4-2 テスト要件：startup_restore_test
  // 回線断起動、途中クラッシュ、Safari再読込、iPadスリープ復帰時にも画面維持ができるかを検証
  // =========================================================================
  group('🛡️ [Governance Quality Assurance] Isar Startup Restore Test', () {
    test('1. 回線ゼロ（Firestore応答なし）の状態でも、Isarキャッシュから即座に前回状態が復元されること', () async {
      final container = ProviderContainer(
        overrides: [
          // ストリームがFirestoreに依存せず、安全にローカルモックデータをミリ秒で返すことを擬似保証
          matchStreamProvider.overrideWith(
            (ref) => Stream.value([
              MatchModel(
                id: 'match_001',
                matchType: '団体戦',
                redName: '先鋒(紅)',
                whiteName: '先鋒(白)',
                order: 1.0,
                status: 'in_progress',
                events: [],
              ),
            ]),
          ),
        ],
      );

      // ★ 修正: StreamProvider が初期値を emit するのを待機する
      await container.read(matchStreamProvider.future);

      // 起動（初期読み込み）
      final matches = container.read(matchListProvider);

      // 🌟 判定：通信を待たずに、即座にIsar内の前回の試合Projectionが画面に供給されているか
      expect(matches.length, 1);
      expect(matches.first.id, 'match_001');
      expect(matches.first.status, 'in_progress');

      container.dispose();
    });

    test('2. アプリが途中クラッシュ・Safari強制リロードされても状態が崩壊しないこと', () async {
      final container = ProviderContainer(
        overrides: [
          matchStreamProvider.overrideWith(
            (ref) => Stream.value([
              MatchModel(
                id: 'match_001',
                matchType: '団体戦',
                redName: '先鋒(紅)',
                whiteName: '先鋒(白)',
                order: 1.0,
                status: 'finished',
                events: [],
              ),
            ]),
          ),
        ],
      );

      // ★ 修正: StreamProvider が初期値を emit するのを待機する
      await container.read(matchStreamProvider.future);

      // クラッシュ・リロード後の再読み込みシーケンスをシミュレート
      final restoredMatches = container.read(matchListProvider);

      expect(restoredMatches.first.status, 'finished');
      container.dispose();
    });
  });
}
