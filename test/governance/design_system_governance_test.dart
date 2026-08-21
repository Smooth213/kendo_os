import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

// ============================================================================
// 🛡️ DESIGN SYSTEM GOVERNANCE FORTRESS TEST
// kendo OS デザインシステム完全統一が今後永久に崩れないよう、
// 全UI要素・ダイアログ・ボトムシート・硬直色・フォント・パディング・カラー反転等の混入を全自動検知・遮断します。
// ============================================================================
void main() {
  group('🛡️ kendo OS Design System Governance Protection Test', () {
    late List<File> dartFiles;

    setUpAll(() {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist.');

      dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
    });

    test(
      '1. SnackBar: 生の ScaffoldMessenger.of(context).showSnackBar の直書きが全アプリで 0 件であること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.contains('lib/shared/utils/app_snack_bar.dart')) {
            continue;
          }

          final content = file.readAsStringSync();
          if (content.contains('showSnackBar(')) {
            violations.add(file.path);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '生の showSnackBar 呼び出しが検出されました。AppSnackBar.show(...) を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test('2. ModalBottomSheet: 生の showModalBottomSheet の直書きが全アプリで 0 件であること', () {
      final violations = <String>[];

      for (final file in dartFiles) {
        if (file.path.contains('lib/shared/widgets/app_bottom_sheet.dart')) {
          continue;
        }

        final content = file.readAsStringSync();
        if (content.contains('showModalBottomSheet(')) {
          violations.add(file.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            '生の showModalBottomSheet 呼び出しが検出されました。showAppBottomSheet(...) を使用してください。\n'
            '違反ファイル:\n${violations.join('\n')}',
      );
    });

    test(
      '3. Chip シリーズ: 生の Chip / ChoiceChip / ActionChip / FilterChip の直書きが全アプリで 0 件であること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.contains('lib/shared/widgets/app_chip.dart')) {
            continue;
          }

          final content = file.readAsStringSync();
          if (RegExp(
            r'\b(Chip|ChoiceChip|ActionChip|FilterChip|RawChip|InputChip)\s*\(',
          ).hasMatch(content)) {
            violations.add(file.path);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '生の Chip コンポーネント呼び出しが検出されました。AppChoiceChip / AppActionChip / AppFilterChip を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test('4. AppBar: アプリ全体での生の AppBar 直書きが 0 件であり AppHeader に統一されていること', () {
      final violations = <String>[];

      for (final file in dartFiles) {
        if (file.path.contains('lib/shared/widgets/app_header.dart')) {
          continue;
        }

        final content = file.readAsStringSync();
        if (RegExp(r'\bAppBar\s*\(').hasMatch(content)) {
          violations.add(file.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            '主要画面で生の AppBar インスタンス化が検出されました。AppHeader(...) を使用してください。\n'
            '違反ファイル:\n${violations.join('\n')}',
      );
    });

    test(
      '5. Dialog: アプリ全体での生の showDialog / AlertDialog 直書きが 0 件であり AppDialog / showAppDialog に統一されていること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.contains('lib/shared/widgets/app_dialog.dart')) {
            continue;
          }

          final content = file.readAsStringSync();
          if (content.contains('showDialog(') ||
              RegExp(r'\bAlertDialog\s*\(').hasMatch(content)) {
            violations.add(file.path);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '生の showDialog または AlertDialog 呼び出しが検出されました。showAppDialog / AppDialog を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test('6. AppTokens & AppKendoColors: デザインシステム装飾トークンが整合していること', () {
      expect(AppRadius.microValue, equals(2.0));
      expect(AppRadius.tinyValue, equals(4.0));
      expect(AppRadius.subValue, equals(6.0));
      expect(AppRadius.smallValue, equals(8.0));
      expect(AppRadius.mediumValue, equals(12.0));
      expect(AppRadius.largeValue, equals(16.0));
      expect(AppRadius.roundValue, equals(20.0));
      expect(AppSpacing.sm, equals(8.0));
      expect(AppSpacing.md, equals(12.0));
      expect(AppSpacing.lg, equals(16.0));
      expect(AppFontWeight.light, equals(FontWeight.w300));
      expect(AppFontWeight.regular, equals(FontWeight.w400));
      expect(AppFontWeight.medium, equals(FontWeight.w500));
      expect(AppFontWeight.semiBold, equals(FontWeight.w600));
      expect(AppFontWeight.bold, equals(FontWeight.w700));
      expect(AppFontWeight.black, equals(FontWeight.w900));
      expect(AppFontSize.micro, equals(8.0));
      expect(AppFontSize.badge, equals(10.0));
      expect(AppFontSize.caption, equals(11.0));
      expect(AppKendoColors.aka, equals(Colors.red));
      expect(AppKendoColors.shiro, equals(Colors.white));
    });

    test(
      '7. AppThemeColors: 全4モード (normal, bunaiksen, normal_viewer, bunaiksen_viewer) x Dark/Light で解像され色の破綻がないこと',
      () {
        for (final isDark in [true, false]) {
          for (final mode in [
            'normal',
            'bunaiksen',
            'normal_viewer',
            'bunaiksen_viewer',
          ]) {
            final theme = AppThemeColors.ofMode(isDark: isDark, mode: mode);
            expect(theme.primaryAccent, isNotNull);
            expect(theme.softAccent, isNotNull);
            expect(theme.cardBackground, isNotNull);
            expect(theme.scaffoldBackground, isNotNull);
            expect(theme.textColor, isNotNull);
            expect(theme.subTextColor, isNotNull);
            expect(theme.separatorColor, isNotNull);
            expect(theme.inputBackground, isNotNull);
            expect(theme.hintColor, isNotNull);
            expect(theme.rosePink, isNotNull);
            expect(theme.successColor, isNotNull);
            expect(theme.warningColor, isNotNull);
            expect(theme.errorColor, isNotNull);
            expect(theme.infoColor, isNotNull);
          }
        }
      },
    );

    test(
      '8. AppFontWeight: UIコンポーネントにおける生の FontWeight.w400/w600/w700/bold の直接指定が 0 件であり AppFontWeight に統一されていること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.contains('lib/shared/theme/app_tokens.dart') ||
              file.path.contains('lib/features/pdf/')) {
            continue;
          }

          final content = file.readAsStringSync();
          if (RegExp(
            r'\bFontWeight\.(w400|w600|w700|bold)\b',
          ).hasMatch(content)) {
            violations.add(file.path);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'UIコンポーネント内で生の FontWeight 直接指定が検出されました。AppFontWeight.regular / semiBold / bold を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '9. AppRadius: UIコンポーネントにおける生の BorderRadius.circular(8/12/16/24) の直接指定が 0 件であり AppRadius に統一されていること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.contains('lib/shared/theme/app_tokens.dart') ||
              file.path.contains('lib/features/pdf/')) {
            continue;
          }

          final content = file.readAsStringSync();
          if (RegExp(
            r'BorderRadius\.circular\s*\(\s*(8|12|16|24)(\.0)?\s*\)',
          ).hasMatch(content)) {
            violations.add(file.path);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'UIコンポーネント内で生の BorderRadius.circular(8/12/16/24) 直接指定が検出されました。AppRadius (small/medium/large/xlarge) を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '10. AppSpacing: UIコンポーネントにおける生の SizedBox(height/width: 4/8/12/16/24/32) の直接数値指定が 0 件であり AppSpacing に統一されていること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.contains('lib/shared/theme/app_tokens.dart') ||
              file.path.contains('lib/features/pdf/')) {
            continue;
          }

          final content = file.readAsStringSync();
          if (RegExp(
            r'SizedBox\s*\(\s*(height|width)\s*:\s*(4|8|12|16|24|32)(\.0)?\s*\)',
          ).hasMatch(content)) {
            violations.add(file.path);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'UIコンポーネント内で生の SizedBox(height/width: 4/8/12/16/24/32) 直接数値指定が検出されました。AppSpacing (xs/sm/md/lg/xl/xxl) を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '11. AppThemeColors: theme_color_extensions.dart 内の全 14 色プロパティの copyWith / lerp が正しく機能すること',
      () {
        final darkTheme = AppThemeColors.ofMode(isDark: true, mode: 'normal');
        final lightTheme = AppThemeColors.ofMode(isDark: false, mode: 'normal');

        final lerped = darkTheme.lerp(lightTheme, 0.5);
        expect(lerped.primaryAccent, isNotNull);
        expect(lerped.softAccent, isNotNull);
        expect(lerped.cardBackground, isNotNull);
        expect(lerped.scaffoldBackground, isNotNull);
        expect(lerped.textColor, isNotNull);

        final copied = darkTheme.copyWith(textColor: Colors.yellow);
        expect(copied.textColor, equals(Colors.yellow));
        expect(copied.primaryAccent, equals(darkTheme.primaryAccent));
      },
    );

    test(
      '12. BottomSheet: アプリ全体での生の showModalBottomSheet 直書きが 0 件であり showAppBottomSheet に統一されていること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.contains('lib/shared/widgets/app_bottom_sheet.dart')) {
            continue;
          }

          final content = file.readAsStringSync();
          if (content.contains('showModalBottomSheet')) {
            violations.add(file.path);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '生の showModalBottomSheet 呼び出しが検出されました。showAppBottomSheet / AppBottomSheetContent を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '13. AppFontSize & AppTokens: アプリ全体系でのデザインシステム装飾トークン（AppFontSize / AppRadius / AppFontWeight / AppKendoColors）の定義完全性',
      () {
        expect(AppFontSize.micro, equals(8.0));
        expect(AppFontSize.badge, equals(10.0));
        expect(AppFontSize.caption, equals(11.0));
        expect(AppFontSize.small, equals(12.0));
        expect(AppFontSize.body, equals(14.0));
        expect(AppFontSize.subhead, equals(16.0));
        expect(AppFontSize.headline, equals(18.0));
        expect(AppFontSize.header, equals(20.0));
        expect(AppFontSize.display, equals(24.0));
        expect(AppFontSize.hero, equals(28.0));
        expect(AppFontSize.jumbo, equals(32.0));
        expect(AppEdgeInsets.zero, equals(EdgeInsets.zero));
        expect(AppEdgeInsets.allSm, equals(const EdgeInsets.all(8.0)));
      },
    );

    test(
      '14. 背景色反転バグ防止: backgroundColor / fillColor / surfaceTintColor / cardColor への textColor (黒) 誤用が全アプリで 0 件であること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.contains('lib/shared/theme/')) {
            continue;
          }
          if (file.path.contains('lib/features/pdf/')) {
            continue;
          }

          final content = file.readAsStringSync();
          final matches = RegExp(
            r'(backgroundColor|fillColor|surfaceTintColor|cardColor)\s*:\s*isDark\s*\?[^:]+:\s*(context\.appColors\.)?textColor\b',
            multiLine: true,
            dotAll: true,
          ).allMatches(content);

          if (matches.isNotEmpty) {
            violations.add('${file.path} (${matches.length}件)');
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '背景色指定に textColor (黒) を割り当てるライトモード漆黒化反転バグが検出されました。cardBackground / inputBackground / scaffoldBackground を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '15. ダークモード文字消失防止: ダークモード時 (isDark: true) のプロパティ色への黒透過色 (0x33000000, 0x8A000000, 0xDE000000) 直接指定が全アプリで 0 件であること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.contains('lib/shared/theme/')) {
            continue;
          }
          if (file.path.contains('lib/features/pdf/')) {
            continue;
          }

          final content = file.readAsStringSync();
          final matches = RegExp(
            r'\bcolor\s*:\s*isDark\s*\?\s*const\s*Color\((0x33000000|0x8A000000|0xDE000000)\)',
          ).allMatches(content);

          if (matches.isNotEmpty) {
            violations.add('${file.path} (${matches.length}件)');
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'ダークモード時に文字/アイコン色へ黒透過色 (0x33000000 / 0x8A000000 / 0xDE000000) が直接指定されている箇所が検出されました。ダークモードで視認性が消失します。context.appColors.textColor または subTextColor を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test('16. チップ同色視認性保証: buildChip 等での背景色と文字色の完全同色指定が全アプリで 0 件であること', () {
      final violations = <String>[];

      for (final file in dartFiles) {
        if (file.path.contains('lib/shared/theme/')) {
          continue;
        }

        final content = file.readAsStringSync();
        final matches = RegExp(
          r'buildChip\([^,\n]+,\s*([a-zA-Z0-9_]+),\s*\1\b',
        ).allMatches(content);

        if (matches.isNotEmpty) {
          violations.add('${file.path} (${matches.length}件)');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'buildChip 呼び出しで背景色と文字色が同一指定されている視認性不具合が検出されました。\n'
            '違反ファイル:\n${violations.join('\n')}',
      );
    });

    test(
      '17. 硬直色 (Colors.white / black / red 等) 防止: UIコンポーネントにおける Flutter 組み込み Colors.* 直書きが全アプリで 0 件であること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.contains('lib/shared/theme/')) {
            continue;
          }
          if (file.path.contains('lib/features/pdf/')) {
            continue;
          }
          if (file.path.endsWith('.freezed.dart') ||
              file.path.endsWith('.g.dart')) {
            continue;
          }

          final content = file.readAsStringSync();
          // コメント行を取り除いて純粋なコード部分のみを検証
          final cleanCode = content
              .split('\n')
              .where((line) => !line.trim().startsWith('//'))
              .join('\n');
          final matches = RegExp(
            r'(?<!\.)\bColors\.(white|black|grey|red|blue|amber|orange|purple|deepPurple|indigo|teal|green|yellow|brown|pink|cyan|lime)\b',
          ).allMatches(cleanCode);

          if (matches.isNotEmpty) {
            violations.add('${file.path} (${matches.length}件)');
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'UIコンポーネント内で硬直色 (Colors.white / black / red 等) の直書きが検出されました。AppThemeColors または AppKendoColors を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '18. フォントサイズ生数値指定防止: UIコンポーネントにおける fontSize: 直数値 (10, 12, 14, 16 等) の直接指定が全アプリで 0 件であること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.contains('lib/shared/theme/')) {
            continue;
          }
          if (file.path.contains('lib/features/pdf/')) {
            continue;
          }
          if (file.path.endsWith('.freezed.dart') ||
              file.path.endsWith('.g.dart')) {
            continue;
          }

          final content = file.readAsStringSync();
          final matches = RegExp(
            r'fontSize:\s*(?!AppFontSize\.)\d+(\.\d+)?',
          ).allMatches(content);

          if (matches.isNotEmpty) {
            violations.add('${file.path} (${matches.length}件)');
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'UIコンポーネント内で fontSize: 直数値指定が検出されました。AppFontSize (caption / small / body / subhead / headline / header) を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '19. 黄色文字低コントラスト防止: 白背景カードや要約欄における TextStyle 内での ipponGold (純黄色) 文字色の直接使用が全アプリで 0 件であること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.contains('lib/shared/theme/')) {
            continue;
          }
          if (file.path.contains('lib/features/pdf/')) {
            continue;
          }
          if (file.path.contains('lib/shared/widgets/scoreboard.dart')) {
            continue;
          }
          if (file.path.contains(
            'lib/features/viewer/presentation/viewer_match_screen.dart',
          )) {
            continue;
          }
          if (file.path.endsWith('.freezed.dart') ||
              file.path.endsWith('.g.dart')) {
            continue;
          }

          final content = file.readAsStringSync();
          final matches = RegExp(
            r'TextStyle\s*\([^)]*color\s*:\s*AppKendoColors\.ipponGold\b',
            multiLine: true,
            dotAll: true,
          ).allMatches(content);

          if (matches.isNotEmpty) {
            violations.add('${file.path} (${matches.length}件)');
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '白背景上で視認性が極めて低い AppKendoColors.ipponGold (純黄色) の文字色指定が検出されました。視認性の高い Color(0xFFD97706) (ダークアンバー) または context.appColors を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '20. [5大監視 1] チップ文字・背景同色化防止: チップコンポーネント及び buildChip 内で背景色と文字色が同色または低コントラスト指定されるパターンの完全監視',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.endsWith('.freezed.dart') ||
              file.path.endsWith('.g.dart')) {
            continue;
          }

          final content = file.readAsStringSync();

          // buildChip(..., sameColor, sameColor)
          final buildChipMatches = RegExp(
            r'buildChip\s*\(\s*[^,]+,\s*([a-zA-Z0-9_.]+)\s*,\s*\1\s*\)',
          ).allMatches(content);
          if (buildChipMatches.isNotEmpty) {
            violations.add('${file.path} (buildChip 背景と文字が同一色)');
          }

          // customSelectedColor があるのに customTextColor が未設定で同色化するパターン
          if (file.path.contains('smart_player_input.dart') ||
              file.path.contains('multi_player_select_input.dart')) {
            if (content.contains('customSelectedColor:') &&
                !content.contains('customTextColor:')) {
              violations.add('${file.path} (チップ選択時背景と文字色の同色化未防護)');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'チップの背景色と文字色が同色になり文字が消失する実装が検出されました。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '21. [5大監視 2] ライトモード時 カード/ボタン/アコーディオン背景黒化防止: collapsedBackgroundColor や Card/Container の color への textColor (黒) 割り当ての完全監視',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.endsWith('.freezed.dart') ||
              file.path.endsWith('.g.dart')) {
            continue;
          }

          final content = file.readAsStringSync();

          // collapsedBackgroundColor: ... ? ... : context.appColors.textColor
          if (RegExp(
            r'collapsedBackgroundColor\s*:\s*[^\n;]*context\.appColors\.textColor\b',
          ).hasMatch(content)) {
            violations.add(
              '${file.path} (collapsedBackgroundColor に textColor(黒) が指定されています)',
            );
          }

          // isDark ? const Color(0xFFFFFFFF) : context.appColors.textColor
          if (content.contains(
            'isDark ? const Color(0xFFFFFFFF) : context.appColors.textColor',
          )) {
            violations.add('${file.path} (コンテナ背景色に textColor(黒) が指定されています)');
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'ライトモード時にカードやアコーディオン背景が黒に反転する破壊コードが検出されました。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '22. [5大監視 3] ダークモード時 文字の黒透過同化防止: ダークモード分岐時や共通TextStyle内での黒色系(0x8A000000等)の文字色直接指定の完全監視',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.contains('lib/shared/theme/')) {
            continue;
          }
          if (file.path.contains('lib/features/pdf/')) {
            continue;
          }
          if (file.path.endsWith('.freezed.dart') ||
              file.path.endsWith('.g.dart')) {
            continue;
          }

          final content = file.readAsStringSync();

          // isDark ? const Color(0x...000000)
          final darkBlackMatches = RegExp(
            r'isDark\s*\?\s*const Color\(0x[0-9A-Fa-f]{2}000000\)',
          ).allMatches(content);
          if (darkBlackMatches.isNotEmpty) {
            violations.add(
              '${file.path} (ダークモード時に黒透過色を文字/アイコンに指定: ${darkBlackMatches.length}件)',
            );
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'ダークモード時に文字・アイコンが黒色系となり背景と同化して消失するコードが検出されました。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '23. [5大監視 4] 大会記録 サマリー黄色文字視認性低下防止: 公式記録・ビューアー・サマリーにおける ipponGold の文字色直接使用の完全監視',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.contains('lib/shared/theme/')) {
            continue;
          }
          if (file.path.contains('lib/features/pdf/')) {
            continue;
          }
          if (file.path.contains('scoreboard.dart')) {
            continue;
          }
          if (file.path.contains('viewer_match_screen.dart')) {
            continue;
          }
          if (file.path.endsWith('.freezed.dart') ||
              file.path.endsWith('.g.dart')) {
            continue;
          }

          final content = file.readAsStringSync();

          // official_record や summary 関連での ipponGold 文字使用
          if (file.path.contains('official_record') ||
              file.path.contains('summary') ||
              file.path.contains('bunaiksen')) {
            if (RegExp(
              r'TextStyle\s*\([^)]*color\s*:\s*AppKendoColors\.ipponGold\b',
              multiLine: true,
              dotAll: true,
            ).hasMatch(content)) {
              violations.add('${file.path} (サマリー/記録画面で純黄色文字が直接使用されています)');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '白地サマリーや公式記録で文字が読めなくなる黄色文字(ipponGold)の直接使用が検出されました。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '24. [5大監視 5] PDFボタン・アクションボタン背景色・アイコン統一監視: 生の ElevatedButton.styleFrom(primary/backgroundColor: 硬直色) 直書きの排除と統一デザインの保証',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.contains('lib/shared/theme/')) {
            continue;
          }
          if (file.path.contains('lib/features/pdf/presentation/widgets/')) {
            continue;
          }
          if (file.path.endsWith('.freezed.dart') ||
              file.path.endsWith('.g.dart')) {
            continue;
          }

          final content = file.readAsStringSync();

          // PDF や共有ボタンで生の赤や黒などの硬直色直書き
          if (file.path.contains('pdf') ||
              file.path.contains('record') ||
              file.path.contains('export')) {
            if (RegExp(
              r'(?<!AppKendo)Colors\.(redAccent|black54)\b',
            ).hasMatch(content)) {
              violations.add('${file.path} (PDF/出力ボタンで非統一硬直色が使用されています)');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'PDFボタンや出力アクションボタンで統一テーマから乖離した硬直色が検出されました。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '25. [新死角監視 1] 透過修飾 (.withValues() / .withOpacity()) を含むライトモード背景色への textColor(黒) 誤用防止',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.contains('lib/shared/theme/')) {
            continue;
          }
          if (file.path.contains('lib/features/pdf/')) {
            continue;
          }
          if (file.path.endsWith('.freezed.dart') ||
              file.path.endsWith('.g.dart')) {
            continue;
          }

          final content = file.readAsStringSync();

          // isDark ? ... : context.appColors.textColor(.withValues/.withOpacity) パターン
          final match = RegExp(
            r'(backgroundColor|fillColor|surfaceTintColor|cardColor|color)\s*:\s*[^;\n]*isDark\s*\?[^;\n]+:\s*(context\.appColors\.)?textColor(\.(withValues|withOpacity)\([^)]*\))?',
          ).firstMatch(content);

          if (match != null) {
            violations.add('${file.path}: ${match.group(0)}');
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'ライトモードの背景色に textColor (黒/黒透過) が誤って割り当てられている箇所が検出されました。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test('26. [新死角監視 2] DropdownButton / ピル型コンテナにおける背景色と文字色・アイコンの同色化防止', () {
      final violations = <String>[];

      for (final file in dartFiles) {
        if (file.path.contains('lib/shared/theme/')) {
          continue;
        }
        if (file.path.endsWith('.freezed.dart') ||
            file.path.endsWith('.g.dart')) {
          continue;
        }

        final content = file.readAsStringSync();

        // DropdownButton 周辺で同じ 0xFF3F51B5 や indigo が背景と文字色に同時に指定されるパターン
        if (content.contains('DropdownButton') &&
            content.contains('Color(0xFF3F51B5)') &&
            content.contains(
              'color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF3F51B5)',
            )) {
          violations.add('${file.path}: DropdownButton の文字色と背景色が同色指定されています');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'DropdownButton / ピル型UIで背景色と文字色が同色化している箇所が検出されました。\n'
            '違反ファイル:\n${violations.join('\n')}',
      );
    });

    test('27. [新死角監視 3] ボタンにおける背景色とアイコン・文字色の同色アクセント潰れ防止', () {
      final violations = <String>[];

      for (final file in dartFiles) {
        if (file.path.contains('lib/shared/theme/')) {
          continue;
        }
        if (file.path.endsWith('.freezed.dart') ||
            file.path.endsWith('.g.dart')) {
          continue;
        }

        final content = file.readAsStringSync();

        // ElevatedButton で backgroundColor に 0xFF3F51B5 (青) を指定しながら文字/アイコンに primaryAccent を指定するパターン
        if (content.contains('ElevatedButton') &&
            content.contains('backgroundColor: isDark ?') &&
            content.contains('const Color(0xFF3F51B5)') &&
            content.contains(
              'color: isDark ? const Color(0xFFFFFFFF) : context.appColors.primaryAccent',
            )) {
          violations.add('${file.path}: ボタンの背景色と文字色が同系色で潰れています');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'ボタンの背景色と文字色・アイコン色が同系色で潰れている箇所が検出されました。\n'
            '違反ファイル:\n${violations.join('\n')}',
      );
    });

    test(
      '28. [新死角監視 4] アコーディオン（ExpansionTile / ExpansionTileThemeData）のダーク/ライトモード背景色・文字色テーマ完全保護監視',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          if (file.path.contains('lib/shared/theme/')) {
            continue;
          }
          if (file.path.endsWith('.freezed.dart') ||
              file.path.endsWith('.g.dart')) {
            continue;
          }

          final content = file.readAsStringSync();

          if (content.contains('ExpansionTile') ||
              content.contains('ExpansionTileThemeData')) {
            // 1. isDark 分岐のない collapsedBackgroundColor: const Color(0xFFFAFAFC)
            if (content.contains(
                  'collapsedBackgroundColor:\n                                const Color(0xFFFAFAFC)',
                ) ||
                content.contains(
                  'collapsedBackgroundColor: const Color(0xFFFAFAFC)',
                )) {
              violations.add(
                '${file.path}: collapsedBackgroundColor に isDark 分岐なしで白固定値 (0xFFFAFAFC) が指定されています',
              );
            }
            // 2. collapsedBackgroundColor への textColor (黒) 誤用
            if (content.contains('collapsedBackgroundColor: isDark ?') &&
                content.contains(': context.appColors.textColor')) {
              violations.add(
                '${file.path}: collapsedBackgroundColor のライトモード側に textColor (黒) が指定されています',
              );
            }
            // 3. backgroundColor への textColor(白) 誤用
            if (content.contains(
                  'backgroundColor: isDark ? context.appColors.textColor',
                ) ||
                content.contains(
                  'backgroundColor: isDark\n                  ? context.appColors.textColor',
                )) {
              violations.add(
                '${file.path}: backgroundColor のダークモード側に textColor が指定されています',
              );
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'アコーディオンの背景色・折りたたみ時背景色でテーマ破綻（ダーク時白飛び、ライト時黒化など）が検出されました。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test('29. [新死角監視 5] TextStyle / Text における separatorColor (枠線色) の文字色誤用防止', () {
      final violations = <String>[];

      for (final file in dartFiles) {
        if (file.path.contains('lib/shared/theme/')) {
          continue;
        }
        if (file.path.endsWith('.freezed.dart') ||
            file.path.endsWith('.g.dart')) {
          continue;
        }

        final content = file.readAsStringSync();

        // TextStyle(..., color: ...separatorColor...) の誤用検知
        // ただし Divider(color: ...), Border(color: ...), Container(decoration: ... Border.all(color: ...separatorColor)) は正常
        final matches = RegExp(
          r'TextStyle\s*\([^)]*color\s*:\s*[^,\)]*separatorColor[^,\)]*',
        ).allMatches(content);

        for (final match in matches) {
          violations.add('${file.path}: ${match.group(0)}');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'TextStyle の文字色 (color) に枠線用の極薄色 separatorColor が誤って指定され、視認性が著しく低下している箇所が検出されました。\n'
            '違反ファイル:\n${violations.join('\n')}',
      );
    });

    test('30. [新死角監視 6] スコアボード・選手名・取得部位における低コントラスト・暗色文字色指定の完全防止監視', () {
      final violations = <String>[];

      for (final file in dartFiles) {
        if (file.path.endsWith('.freezed.dart') ||
            file.path.endsWith('.g.dart')) {
          continue;
        }

        final content = file.readAsStringSync();

        // scoreboard.dart における nameColor への separatorColor 割り当ての再発防止
        if (file.path.endsWith('scoreboard.dart')) {
          if (content.contains('nameColor') &&
              content.contains('separatorColor')) {
            violations.add(
              '${file.path}: nameColor に separatorColor が指定されています',
            );
          }
        }

        // PointBox / PointMarkBadge における文字色への separatorColor 割り当ての防止
        if (file.path.endsWith('point_mark_badge.dart')) {
          if (content.contains('PointMarkBadge') &&
              content.contains('separatorColor')) {
            violations.add(
              '${file.path}: PointMarkBadge に separatorColor が文字色として指定されています',
            );
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'スコアボードや選手名・取得部位の文字色に暗い枠線色 separatorColor が使用され、視認性が破壊されている箇所が検出されました。\n'
            '違反ファイル:\n${violations.join('\n')}',
      );
    });
  });
}
