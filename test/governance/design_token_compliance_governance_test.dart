import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

void main() {
  group('🎨 【ガバナンス第3条】デザインシステムトークン厳格準拠 監査テスト', () {
    test(
      '1. app_tokens.dart に AppSpacing, AppRadius, AppFontSize 等の基幹トークンが完全定義されていること',
      () {
        final tokenFile = File('lib/shared/theme/app_tokens.dart');
        expect(tokenFile.existsSync(), isTrue);

        final content = tokenFile.readAsStringSync();
        expect(content.contains('class AppSpacing'), isTrue);
        expect(content.contains('class AppRadius'), isTrue);
        expect(content.contains('class AppFontSize'), isTrue);
        expect(content.contains('class AppEdgeInsets'), isTrue);
      },
    );

    test('2. 主要トークン値（Spacing, Radius, FontSize, AppKendoColors）が有効であること', () {
      expect(AppSpacing.xs, greaterThan(0));
      expect(AppSpacing.sm, greaterThan(AppSpacing.xs));
      expect(AppSpacing.md, greaterThan(AppSpacing.sm));
      expect(AppRadius.small, isNotNull);
      expect(AppRadius.medium, isNotNull);
      expect(AppFontSize.body, greaterThan(0));
      expect(AppKendoColors.aka, isNotNull);
      expect(AppKendoColors.shiro, isNotNull);
    });
  });
}
