import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🧪 【Unit 2/5】多言語・国際化ロケールフォールバック境界値テスト', () {
    const supportedLocales = [Locale('ja', 'JP'), Locale('en', 'US')];
    const defaultLocale = Locale('ja', 'JP');

    // 本番 MaterialApp と同等の堅牢なロケールフォールバックリゾルバ
    Locale resolveLocale(Locale? locale, Iterable<Locale> supported) {
      if (locale == null) return defaultLocale;
      for (final s in supported) {
        if (s.languageCode == locale.languageCode) {
          return s;
        }
      }
      return defaultLocale;
    }

    test('1. サポート対象言語（日本語・英語）が完全に一致・解決されること', () {
      expect(
        resolveLocale(const Locale('ja', 'JP'), supportedLocales),
        const Locale('ja', 'JP'),
      );
      expect(
        resolveLocale(const Locale('ja'), supportedLocales),
        const Locale('ja', 'JP'),
      );
      expect(
        resolveLocale(const Locale('en', 'US'), supportedLocales),
        const Locale('en', 'US'),
      );
      expect(
        resolveLocale(const Locale('en', 'GB'), supportedLocales),
        const Locale('en', 'US'),
      );
    });

    test('2. 未知の国際ロケール（仏・独・中・韓・西・アラビア語）で日本語へ安全にフォールバックすること', () {
      final exoticLocales = [
        const Locale('fr', 'FR'), // フランス
        const Locale('de', 'DE'), // ドイツ
        const Locale('zh', 'CN'), // 中国
        const Locale('ko', 'KR'), // 韓国
        const Locale('es', 'ES'), // スペイン
        const Locale('ar', 'SA'), // アラビア
        const Locale('ru', 'RU'), // ロシア
      ];

      for (final loc in exoticLocales) {
        final resolved = resolveLocale(loc, supportedLocales);
        expect(
          resolved,
          defaultLocale,
          reason: '${loc.languageCode} はデフォルトの日本語ロケールにフォールバックしなければならない',
        );
      }
    });

    test('3. null や未定義ロケールが渡された場合でも例外なくデフォルトを返すこと', () {
      expect(resolveLocale(null, supportedLocales), defaultLocale);
      expect(
        resolveLocale(const Locale('und'), supportedLocales),
        defaultLocale,
      );
    });
  });
}
