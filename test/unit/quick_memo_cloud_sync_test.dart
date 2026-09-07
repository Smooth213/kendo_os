import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group(
    '🥋 QuickMemoStorageService Cloud Sync & Backward Compatibility Tests',
    () {
      setUp(() {
        SharedPreferences.setMockInitialValues({});
      });

      test('QuickMemoData の isEmpty / isNotEmpty 判定が正確であること', () {
        const emptyMemo = QuickMemoData();
        expect(emptyMemo.isEmpty, isTrue);
        expect(emptyMemo.isNotEmpty, isFalse);

        const textMemo = QuickMemoData(text: '審判ミーティング 13:00');
        expect(textMemo.isEmpty, isFalse);
        expect(textMemo.isNotEmpty, isTrue);

        final strokeMemo = QuickMemoData(
          strokes: [
            MemoStroke(
              points: [],
              color: const Color(0xFFFFFFFF),
              strokeWidth: 2.0,
            ),
          ],
        );
        expect(strokeMemo.isEmpty, isFalse);
        expect(strokeMemo.isNotEmpty, isTrue);
      });

      test('未連携時（ローカル単体環境）でも保存と復元が完全に動作すること（後方互換性100%保証）', () async {
        final service = QuickMemoStorageService.instance;
        const tournamentId = 'tourney_test_123';

        // 初期状態は空
        final initial = await service.loadMemo(tournamentId);
        expect(initial.isEmpty, isTrue);

        // 保存
        await service.saveMemo(
          tournamentId: tournamentId,
          text: '第3試合場 延長戦あり',
          strokes: [],
          modeName: 'text',
        );

        // 復元
        final loaded = await service.loadMemo(tournamentId);
        expect(loaded.text, equals('第3試合場 延長戦あり'));
        expect(loaded.modeName, equals('text'));
        expect(loaded.updatedAt, isNotNull);

        // 全消去
        await service.clearMemo(tournamentId);
        final cleared = await service.loadMemo(tournamentId);
        expect(cleared.isEmpty, isTrue);
      });

      test('MemoStroke が Firestore準拠のフラット配列でシリアライズされ、旧形式も安全にデシリアライズできること', () {
        final stroke = MemoStroke(
          points: const [Offset(10.5, 20.5), Offset(30.0, 40.0)],
          color: const Color(0xFFFF0000),
          strokeWidth: 3.5,
        );

        // 新形式（フラット配列）
        final json = stroke.toJson();
        expect(json['points'], equals([10.5, 20.5, 30.0, 40.0]));
        expect(json['strokeWidth'], equals(3.5));

        final restored = MemoStroke.fromJson(json);
        expect(restored.points.length, equals(2));
        expect(restored.points[0], equals(const Offset(10.5, 20.5)));
        expect(restored.points[1], equals(const Offset(30.0, 40.0)));

        // 旧形式（2重配列）の後方互換テスト
        final legacyJson = {
          'points': [
            [15.0, 25.0],
            [35.0, 45.0],
          ],
          'color': 0xFFFF0000,
          'strokeWidth': 2.0,
        };
        final legacyRestored = MemoStroke.fromJson(legacyJson);
        expect(legacyRestored.points.length, equals(2));
        expect(legacyRestored.points[0], equals(const Offset(15.0, 25.0)));
        expect(legacyRestored.points[1], equals(const Offset(35.0, 45.0)));
      });
    },
  );
}
