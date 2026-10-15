import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/quick_next_match/kata_pair_helper.dart';

void main() {
  group('[Unit] KataPairHelperの検証', () {
    test('isPair: 中黒を含む場合はtrue、含まない場合はfalseであること', () {
      expect(KataPairHelper.isPair('皿田 脩人・塚本 大道'), isTrue);
      expect(KataPairHelper.isPair('皿田 脩人'), isFalse);
      expect(KataPairHelper.isPair(null), isFalse);
    });

    test('parsePair: 木刀基本技の場合、元立ち・掛かり手として正しく分解できること', () {
      final members = KataPairHelper.parsePair(
        '皿田 脩人・塚本 大道',
        posName: '木刀による剣道基本技稽古法（5本）',
      );
      expect(members.length, 2);
      expect(members[0].role, '元立ち');
      expect(members[0].name, '皿田 脩人');
      expect(members[1].role, '掛かり手');
      expect(members[1].name, '塚本 大道');
    });

    test('parsePair: 日本剣道形の場合、打太刀・仕太刀として正しく分解できること', () {
      final members = KataPairHelper.parsePair('佐藤・鈴木', posName: '日本剣道形');
      expect(members.length, 2);
      expect(members[0].role, '打太刀');
      expect(members[0].name, '佐藤');
      expect(members[1].role, '仕太刀');
      expect(members[1].name, '鈴木');
    });

    test('updateMember: 1人目を変更したとき、2人目が維持されること', () {
      final updated = KataPairHelper.updateMember('皿田 脩人・塚本 大道', 0, '田中 太郎');
      expect(updated, '田中 太郎・塚本 大道');
    });

    test('updateMember: 2人目を変更したとき、1人目が維持されること', () {
      final updated = KataPairHelper.updateMember('皿田 脩人・塚本 大道', 1, '山田 花子');
      expect(updated, '皿田 脩人・山田 花子');
    });

    test('updateMember: プレフィックス付きの場合、プレフィックスが維持されること', () {
      final updated = KataPairHelper.updateMember(
        '打太刀: 皿田 脩人・仕太刀: 塚本 大道',
        1,
        '山田 花子',
      );
      expect(updated, '打太刀: 皿田 脩人・仕太刀: 山田 花子');
    });
  });
}
