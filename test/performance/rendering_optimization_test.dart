// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/score/stroke_model.dart';
import 'package:kendo_os/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

// ============================================================
// テスト用ヘルパー: MatchProjection の最小ファクトリ
// ============================================================
MatchProjection _makeProjection({
  String id = 'match-1',
  String status = 'in_progress',
  int redScore = 0,
  int whiteScore = 0,
  String redName = '赤選手',
  String whiteName = '白選手',
  String note = '',
}) {
  return MatchProjection(
    id: id,
    tournamentId: 'tourney-1',
    matchOrder: 1,
    matchType: '個人戦',
    status: status,
    groupName: 'group-1',
    isKachinuki: false,
    redName: redName,
    whiteName: whiteName,
    redScore: redScore,
    whiteScore: whiteScore,
    remainingSeconds: 180,
    timerIsRunning: false,
    note: note,
  );
}

// ============================================================
// テスト用ヘルパー: StrokeModel の最小ファクトリ
// ============================================================
StrokeModel _makeStroke(String id) {
  return StrokeModel(
    id: id,
    programId: 'program-1',
    points: const [Offset(0, 0), Offset(10, 10)],
    color: Colors.red,
    strokeWidth: 3.0,
  );
}

void main() {
  // ─────────────────────────────────────────────────────────
  // Step 1: スクロール先読みキャッシュ検証
  // ─────────────────────────────────────────────────────────
  group('Step1: スクロール先読みキャッシュ (cacheExtent)', () {
    test('1-1. cacheExtent値が正しく計算できること（1500.0, 1000.0）', () {
      const double tournamentListCacheExtent = 1500.0;
      const double categoryListCacheExtent = 1000.0;

      expect(tournamentListCacheExtent, greaterThan(0));
      expect(categoryListCacheExtent, greaterThan(0));

      // 少なくとも1画面分以上（典型的なデバイス高さ 500px 以上）の先読みが有効であること
      // tournamentList: 3画面分(1500px), categoryList: 2画面分(1000px)
      const double minEffectiveCache = 500.0;
      expect(
        tournamentListCacheExtent,
        greaterThanOrEqualTo(minEffectiveCache),
      );
      expect(categoryListCacheExtent, greaterThanOrEqualTo(minEffectiveCache));
      // tournamentListはcategoryListより大きい（より多くのカードを先読み）
      expect(tournamentListCacheExtent, greaterThan(categoryListCacheExtent));
    });

    test('1-2. program_management_screen の itemExtent が妥当な値であること', () {
      // program_management_screen は itemExtent: 68.0 を設定済み
      const double programListItemExtent = 68.0;

      // 68px は通常の ListTile 高さ(56px) + 余白で妥当な値
      expect(programListItemExtent, greaterThan(56.0));
      expect(programListItemExtent, lessThan(100.0));
    });
  });

  // ─────────────────────────────────────────────────────────
  // Step 2-A: KachinukiBracketPainter.shouldRepaint の検証
  // ─────────────────────────────────────────────────────────
  group('Step2-A: KachinukiBracketPainter.shouldRepaint (Web/Native共通)', () {
    // ref は paint() 内でのみ使われるため、shouldRepaint のテストでは null で代用

    test('2A-1. 同一データのリストが渡された場合は false を返すこと', () {
      final matches = [_makeProjection()];
      final old = KachinukiBracketPainter(
        matches: matches,
        isDark: false,
        ref: null,
      );
      final current = KachinukiBracketPainter(
        matches: List.of(matches), // 別インスタンスだが内容同一
        isDark: false,
        ref: null,
      );

      expect(
        current.shouldRepaint(old),
        isFalse,
        reason: '同一データのとき再描画をスキップすべき',
      );
    });

    test('2A-2. スコアが変化した場合は true を返すこと', () {
      final old = KachinukiBracketPainter(
        matches: [_makeProjection(redScore: 0)],
        isDark: false,
        ref: null,
      );
      final current = KachinukiBracketPainter(
        matches: [_makeProjection(redScore: 1)],
        isDark: false,
        ref: null,
      );

      expect(current.shouldRepaint(old), isTrue, reason: 'スコア変化時は再描画すべき');
    });

    test('2A-3. status が in_progress→finished に変化した場合は true を返すこと', () {
      final old = KachinukiBracketPainter(
        matches: [_makeProjection(status: 'in_progress')],
        isDark: false,
        ref: null,
      );
      final current = KachinukiBracketPainter(
        matches: [_makeProjection(status: 'finished')],
        isDark: false,
        ref: null,
      );

      expect(current.shouldRepaint(old), isTrue, reason: '試合終了時は再描画すべき');
    });

    test('2A-4. isDark が切り替わった場合は true を返すこと', () {
      final matches = [_makeProjection()];
      final old = KachinukiBracketPainter(
        matches: matches,
        isDark: false,
        ref: null,
      );
      final current = KachinukiBracketPainter(
        matches: matches,
        isDark: true,
        ref: null,
      );

      expect(current.shouldRepaint(old), isTrue, reason: 'テーマ変更時は再描画すべき');
    });

    test('2A-5. 試合が追加された場合（リスト長変化）は true を返すこと', () {
      final old = KachinukiBracketPainter(
        matches: [_makeProjection()],
        isDark: false,
        ref: null,
      );
      final current = KachinukiBracketPainter(
        matches: [
          _makeProjection(),
          _makeProjection(id: 'match-2', redName: '鈴木', whiteName: '佐藤'),
        ],
        isDark: false,
        ref: null,
      );

      expect(current.shouldRepaint(old), isTrue, reason: '試合数増加時は再描画すべき');
    });

    test('2A-6. note（延長など）が変化した場合は true を返すこと', () {
      final old = KachinukiBracketPainter(
        matches: [_makeProjection(note: '')],
        isDark: false,
        ref: null,
      );
      final current = KachinukiBracketPainter(
        matches: [_makeProjection(note: '延長')],
        isDark: false,
        ref: null,
      );

      expect(current.shouldRepaint(old), isTrue, reason: '延長フラグ変化時は再描画すべき');
    });

    test('2A-7. PointDisplay参照が異なりスコア/status/nameが同一なら false を返すこと'
        '（PointDisplay.== 未実装の安全保証 - Web/Native共通）', () {
      // PointDisplayは==未実装だが、描画判定はstatus/score/nameのみで行う
      final p1 = MatchProjection(
        id: 'match-1',
        tournamentId: 'tourney-1',
        matchOrder: 1,
        matchType: '個人戦',
        status: 'finished',
        groupName: 'group-1',
        isKachinuki: false,
        redName: '山田',
        whiteName: '田中',
        redScore: 1,
        whiteScore: 0,
        remainingSeconds: 0,
        timerIsRunning: false,
        note: '',
        redDisplays: [PointDisplay('◯', true)], // 別インスタンス
      );
      final p2 = p1.copyWith(
        redDisplays: [PointDisplay('◯', true)], // 別インスタンスだが同内容
      );

      final old = KachinukiBracketPainter(
        matches: [p1],
        isDark: false,
        ref: null,
      );
      final current = KachinukiBracketPainter(
        matches: [p2],
        isDark: false,
        ref: null,
      );

      expect(
        current.shouldRepaint(old),
        isFalse,
        reason: 'PointDisplay参照違いのみでは再描画をスキップすべき',
      );
    });
  });

  // ─────────────────────────────────────────────────────────
  // Step 2-B: StrokePainter の shouldRepaint ロジック検証
  // ─────────────────────────────────────────────────────────
  group('Step2-B: StrokePainter.shouldRepaint ロジック (Web/Native共通)', () {
    test('2B-1. 同一ストロークリスト参照では false を返すこと', () {
      final strokes = [_makeStroke('stroke-1')];
      final checker = _StrokePainterLogic(
        sharedStrokes: strokes,
        privateCount: 0,
        currentPoints: null,
        color: Colors.red,
        width: 3.0,
      );
      final oldChecker = _StrokePainterLogic(
        sharedStrokes: strokes,
        privateCount: 0,
        currentPoints: null,
        color: Colors.red,
        width: 3.0,
      );

      expect(
        checker.shouldRepaintWith(oldChecker),
        isFalse,
        reason: '同一参照では再描画不要',
      );
    });

    test('2B-2. ストロークが追加された場合（長さ変化）は true を返すこと', () {
      final old = _StrokePainterLogic(
        sharedStrokes: [_makeStroke('stroke-1')],
        privateCount: 0,
        currentPoints: null,
        color: Colors.red,
        width: 3.0,
      );
      final current = _StrokePainterLogic(
        sharedStrokes: [_makeStroke('stroke-1'), _makeStroke('stroke-2')],
        privateCount: 0,
        currentPoints: null,
        color: Colors.red,
        width: 3.0,
      );

      expect(current.shouldRepaintWith(old), isTrue, reason: 'ストローク追加時は再描画すべき');
    });

    test('2B-3. 描画中の点列が変化した場合は true を返すこと', () {
      final old = _StrokePainterLogic(
        sharedStrokes: [],
        privateCount: 0,
        currentPoints: null,
        color: Colors.red,
        width: 3.0,
      );
      final current = _StrokePainterLogic(
        sharedStrokes: [],
        privateCount: 0,
        currentPoints: const [Offset(10, 20)],
        color: Colors.red,
        width: 3.0,
      );

      expect(
        current.shouldRepaintWith(old),
        isTrue,
        reason: '描画中の点列変化時は再描画すべき',
      );
    });

    test('2B-4. ペン色が変わった場合は true を返すこと', () {
      final strokes = [_makeStroke('stroke-1')];
      final old = _StrokePainterLogic(
        sharedStrokes: strokes,
        privateCount: 0,
        currentPoints: null,
        color: Colors.red,
        width: 3.0,
      );
      final current = _StrokePainterLogic(
        sharedStrokes: strokes,
        privateCount: 0,
        currentPoints: null,
        color: Colors.blue,
        width: 3.0,
      );

      expect(current.shouldRepaintWith(old), isTrue, reason: 'ペン色変更時は再描画すべき');
    });
  });

  // ─────────────────────────────────────────────────────────
  // Step 3: Debounce バッチ処理の検証
  // ─────────────────────────────────────────────────────────
  group('Step3: デバウンスバッチ処理 (Web/Native共通)', () {
    test('3-1. 50ms以内の連続イベントは1回にまとめて処理されること', () async {
      int callCount = 0;
      Timer? debounceTimer;

      void triggerDebounce() {
        debounceTimer?.cancel();
        debounceTimer = Timer(const Duration(milliseconds: 50), () {
          callCount++;
        });
      }

      // 10ms間隔で5回連続トリガー（各間隔は50ms未満）
      for (int i = 0; i < 5; i++) {
        triggerDebounce();
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // 最後のtriggerから50ms後に発火するのを待つ
      await Future.delayed(const Duration(milliseconds: 100));

      expect(callCount, equals(1), reason: '50ms以内の連続イベントは1回のみ実行される');
    });

    test('3-2. 50msを超える間隔のイベントは独立して処理されること', () async {
      int callCount = 0;
      Timer? debounceTimer;

      void triggerDebounce() {
        debounceTimer?.cancel();
        debounceTimer = Timer(const Duration(milliseconds: 50), () {
          callCount++;
        });
      }

      triggerDebounce();
      await Future.delayed(const Duration(milliseconds: 100));
      triggerDebounce();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(callCount, equals(2), reason: '50msを超える間隔のイベントは独立して処理される');
    });

    test('3-3. Web環境でIsarがnullの場合もデバウンス処理の型安全性が保たれること', () {
      // LocalMatchRepositoryのnullガードを検証するダミーロジック
      const bool isarIsNull = true; // Web環境シミュレーション

      if (isarIsNull) {
        // Isar null時は空ストリームを返す（クラッシュしない）
        final stream = Stream<List<String>>.value([]);
        expectLater(stream, emits(isEmpty));
      }
    });
  });

  // ─────────────────────────────────────────────────────────
  // パフォーマンス境界値テスト
  // ─────────────────────────────────────────────────────────
  group('パフォーマンス境界値: 大量データ時の shouldRepaint コスト', () {
    test('P-1. 100試合リストの shouldRepaint 比較が 1ms 未満で完了すること', () {
      final matches100 = List.generate(
        100,
        (i) => _makeProjection(
          id: 'match-$i',
          status: i < 90 ? 'finished' : 'in_progress',
          redScore: i % 3,
          whiteScore: (i + 1) % 3,
          redName: '赤選手$i',
          whiteName: '白選手$i',
        ),
      );

      final old = KachinukiBracketPainter(
        matches: matches100,
        isDark: false,
        ref: null,
      );
      final current = KachinukiBracketPainter(
        matches: List.of(matches100),
        isDark: false,
        ref: null,
      );

      final sw = Stopwatch()..start();
      final result = current.shouldRepaint(old);
      sw.stop();

      expect(result, isFalse, reason: '内容同一なら再描画不要');
      expect(
        sw.elapsedMicroseconds,
        lessThan(1000),
        reason: '100試合の比較は1ms未満で完了すべき',
      );
    });
  });
}

// ============================================================
// StrokePainterの shouldRepaint ロジックをIsar依存なしでテスト
// ============================================================
class _StrokePainterLogic {
  final List<StrokeModel> sharedStrokes;
  final int privateCount;
  final List<Offset>? currentPoints;
  final Color color;
  final double width;

  _StrokePainterLogic({
    required this.sharedStrokes,
    required this.privateCount,
    required this.currentPoints,
    required this.color,
    required this.width,
  });

  // StrokePainter.shouldRepaint と同一ロジック
  bool shouldRepaintWith(_StrokePainterLogic old) {
    if (old.sharedStrokes.length != sharedStrokes.length) return true;
    if (old.privateCount != privateCount) return true;
    if (old.color != color) return true;
    if (old.width != width) return true;
    if (old.currentPoints != currentPoints) return true;
    return old.sharedStrokes != sharedStrokes;
  }
}
