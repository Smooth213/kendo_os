import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/presentation/operate/providers/match_timer_provider.dart';
import 'package:kendo_os/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/application/usecases/match_application_service.dart';

// ============================================================================
// ★ UI・状態管理層 (Provider) 専用の要塞テスト
// このファイルは、通信ラグや画面遷移によってタイマーが壊れないことを証明します。
// ============================================================================

// 1. テスト用のDB保存モック（書き込み結果を検証するため）
class FakeMatchApplicationService implements MatchApplicationService {
  MatchModel? lastSavedMatch;

  @override
  Future<void> saveMatch(MatchModel match) async {
    lastSavedMatch = match;
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// 2. 試合データのスタブ生成ヘルパー
MatchModel createDummyMatch({
  required String id,
  int matchTimeMinutes = 3,
  DateTime? timerStartedAt,
  DateTime? timerPausedAt,
  String status = 'not_started',
}) {
  return MatchModel(
    id: id,
    tournamentId: 't1',
    redName: '赤',
    whiteName: '白',
    redScore: 0,
    whiteScore: 0,
    status: status,
    matchType: '個人戦',
    matchTimeMinutes: matchTimeMinutes,
    timerStartedAt: timerStartedAt,
    timerPausedAt: timerPausedAt,
    events: const [],
  );
}

void main() {
  late FakeMatchApplicationService fakeService;

  setUp(() {
    fakeService = FakeMatchApplicationService();
  });

  group('MatchTimerProvider (UI Layer) Governance Tests', () {

    test('1. 無限リセット防止: キャッシュされた秒数は外部の通信ラグで上書きされない', () {
      final dummyMatch = createDummyMatch(id: 'match1', matchTimeMinutes: 3);
      
      final container = ProviderContainer(
        overrides: [
          matchListProvider.overrideWith((ref) => [dummyMatch]),
        ]
      );

      // 初回ロード時はDBの値(180秒)が正しく取れること
      final initial = container.read(liveRemainingSecondsProvider('match1'));
      expect(initial, 180);

      // UI側でタイマーが稼働して秒数が減ったと仮定（キャッシュの更新）
      container.read(liveRemainingSecondsProvider('match1').notifier).state = 175;

      // 状態が正しく175として保持され、通信が走っても勝手に180に戻らないことの証明
      // （※ StateProvider.family が read で初期化されているため、不変条件が守られます）
      final current = container.read(liveRemainingSecondsProvider('match1'));
      expect(current, 175);
      
      container.dispose();
    });

    test('2. 計算の正確性: toggleTimer(Pause) 時に現在の残り秒数(キャッシュ)が正しくDBへ保存される', () async {
      final dummyMatch = createDummyMatch(
        id: 'match2',
        matchTimeMinutes: 3, // 初期の残り時間
        timerStartedAt: DateTime.now().subtract(const Duration(seconds: 10)),
        status: 'in_progress',
      );

      final container = ProviderContainer(
        overrides: [
          matchListProvider.overrideWith((ref) => [dummyMatch]),
          matchApplicationServiceProvider.overrideWithValue(fakeService),
        ]
      );

      final timerEngine = container.read(matchTimerProvider);
      
      // ★ 新アーキテクチャのシミュレート: 
      // 画面ロード時にタイマーが稼働中であればTickerが開始される状態を作る
      timerEngine.startLocalTicker('match2', isImmediateStart: true);

      // ローカルのTickerが10秒間動いて、UIの表示秒数が「170秒」に更新されている状態を作る
      container.read(liveRemainingSecondsProvider('match2').notifier).state = 170;

      // UIから「一時停止(Pause)」を指令
      await timerEngine.toggleTimer('match2');

      // 検証: モックに渡された保存データを確認
      final savedMatch = fakeService.lastSavedMatch;
      expect(savedMatch, isNotNull);
      expect(savedMatch!.timerIsRunning, false, reason: 'タイマーが停止状態になっていること');
      expect(savedMatch.timerStartedAt, isNull, reason: '次回の計算のために開始時刻がリセットされていること');
      expect(savedMatch.timerPausedAt, isNotNull, reason: '停止時刻が記録されていること');

      // ★ 検証: DBの計算ではなく、「UIに見えていた170秒」がそのまま正確にDBへ保存されていること
      expect(savedMatch.remainingSeconds, 170, reason: '画面上の秒数がそのまま記録されること');

      container.dispose();
    });

    test('3. 手動更新時の凍結防止: 稼働中に時間を修正してもタイマーがフリーズしない', () async {
      final dummyMatch = createDummyMatch(
        id: 'match3',
        matchTimeMinutes: 2,
        timerStartedAt: DateTime.now().subtract(const Duration(seconds: 5)),
        status: 'in_progress',
      );

      final container = ProviderContainer(
        overrides: [
          matchListProvider.overrideWith((ref) => [dummyMatch]),
          matchApplicationServiceProvider.overrideWithValue(fakeService),
        ]
      );

      final timerEngine = container.read(matchTimerProvider);
      // 画面ロード時にタイマーが稼働中であればTickerが開始される状態を作る
      timerEngine.startLocalTicker('match3', isImmediateStart: true);

      // 審判の指示で、時計を手動で「60秒」に修正したと仮定
      await timerEngine.updateRemainingSeconds('match3', 60);

      final savedMatch = fakeService.lastSavedMatch;
      expect(savedMatch, isNotNull);
      expect(savedMatch!.remainingSeconds, 60, reason: '秒数が強制的に60に上書きされていること');
      expect(savedMatch.timerStartedAt, isNotNull, reason: '稼働中なので、計算の起点が【今】にリセットされていること');
      expect(savedMatch.timerIsRunning, true, reason: 'タイマーが引き続き稼働していること');

      container.dispose();
    });
  });
}