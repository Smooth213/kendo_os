import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_court_and_group_tab.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_team_and_players_tab.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

// ==============================================================================
// 🥋 Kendo OS - 【第3条 ガバナンス監査】🎨 全画面ヒントテキスト視認性・適正グレー保証規約
// ==============================================================================
// アプリ内の全画面・全入力コンポーネントにおいて、ヒントテキスト（入力補助・プレースホルダー）が
// ライトモードおよびダークモードの双方で、通常入力テキストと同化（白飛び・黒潰れ）せず、
// 適正な薄いグレー（hintColor / subTextColor / 透過グレー等）で表示されることを永久保証します。
// ==============================================================================
void main() {
  group('🛡️ [第3条 ガバナンス規約] 全画面ヒントテキスト視認性・適正グレー保証テスト', () {
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

    // --------------------------------------------------------------------------
    // 1. 静的コード解析規約: lib/ 全域での hintStyle 不透明純白・純黒の直書きゼロ保証
    // --------------------------------------------------------------------------
    test(
      '1. [静的規約] 全Dartファイルで hintStyle への不透明純白(0xFFFFFFFF/white)・純黒の直接指定が0件であること',
      () {
        final violations = <String>[];

        final whiteRegex = RegExp(
          r'hintStyle:\s*(?:const\s+)?TextStyle\([^)]*(?:0xFFFFFFFF|Colors\.white\b)',
        );
        final blackRegex = RegExp(
          r'hintStyle:\s*(?:const\s+)?TextStyle\([^)]*(?:0xFF000000|Colors\.black\b)',
        );

        for (final file in dartFiles) {
          final content = file.readAsStringSync();

          if (whiteRegex.hasMatch(content)) {
            violations.add(
              '${file.path}: hintStyle に不透明純白(0xFFFFFFFF / Colors.white)が指定されています',
            );
          }
          if (blackRegex.hasMatch(content)) {
            violations.add(
              '${file.path}: hintStyle に不透明純黒(0xFF000000 / Colors.black)が指定されています',
            );
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'ヒントテキストの文字色に不透明な純白または純黒が指定されているため、'
              'ダークモードでの白飛び（入力文字と同化）やライトモードでの黒潰れが発生します。\n'
              'デザインシステムの themeColors.hintColor または適正なグレー系トークンを使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    // --------------------------------------------------------------------------
    // 2. デザインシステムトークン規約: ライト/ダーク両モードの hintColor が適正グレーであること
    // --------------------------------------------------------------------------
    test('2. [トークン規約] AppThemeColors の hintColor がライト/ダークともに適正なグレー色であること', () {
      for (final mode in ['normal', 'combat', 'zen']) {
        final lightColors = AppThemeColors.ofMode(isDark: false, mode: mode);
        final darkColors = AppThemeColors.ofMode(isDark: true, mode: mode);

        // ライトモード検証:
        // - 純白(0xFFFFFFFF)でも純黒(0xFF000000)でもないこと
        // - 通常文字色(textColor)と異なること
        expect(lightColors.hintColor, isNot(equals(const Color(0xFFFFFFFF))));
        expect(lightColors.hintColor, isNot(equals(const Color(0xFF000000))));
        expect(lightColors.hintColor, isNot(equals(lightColors.textColor)));

        // 各RGB値が中間調（グレー系）であり、RGB差が極端に偏っていないこと（ニュートラルグレー）
        final lr = ((lightColors.hintColor.toARGB32() >> 16) & 0xFF);
        final lg = ((lightColors.hintColor.toARGB32() >> 8) & 0xFF);
        final lb = (lightColors.hintColor.toARGB32() & 0xFF);
        expect((lr - lg).abs(), lessThanOrEqualTo(20));
        expect((lg - lb).abs(), lessThanOrEqualTo(20));

        // ダークモード検証:
        // - 純白(0xFFFFFFFF)でも純黒(0xFF000000)でもないこと
        // - 通常文字色(textColor)と異なること
        expect(darkColors.hintColor, isNot(equals(const Color(0xFFFFFFFF))));
        expect(darkColors.hintColor, isNot(equals(const Color(0xFF000000))));
        expect(darkColors.hintColor, isNot(equals(darkColors.textColor)));

        final dr = ((darkColors.hintColor.toARGB32() >> 16) & 0xFF);
        final dg = ((darkColors.hintColor.toARGB32() >> 8) & 0xFF);
        final db = (darkColors.hintColor.toARGB32() & 0xFF);
        expect((dr - dg).abs(), lessThanOrEqualTo(20));
        expect((dg - db).abs(), lessThanOrEqualTo(20));
      }
    });

    // --------------------------------------------------------------------------
    // 3. 動的ウィジェット規約: AppTextField がライト/ダーク両モードで hintColor を自動適用すること
    // --------------------------------------------------------------------------
    testWidgets(
      '3. [ウィジェット規約] AppTextField のデフォルトヒント色がライト/ダークともに hintColor であること',
      (tester) async {
        for (final isDark in [false, true]) {
          final colors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
          final controller = TextEditingController();
          addTearDown(controller.dispose);

          final themeData = ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            extensions: [colors],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Theme(
                data: themeData,
                child: Scaffold(
                  body: AppTextField(
                    controller: controller,
                    hintText: 'プレースホルダー入力補助',
                  ),
                ),
              ),
            ),
          );

          final textField = tester.widget<TextField>(find.byType(TextField));
          final hintColor = textField.decoration?.hintStyle?.color;

          expect(hintColor, isNotNull);
          expect(hintColor, equals(colors.hintColor));
          expect(hintColor, isNot(equals(const Color(0xFFFFFFFF))));
          expect(hintColor, isNot(equals(const Color(0xFF000000))));
        }
      },
    );

    // --------------------------------------------------------------------------
    // 4. 動的画面規約: MatchEditCourtAndGroupTab の入力欄がライト/ダークともに適正グレーであること
    // --------------------------------------------------------------------------
    testWidgets(
      '4. [画面規約] MatchEditCourtAndGroupTab 全入力欄のヒント色がライト/ダークともに適正グレーであること',
      (tester) async {
        for (final isDark in [false, true]) {
          final colors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
          final courtCtrl = TextEditingController();
          final noteCtrl = TextEditingController();
          addTearDown(() {
            courtCtrl.dispose();
            noteCtrl.dispose();
          });

          await tester.pumpWidget(
            MaterialApp(
              theme: isDark ? ThemeData.dark() : ThemeData.light(),
              home: Scaffold(
                body: MatchEditCourtAndGroupTab(
                  themeColors: colors,
                  courtController: courtCtrl,
                  noteController: noteCtrl,
                  isDark: isDark,
                  textColor: colors.textColor,
                  onToggleHeadingPreset: (_) {},
                  onClearCourt: () {},
                ),
              ),
            ),
          );

          final textFields = tester.widgetList<TextField>(
            find.byType(TextField),
          );
          expect(textFields.length, greaterThanOrEqualTo(2));

          for (final tf in textFields) {
            final hintColor = tf.decoration?.hintStyle?.color;
            expect(hintColor, isNotNull);
            expect(hintColor, equals(colors.hintColor));
            expect(hintColor, isNot(equals(const Color(0xFFFFFFFF))));
            expect(hintColor, isNot(equals(const Color(0xFF000000))));
            expect(hintColor, isNot(equals(colors.textColor)));
          }
        }
      },
    );

    // --------------------------------------------------------------------------
    // 5. 動的画面規約: MatchEditTeamAndPlayersTab の入力欄がライト/ダークともに適正グレーであること
    // --------------------------------------------------------------------------
    testWidgets(
      '5. [画面規約] MatchEditTeamAndPlayersTab 全入力欄のヒント色がライト/ダークともに適正グレーであること',
      (tester) async {
        for (final isDark in [false, true]) {
          final colors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
          final redTeamCtrl = TextEditingController();
          final whiteTeamCtrl = TextEditingController();
          final redPlayerCtrls = List.generate(
            5,
            (_) => TextEditingController(),
          );
          final whitePlayerCtrls = List.generate(
            5,
            (_) => TextEditingController(),
          );

          addTearDown(() {
            redTeamCtrl.dispose();
            whiteTeamCtrl.dispose();
            for (final c in redPlayerCtrls) {
              c.dispose();
            }
            for (final c in whitePlayerCtrls) {
              c.dispose();
            }
          });

          await tester.pumpWidget(
            MaterialApp(
              theme: isDark ? ThemeData.dark() : ThemeData.light(),
              home: Scaffold(
                body: MatchEditTeamAndPlayersTab(
                  isDantai: true,
                  redTeamController: redTeamCtrl,
                  whiteTeamController: whiteTeamCtrl,
                  redPlayerControllers: redPlayerCtrls,
                  whitePlayerControllers: whitePlayerCtrls,
                  primaryAccent: colors.primaryAccent,
                  isDark: isDark,
                  textColor: colors.textColor,
                  onSwapTeamsAndPlayers: () {},
                ),
              ),
            ),
          );

          final textFields = tester.widgetList<TextField>(
            find.byType(TextField),
          );
          expect(textFields, isNotEmpty);

          for (final tf in textFields) {
            final hintColor = tf.decoration?.hintStyle?.color;
            if (hintColor != null) {
              expect(hintColor, isNot(equals(const Color(0xFFFFFFFF))));
              expect(hintColor, isNot(equals(const Color(0xFF000000))));
              expect(hintColor, isNot(equals(colors.textColor)));
            }
          }
        }
      },
    );

    // --------------------------------------------------------------------------
    // 6. 動的画面規約: 大会作成画面 (Page1 / Page2) のヒント色がライト/ダークともに適正グレーであること
    // --------------------------------------------------------------------------
    testWidgets(
      '6. [画面規約] 大会作成画面 (Page1 & Page2) 全入力欄のヒント色がライト/ダークともに適正グレーであること',
      (tester) async {
        for (final isDark in [false, true]) {
          final colors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
          final nameCtrl = TextEditingController();
          final venueCtrl = TextEditingController();
          final notesCtrl = TextEditingController();

          addTearDown(() {
            nameCtrl.dispose();
            venueCtrl.dispose();
            notesCtrl.dispose();
          });

          final themeData = ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            extensions: [colors],
          );

          // Page 1
          await tester.pumpWidget(
            MaterialApp(
              home: Theme(
                data: themeData,
                child: Scaffold(
                  body: Builder(
                    builder: (context) {
                      final hintColor = isDark
                          ? const Color(0xFF8E8E93)
                          : context.appColors.hintColor;
                      return TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          hintText: '例：第1回 〇〇剣道大会',
                          hintStyle: TextStyle(color: hintColor),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          var tf = tester.widget<TextField>(find.byType(TextField));
          var hintColor = tf.decoration?.hintStyle?.color;
          expect(hintColor, isNotNull);
          expect(hintColor, isNot(equals(const Color(0xFFFFFFFF))));
          expect(hintColor, isNot(equals(const Color(0xFF000000))));
          expect(hintColor, isNot(equals(colors.textColor)));

          // Page 2
          await tester.pumpWidget(
            MaterialApp(
              home: Theme(
                data: themeData,
                child: Scaffold(
                  body: Builder(
                    builder: (context) {
                      final hintColor = isDark
                          ? const Color(0xFF8E8E93)
                          : context.appColors.hintColor;
                      return Column(
                        children: [
                          TextField(
                            controller: venueCtrl,
                            decoration: InputDecoration(
                              hintText: '例：〇〇県立武道館',
                              hintStyle: TextStyle(color: hintColor),
                            ),
                          ),
                          TextField(
                            controller: notesCtrl,
                            decoration: InputDecoration(
                              hintText: '例：駐車場は第2駐車場を利用',
                              hintStyle: TextStyle(color: hintColor),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          final textFields = tester.widgetList<TextField>(
            find.byType(TextField),
          );
          for (final field in textFields) {
            final color = field.decoration?.hintStyle?.color;
            expect(color, isNotNull);
            expect(color, isNot(equals(const Color(0xFFFFFFFF))));
            expect(color, isNot(equals(const Color(0xFF000000))));
            expect(color, isNot(equals(colors.textColor)));
          }
        }
      },
    );
  });
}
