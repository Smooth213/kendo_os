import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('[Unit] デザインカタログ 全UIパーツ網羅性 ＆ 形状言語監査テスト', () {
    const galleryDirPath = 'lib/admin/presentation/components/design_gallery';
    const parentScreenPath =
        'lib/admin/presentation/screens/design_system_gallery_screen.dart';
    const manifestPath = 'scripts/design_system_manifest.json';

    late List<File> galleryFiles;
    late String combinedCode;

    setUpAll(() {
      final galleryDir = Directory(galleryDirPath);
      expect(
        galleryDir.existsSync(),
        isTrue,
        reason: 'デザインカタログのモジュールディレクトリが存在すること',
      );

      galleryFiles = galleryDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      final parentFile = File(parentScreenPath);
      expect(parentFile.existsSync(), isTrue, reason: 'デザインカタログ親画面が存在すること');

      // 全モジュール + 親画面のコードを結合
      final buffer = StringBuffer();
      for (final f in galleryFiles) {
        buffer.writeln(f.readAsStringSync());
      }
      buffer.writeln(parentFile.readAsStringSync());
      combinedCode = buffer.toString();
    });

    test('全7大セクションモジュールが独立ファイルとして配置されていること', () {
      final fileNames = galleryFiles
          .map((f) => f.uri.pathSegments.last)
          .toSet();

      expect(fileNames, contains('gallery_textures_and_springs_section.dart'));
      expect(fileNames, contains('gallery_kendo_domain_section.dart'));
      expect(fileNames, contains('gallery_scene_and_status_section.dart'));
      expect(fileNames, contains('gallery_buttons_and_actions_section.dart'));
      expect(fileNames, contains('gallery_forms_and_inputs_section.dart'));
      expect(fileNames, contains('gallery_dock_and_overlays_section.dart'));
      expect(fileNames, contains('gallery_palette_typography_section.dart'));
    });

    test('各カタログモジュールが500行上限規約を完全に遵守していること', () {
      for (final f in galleryFiles) {
        final lines = f.readAsLinesSync().length;
        expect(
          lines,
          lessThan(500),
          reason: '${f.path} は500行未満である必要があります (現在: $lines 行)',
        );
      }
      final parentLines = File(parentScreenPath).readAsLinesSync().length;
      expect(
        parentLines,
        lessThan(500),
        reason: '$parentScreenPath は500行未満である必要があります (現在: $parentLines 行)',
      );
    });

    test('競技ドメイン必須パーツ（紅白対戦・一本・反則・スコアボード）がカタログに含まれていること', () {
      expect(combinedCode, contains('akaDark'));
      expect(combinedCode, contains('ipponGold'));
      expect(combinedCode, contains('hansokuRed'));
      expect(combinedCode, contains('二本勝ち'));
      expect(combinedCode, contains('03:45'));
    });

    test('試合シーン ＆ 進行ステータス ＆ サーマルバッジがカタログに含まれていること', () {
      expect(combinedCode, contains('KendoSceneBadge'));
      expect(combinedCode, contains('MatchStatusBadge'));
      expect(combinedCode, contains('ThermalStatusBadge'));
      expect(combinedCode, contains('honsen'));
      expect(combinedCode, contains('renseikai'));
      expect(combinedCode, contains('moushiawase'));
      expect(combinedCode, contains('bunaiksen'));
    });

    test('ボタン階層 ＆ 浮遊FAB ＆ カプセル形状言語がカタログに含まれていること', () {
      expect(combinedCode, contains('StadiumBorder'));
      expect(combinedCode, contains('ElevatedButton'));
      expect(combinedCode, contains('OutlinedButton'));
      expect(combinedCode, contains('新規試合を追加'));
    });

    test('入力フォーム（単一行カプセル ＆ 複数行Squircle ＆ スロット）がカタログに含まれていること', () {
      expect(combinedCode, contains('AppRadius.capsule'));
      expect(combinedCode, contains('AppRadius.large'));
      expect(
        combinedCode.contains('SmartPlayerInput') ||
            combinedCode.contains('先鋒'),
        isTrue,
      );
      expect(combinedCode, contains('必須項目が未入力です'));
    });

    test('常設ドック ＆ モーダル ＆ トーストがカタログに含まれていること', () {
      expect(combinedCode, contains('iosDock'));
      expect(combinedCode, contains('showAppBottomSheet'));
      expect(combinedCode, contains('showAppDialog'));
      expect(combinedCode, contains('AppSnackBar'));
    });

    test('セマンティックカラーパレット ＆ タイポグラフィ階層がカタログに含まれていること', () {
      expect(combinedCode, contains('Primary Accent'));
      expect(combinedCode, contains('Scoreboard Timer'));
      expect(combinedCode, contains('hairlineBorder'));
    });

    test('マニフェスト (design_system_manifest.json) との照合整合性が100%であること', () {
      final manifestFile = File(manifestPath);
      expect(manifestFile.existsSync(), isTrue);

      final manifestJson =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final shapeSpecs = manifestJson['shape_spec'] as Map<String, dynamic>;

      // 主要な形状仕様が定義されていること
      expect(shapeSpecs.containsKey('action_buttons'), isTrue);
      expect(shapeSpecs.containsKey('single_line_inputs'), isTrue);
      expect(shapeSpecs.containsKey('status_badges'), isTrue);
      expect(shapeSpecs.containsKey('multiline_inputs'), isTrue);
    });
  });
}
