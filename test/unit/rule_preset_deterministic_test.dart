import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/rule_preset.dart';

void main() {
  group('[Unit] RulePreset 公式プリセット健全性・決定論テスト', () {
    test('小学生練成会プリセットが1分30秒一本勝負かつ判定あり延長なしの設定値を保持すること', () {
      final preset = RulePreset.elementaryRenseikai;

      expect(preset.id, equals('elementary_renseikai'));
      expect(preset.name, equals('小学生練成会'));
      expect(preset.description, contains('1分30秒一本勝負'));

      final config = preset.config;
      expect(config.time.matchTimeMinutes, equals(1.5));
      expect(config.time.isRunningTime, isFalse);
      expect(config.scoring.isIpponShobu, isTrue);
      expect(config.scoring.ipponLimit, equals(1));
      expect(config.encho.isEnchoUnlimited, isFalse);
      expect(config.encho.enchoCount, equals(0));
      expect(config.draw.hasHantei, isTrue);
    });

    test('高体連団体戦プリセットが4分3本勝負かつ引き分けあり代表戦一本勝負の設定値を保持すること', () {
      final preset = RulePreset.highSchoolTeam;

      expect(preset.id, equals('high_school_team'));
      expect(preset.name, equals('高体連団体戦'));
      expect(preset.description, contains('4分3本勝負'));

      final config = preset.config;
      expect(config.time.matchTimeMinutes, equals(4.0));
      expect(config.time.isRunningTime, isFalse);
      expect(config.scoring.isIpponShobu, isFalse);
      expect(config.scoring.ipponLimit, equals(2));
      expect(config.encho.isEnchoUnlimited, isFalse);
      expect(config.encho.enchoCount, equals(0));
      expect(config.draw.hasHantei, isFalse);
      expect(config.team.isKachinuki, isFalse);
      expect(config.team.hasRepresentativeMatch, isTrue);
      expect(config.team.isDaihyoIpponShobu, isTrue);
    });

    test('道場大会一般プリセットが3分3本勝負かつ2分延長1回後に判定の設定値を保持すること', () {
      final preset = RulePreset.dojoTournament;

      expect(preset.id, equals('dojo_tournament'));
      expect(preset.name, equals('道場大会（一般）'));
      expect(preset.description, contains('3分3本勝負'));

      final config = preset.config;
      expect(config.time.matchTimeMinutes, equals(3.0));
      expect(config.encho.isEnchoUnlimited, isFalse);
      expect(config.encho.enchoTimeMinutes, equals(2.0));
      expect(config.encho.enchoCount, equals(1));
      expect(config.draw.hasHantei, isTrue);
    });

    test('全公式プリセットリストの識別子が一意であり設定値が正常に展開されること', () {
      final officials = RulePreset.officials;
      expect(officials, isNotEmpty);
      expect(officials.length, equals(3));

      final ids = officials.map((p) => p.id).toSet();
      expect(ids.length, equals(officials.length));

      for (final preset in officials) {
        expect(preset.id, isNotEmpty);
        expect(preset.name, isNotEmpty);
        expect(preset.description, isNotEmpty);
        expect(preset.config.schemaVersion, equals(1));
        expect(preset.config.time.matchTimeMinutes, greaterThan(0));
        expect(preset.config.scoring.ipponLimit, greaterThan(0));
      }
    });
  });
}
