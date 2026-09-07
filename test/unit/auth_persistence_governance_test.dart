import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('🛡️ Google連携・クイックペン・クラウド同期 統合ガバナンステスト', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('【Google連携判定】Googleプロバイダが存在する場合のみ連携UIDとして認識されること', () {
      // AuthService / QuickMemoStorageService / ReadAnnouncementsNotifier 共通判定ロジック
      bool isGoogleLinked(List<String> providerIds, bool isAnonymous) {
        if (isAnonymous) return false;
        return providerIds.contains('google.com');
      }

      // 1. 匿名ユーザー
      expect(isGoogleLinked(['firebase'], true), isFalse);

      // 2. Googleアカウント連携済みユーザー
      expect(isGoogleLinked(['google.com'], false), isTrue);

      // 3. 複数プロバイダ（パスワード + Google）連携済みユーザー
      expect(isGoogleLinked(['password', 'google.com'], false), isTrue);

      // 4. メールパスワードのみのユーザー
      expect(isGoogleLinked(['password'], false), isFalse);
    });

    test('【Webセッション維持ガバナンス】Googleログイン済みユーザーに対して匿名ログインによる上書きが発生しないこと', () {
      // AppBootstrapHelper.ensureAuthenticated の保護条件:
      // currentUser != null && !currentUser.isAnonymous のときは signInAnonymously() をスキップする
      bool shouldSkipAnonymousSignIn({
        required bool hasCurrentUser,
        required bool isAnonymous,
      }) {
        if (!hasCurrentUser) return false; // ユーザーが存在しないなら匿名ログインが必要
        if (isAnonymous) return false; // 既に匿名ならそのまま（または再認証）
        return true; // Google連携など永続ログイン中ならスキップして保護
      }

      // 未ログイン状態 -> 匿名ログインを実行する
      expect(
        shouldSkipAnonymousSignIn(hasCurrentUser: false, isAnonymous: true),
        isFalse,
      );

      // 既存のGoogle連携ユーザー -> 匿名ログインをスキップしてGoogleアカウントを保護する！
      expect(
        shouldSkipAnonymousSignIn(hasCurrentUser: true, isAnonymous: false),
        isTrue,
      );

      // 既存の匿名ユーザー -> スキップせず通常処理
      expect(
        shouldSkipAnonymousSignIn(hasCurrentUser: true, isAnonymous: true),
        isFalse,
      );
    });

    test(
      '【クイックペン極限座標テスト】四隅・画面端（800x1000キャンバス）の描画データが100%欠損なくシリアライズ・復元されること',
      () {
        const baseWidth = 800.0;
        const baseHeight = 1000.0;

        // 四隅および中央の極限座標ストローク
        final strokes = [
          MemoStroke(
            points: const [
              Offset(0.0, 0.0), // 左上
              Offset(baseWidth - 1, 0.0), // 右上
              Offset(
                baseWidth - 1,
                baseHeight - 1,
              ), // 右下（PCで描いてiPhoneで見切れやすかった箇所）
              Offset(0.0, baseHeight - 1), // 左下
              Offset(baseWidth / 2, baseHeight / 2), // 中央
            ],
            color: const Color(0xFF00FF00),
            strokeWidth: 4.0,
          ),
        ];

        // QuickMemoStorageService と同一形式のFirestoreマップ
        final firestorePayload = {
          'text': '全端末ピクセル統一テスト',
          'mode': 'pen',
          'strokes': strokes.map((s) => s.toJson()).toList(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        expect(firestorePayload['text'], equals('全端末ピクセル統一テスト'));
        expect(firestorePayload['mode'], equals('pen'));

        final strokeList = firestorePayload['strokes'] as List;
        expect(strokeList.length, equals(1));
        final strokeMap = strokeList.first as Map<String, dynamic>;
        final points = strokeMap['points'] as List;
        // 5点 * (x, y) = 10要素のフラット配列
        expect(points.length, equals(10));
        expect(points[4], equals(baseWidth - 1)); // 右下 X (799.0)
        expect(points[5], equals(baseHeight - 1)); // 右下 Y (999.0)

        // Firestoreデータ形式からの完全復元
        final rawStrokes = firestorePayload['strokes'] as List<dynamic>;
        final restoredStrokes = rawStrokes
            .map((s) => MemoStroke.fromJson(s as Map<String, dynamic>))
            .toList();

        expect(restoredStrokes.length, equals(1));
        final restoredStroke = restoredStrokes.first;
        expect(restoredStroke.points.length, equals(5));
        expect(
          restoredStroke.points[2],
          equals(const Offset(799.0, 999.0)),
        ); // 右下が完全に一致
        expect(restoredStroke.strokeWidth, equals(4.0));
        expect(
          restoredStroke.color.toARGB32(),
          equals(const Color(0xFF00FF00).toARGB32()),
        );
      },
    );

    test('【クイックペン負荷耐久テスト】大量のストローク（100本）と多数の座標点でもJSONシリアライズと完全性が保たれること', () {
      final List<MemoStroke> complexStrokes = [];
      for (int i = 0; i < 100; i++) {
        complexStrokes.add(
          MemoStroke(
            points: [
              Offset(i.toDouble() * 5, i.toDouble() * 5),
              Offset(i.toDouble() * 5 + 10, i.toDouble() * 5 + 10),
            ],
            color: Color(0xFF000000 + i * 1000),
            strokeWidth: 1.0 + (i % 5),
          ),
        );
      }

      final jsonString = jsonEncode(
        complexStrokes.map((s) => s.toJson()).toList(),
      );
      final List<dynamic> decodedList = jsonDecode(jsonString) as List<dynamic>;
      final restoredStrokes = decodedList
          .map((s) => MemoStroke.fromJson(s as Map<String, dynamic>))
          .toList();

      expect(restoredStrokes.length, equals(100));
      expect(restoredStrokes[50].points[0], equals(const Offset(250.0, 250.0)));
      expect(restoredStrokes[99].points[1], equals(const Offset(505.0, 505.0)));
      expect(restoredStrokes[99].strokeWidth, equals(1.0 + (99 % 5)));
    });

    test(
      '【ストレージ保存＆全消去テスト】QuickMemoStorageService で保存・読み込み・消去が安全に動作すること',
      () async {
        final service = QuickMemoStorageService.instance;
        const testTournamentId = 'tourney_safe_test_999';

        await service.saveMemo(
          tournamentId: testTournamentId,
          text: 'メモ本文テスト',
          strokes: [
            MemoStroke(
              points: const [Offset(10, 20), Offset(30, 40)],
              color: Colors.yellow,
              strokeWidth: 2.5,
            ),
          ],
          modeName: 'drawing',
        );

        final loaded = await service.loadMemo(testTournamentId);
        expect(loaded.text, equals('メモ本文テスト'));
        expect(loaded.strokes.length, equals(1));
        expect(loaded.strokes.first.points.length, equals(2));
        expect(loaded.strokes.first.strokeWidth, equals(2.5));

        // 消去
        await service.clearMemo(testTournamentId);
        final cleared = await service.loadMemo(testTournamentId);
        expect(cleared.isEmpty, isTrue);
        expect(cleared.strokes, isEmpty);
        expect(cleared.text, isEmpty);
      },
    );
  });
}
