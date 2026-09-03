import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/widgets/room_join_validator.dart';

void main() {
  group('RoomJoinValidator.normalize - ルームコード正規化', () {
    test('前後のスペースがトリムされること', () {
      expect(RoomJoinValidator.normalize('  tokyo_dojo  '), 'tokyo_dojo');
    });

    test('大文字が小文字に変換されること', () {
      expect(RoomJoinValidator.normalize('Tokyo_Dojo_2026'), 'tokyo_dojo_2026');
    });

    test('空文字はそのまま空文字になること', () {
      expect(RoomJoinValidator.normalize(''), '');
    });

    test('既に正規化済みの文字列は変化しないこと', () {
      expect(RoomJoinValidator.normalize('abc123'), 'abc123');
    });
  });

  group('RoomJoinValidator.validate - バリデーション', () {
    test('空文字 → エラー（コード入力を求める）', () {
      final result = RoomJoinValidator.validate('');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, isNotEmpty);
    });

    test('スペースのみ → エラー', () {
      final result = RoomJoinValidator.validate('   ');
      expect(result.isValid, isFalse);
    });

    test('半角英数字のみ → OK', () {
      final result = RoomJoinValidator.validate('abc123');
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('ハイフン含む → OK', () {
      final result = RoomJoinValidator.validate('tokyo-dojo-2026');
      expect(result.isValid, isTrue);
    });

    test('アンダーバー含む → OK', () {
      final result = RoomJoinValidator.validate('tokyo_dojo_2026');
      expect(result.isValid, isTrue);
    });

    test('ハイフンとアンダーバー混在 → OK', () {
      final result = RoomJoinValidator.validate('tokyo_dojo-2026');
      expect(result.isValid, isTrue);
    });

    test('日本語文字 → エラー', () {
      final result = RoomJoinValidator.validate('東京道場');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, isNotEmpty);
    });

    test('スペース含む → エラー', () {
      final result = RoomJoinValidator.validate('tokyo dojo');
      expect(result.isValid, isFalse);
    });

    test('特殊記号（@）含む → エラー', () {
      final result = RoomJoinValidator.validate('tokyo@dojo');
      expect(result.isValid, isFalse);
    });

    test('大文字英字 → 正規化後にOKになること', () {
      // validateはnormalizeを内部で使う
      final result = RoomJoinValidator.validate('TOKYO_DOJO');
      expect(result.isValid, isTrue);
    });

    test('現実的な道場コード例 → OK', () {
      final codes = [
        'shinagawa-kendo-2026',
        'osaka_dojo01',
        'test123',
        'a',
        '1234567890',
      ];
      for (final code in codes) {
        final result = RoomJoinValidator.validate(code);
        expect(result.isValid, isTrue, reason: 'コード「$code」は有効であるべき');
      }
    });
  });

  group('RoomJoinValidationResult - 結果オブジェクト', () {
    test('ok()コンストラクタはisValid=true, errorMessage=nullであること', () {
      const result = RoomJoinValidationResult.ok();
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('error()コンストラクタはisValid=false, errorMessageが設定されること', () {
      const result = RoomJoinValidationResult.error('テストエラー');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('テストエラー'));
    });
  });
}
