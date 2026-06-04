import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/presentation/operate/providers/settings_provider.dart';
import 'package:kendo_os/application/services/sound_service.dart'; // ★ 追加
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/services.dart';

// モッククラスの定義
class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockSoundService extends Mock
    implements SoundService {} // ★ 追加：音響サービスのモック

void main() {
  // ★ 重要：プラットフォーム機能（Wakelock等）をテストで使うための初期化
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // ★ 追加: WakelockPlusのネイティブ通信(Pigeon)を生のバイナリレベルでモックする
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const codec = StandardMessageCodec();

    // 1. toggle (戻り値なし) の通信モック
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
      (ByteData? message) async {
        // Pigeonの void 成功レスポンスは [null] となるため手動エンコード
        return codec.encodeMessage(<Object?>[null]);
      },
    );

    // 2. isEnabled (戻り値あり) の通信モック
    Future<ByteData?> isEnabledHandler(ByteData? message) async {
      // Pigeonの戻り値(IsEnabledMessage) は [false] のようなリストになり、さらにレスポンスのリストで包まれる
      return codec.encodeMessage(<Object?>[
        <Object?>[false],
      ]);
    }

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.isEnabled',
      isEnabledHandler,
    );
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.enabled',
      isEnabledHandler,
    );
  });

  late ProviderContainer container;
  late MockSharedPreferences mockPrefs;
  late MockSoundService mockSoundService; // ★ 追加

  setUp(() {
    mockPrefs = MockSharedPreferences();
    mockSoundService = MockSoundService(); // ★ 追加

    // SharedPreferencesのスタブ設定
    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

    // ★ 追加：SoundServiceが呼び出されてもエラーにならないようにする
    when(
      () => mockSoundService.configureAudio(any()),
    ).thenAnswer((_) async => {});

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        // ★ 重要：音響サービスをモックに差し替えて、実機機能へのアクセスを遮断する
        soundServiceProvider.overrideWithValue(mockSoundService),
      ],
    );
  });

  group('SettingsNotifier 監査ログ発行テスト', () {
    test('セキュリティレベルを変更した際にステートが正しく更新されること', () async {
      final notifier = container.read(settingsProvider.notifier);

      // セキュリティレベルを 1 -> 3 に変更
      // この内部で _applyWakelock や soundService が呼ばれるが、
      // 差し替えているためエラーにならない
      await notifier.updateField(securityLevel: 3);

      final state = container.read(settingsProvider);
      expect(state.securityLevel, 3);

      // ログがコンソールに出力されていることは、出力結果の
      // 「📝 [AuditLog] セキュリティレベル変更: Lv.1 -> Lv.3」で確認できます
    });
  });
}
