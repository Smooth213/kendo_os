import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import '../../../helpers/safe_pump_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kendo_os/features/tournament/presentation/operate/screens/program_management_screen.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/program_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockProgramRepository extends Mock implements ProgramRepository {}

class MockFilePicker extends FilePicker with MockPlatformInterfaceMixin {
  List<PlatformFile> filesToReturn = [
    PlatformFile(
      name: 'test_program.pdf',
      size: 500,
      bytes: Uint8List.fromList([0, 1, 2, 3]),
    ),
  ];

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int? compressionQuality,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return FilePickerResult(filesToReturn);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(FileType.any);
  });

  group('[Widget] ProgramManagementScreen - Upload Validation テスト', () {
    late MockProgramRepository mockProgramRepo;
    late MockFilePicker mockFilePicker;
    late SharedPreferences prefs;

    setUp(() async {
      mockProgramRepo = MockProgramRepository();
      mockFilePicker = MockFilePicker();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      // FilePickerのプラットフォームモックを設定
      FilePicker.platform = mockFilePicker;

      final dummyProgram = ProgramModel(
        id: 'p1',
        tournamentId: 't1',
        title: 'テスト進行表',
        fileUrl: 'https://example.com/dummy.pdf',
        fileType: 'pdf',
        pageCount: 1,
        createdAt: DateTime.now(),
      );

      // リポジトリメソッドのスタブ
      when(
        () => mockProgramRepo.watchPrograms(any()),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => mockProgramRepo.uploadProgram(
          tournamentId: any(named: 'tournamentId'),
          title: any(named: 'title'),
          file: any(named: 'file'),
          bytes: any(named: 'bytes'),
          fileType: any(named: 'fileType'),
          pageCount: any(named: 'pageCount'),
        ),
      ).thenAnswer((_) async => dummyProgram);
    });

    Widget createManagementWidget() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          programRepositoryProvider.overrideWithValue(mockProgramRepo),
          activeRoleProvider.overrideWith((ref) => Role.admin),
          permissionProvider.overrideWith(
            (ref) => const AppPermissions(isReadOnly: false),
          ),
        ],
        child: const MaterialApp(
          home: ProgramManagementScreen(tournamentId: 't1'),
        ),
      );
    }

    testWidgets('タイトル空欄バリデーションエラーのテスト: 空のまま決定すると警告が出てダイアログが閉じないこと', (
      tester,
    ) async {
      await tester.pumpWidget(createManagementWidget());
      await tester.safePumpAndSettle();

      // 1. 「プログラムを追加」FloatingActionButtonをタップ
      final addButton = find.byType(FloatingActionButton);
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.safePumpAndSettle();

      // 2. ボトムシートの「ファイルから選ぶ」をタップ
      final fileOption = find.text('ファイルから選ぶ (複数可)');
      expect(fileOption, findsOneWidget);
      await tester.tap(fileOption);
      await tester.safePumpAndSettle();

      // 3. ダイアログ「順番とタイトルの確認」が起動していることを検証
      expect(find.text('順番とタイトルの確認'), findsOneWidget);

      // 4. タイトル（プログラム名）入力欄が初期状態（空欄）であることを確認
      final titleField = find.byType(TextFormField);
      expect(titleField, findsOneWidget);
      final TextFormField textWidget = tester.widget(titleField);
      expect(textWidget.controller?.text ?? '', isEmpty);

      // 5. 空欄のまま「アップロード開始」をタップ
      final startButton = find.text('アップロード開始');
      expect(startButton, findsOneWidget);
      await tester.tap(startButton);
      await tester.safePumpAndSettle();

      // 6. ダイアログが閉じずに残り、赤文字のバリデーションエラーが表示されていることを検証
      expect(find.text('順番とタイトルの確認'), findsOneWidget);
      expect(find.text('プログラムのタイトルを入力してください'), findsOneWidget);

      // 7. タイトルを入力して再度「アップロード開始」をタップ
      await tester.enterText(titleField, '新大会進行表');
      await tester.safePumpAndSettle();
      await tester.tap(startButton);
      // アップロード処理が進むため、ロードダイアログ等のポップイベントを処理
      await tester.pump();
      await tester.safePumpAndSettle();

      // 8. 正常に入力されたため、ダイアログ「順番とタイトルの確認」が完全に閉じていることを検証
      expect(find.text('順番とタイトルの確認'), findsNothing);
      expect(find.text('プログラムのタイトルを入力してください'), findsNothing);
    });

    testWidgets('画像ファイルアップロード完了時に軽量化された削減サイズを含むトーストが表示されること', (tester) async {
      // 1. 圧縮対象となる画像データ（未圧縮BMPデータ: 約30KB -> JPEG圧縮で約2KBに軽量化）を生成し一時ファイルに保存
      final rawImage = img.Image(width: 100, height: 100);
      img.fill(rawImage, color: img.ColorRgb8(255, 0, 0));
      final rawBytes = Uint8List.fromList(img.encodeBmp(rawImage));

      final tempDir = Directory.systemTemp.createTempSync('kendo_test_');
      final tempFile = File('${tempDir.path}/large_poster.png');
      tempFile.writeAsBytesSync(rawBytes);

      mockFilePicker.filesToReturn = [
        PlatformFile(
          name: 'large_poster.png',
          path: tempFile.path,
          size: rawBytes.length,
          bytes: rawBytes,
        ),
      ];

      await tester.pumpWidget(createManagementWidget());
      await tester.safePumpAndSettle();

      // 2. 「プログラムを追加」FloatingActionButtonをタップ
      await tester.tap(find.byType(FloatingActionButton));
      await tester.safePumpAndSettle();

      // 3. ボトムシートの「写真ライブラリから選ぶ」をタップ
      await tester.tap(find.text('写真ライブラリから選ぶ (複数可)'));
      await tester.safePumpAndSettle();

      // 4. タイトルを入力して「アップロード開始」をタップ
      final titleField = find.byType(TextFormField);
      await tester.enterText(titleField, '大ポスター');
      await tester.safePumpAndSettle();

      await tester.tap(find.text('アップロード開始'));
      // compute (Isolate) の処理完了をリアルタイムで待機
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();
      await tester.safePumpAndSettle();

      // 5. トーストに「画像軽量化:」および「削減」という文言が含まれていることを検証
      expect(find.textContaining('画像軽量化:'), findsOneWidget);
      expect(find.textContaining('削減)'), findsOneWidget);

      // 一時ファイルのクリーンアップ
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });
  });
}
