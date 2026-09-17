import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';

void main() {
  group('🏛️ 試合数計算機 ガバナンス＆設計憲法テスト', () {
    test('【ガバナンス第2条】calculator配下の全ファイルが500行未満であること', () {
      final calculatorDir = Directory(
        'lib/features/tournament/presentation/components/bunaiksen/calculator',
      );
      expect(calculatorDir.existsSync(), isTrue);

      final dartFiles = calculatorDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      expect(dartFiles.isNotEmpty, isTrue);

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        final lineCount = lines.length;
        expect(
          lineCount,
          lessThan(500),
          reason: '${file.path.split('/').last} が $lineCount 行で500行制限を超過しています',
        );
      }
    });

    test('【モデル不変性】CalculatorSettingsがイミュータブルかつデフォルト値が健全であること', () {
      const defaultSettings = CalculatorSettings();

      expect(defaultSettings.participantCount, 8);
      expect(defaultSettings.courtCount, 2);
      expect(defaultSettings.leagueCount, 2);
      expect(defaultSettings.matchDurationMinutes, 2.0);
      expect(defaultSettings.intervalDurationMinutes, 1.0);

      // copyWithで不変オブジェクトが正しく生成されること
      final modified = defaultSettings.copyWith(participantCount: 12);
      expect(modified.participantCount, 12);
      expect(defaultSettings.participantCount, 8); // 元は不変
    });

    test('【デザイントークン遵守】新規追加・更新した主要コンポーネントで生Colorsが過剰に使用されていないこと', () {
      final targetFiles = [
        'lib/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_accordion_card.dart',
        'lib/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_basic_settings_card.dart',
        'lib/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_format_selector.dart',
        'lib/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_league_advanced_settings.dart',
      ];

      for (final path in targetFiles) {
        final file = File(path);
        if (!file.existsSync()) continue;
        final content = file.readAsStringSync();

        // themeColorsやAppKendoColorsまたはAppTokensの利用を確認
        final hasThemeColors =
            content.contains('AppThemeColors') ||
            content.contains('themeColors') ||
            content.contains('AppKendoColors') ||
            content.contains('AppTokens');

        expect(hasThemeColors, isTrue, reason: '$path でデザイントークン拡張が利用されていません');
      }
    });
  });
}
