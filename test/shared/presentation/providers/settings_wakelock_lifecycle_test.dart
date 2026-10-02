import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wakelock_plus_platform_interface/messages.g.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/application/services/sound_service.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockSoundService extends Mock implements SoundService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<bool> toggleCalls = [];

  setUpAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final codec = WakelockPlusApi.pigeonChannelCodec;

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
      (ByteData? message) async {
        if (message != null) {
          final decoded = codec.decodeMessage(message);
          if (decoded is List && decoded.isNotEmpty) {
            final arg = decoded[0];
            if (arg is ToggleMessage) {
              toggleCalls.add(arg.enable ?? false);
            }
          }
        }
        return codec.encodeMessage(<Object?>[null]);
      },
    );

    Future<ByteData?> isEnabledHandler(ByteData? message) async {
      return codec.encodeMessage(<Object?>[IsEnabledMessage(enabled: false)]);
    }

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.isEnabled',
      isEnabledHandler,
    );
  });

  late MockSharedPreferences mockPrefs;
  late MockSoundService mockSoundService;

  setUp(() {
    toggleCalls.clear();
    mockPrefs = MockSharedPreferences();
    mockSoundService = MockSoundService();

    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    when(() => mockSoundService.configureAudio(any())).thenAnswer((_) async {});
  });

  testWidgets('バックグラウンド遷移時にWakelockを無効化し、フォアグラウンド復帰時に再有効化されること', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        soundServiceProvider.overrideWithValue(mockSoundService),
      ],
    );
    addTearDown(container.dispose);

    // 初期化（sleepPrevent: true）
    final notifier = container.read(settingsProvider.notifier);
    await notifier.updateField(sleepPrevent: true);
    await tester.pumpAndSettle();

    toggleCalls.clear();

    // バックグラウンドへ移行 (resumed -> inactive -> hidden -> paused)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();

    expect(
      toggleCalls,
      contains(false),
      reason: 'バックグラウンド(paused)移行時にWakelockがdisableされること',
    );

    toggleCalls.clear();

    // フォアグラウンドへ復帰 (paused -> hidden -> inactive -> resumed)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(
      toggleCalls,
      contains(true),
      reason: 'フォアグラウンド(resumed)復帰時にWakelockが再有効化(enable)されること',
    );
  });

  testWidgets('sleepPrevent が false の場合、フォアグラウンド復帰時にもWakelockは有効化されないこと', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        soundServiceProvider.overrideWithValue(mockSoundService),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(settingsProvider.notifier);
    await notifier.updateField(sleepPrevent: false);
    await tester.pumpAndSettle();

    toggleCalls.clear();

    // バックグラウンドへ移行
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();

    toggleCalls.clear();

    // フォアグラウンドへ復帰
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(
      toggleCalls.contains(true),
      isFalse,
      reason: 'sleepPreventがfalseの場合、resumed復帰時でもenableされないこと',
    );
  });

  testWidgets('inactive または hidden 状態でもWakelockが解除されること', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        soundServiceProvider.overrideWithValue(mockSoundService),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(settingsProvider.notifier);
    await notifier.updateField(sleepPrevent: true);
    await tester.pumpAndSettle();

    toggleCalls.clear();

    // inactive状態
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(toggleCalls, contains(false));

    toggleCalls.clear();

    // hidden状態
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pumpAndSettle();
    expect(toggleCalls, contains(false));

    // 復帰
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  });
}
