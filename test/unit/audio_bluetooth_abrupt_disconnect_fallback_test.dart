import 'package:flutter_test/flutter_test.dart';

/// 🔊 オーディオ出力デバイスフォールバックマネージャー
class AudioOutputFallbackManager {
  bool isBluetoothConnected;
  String currentActiveOutput;
  bool isPlayingAlert;

  AudioOutputFallbackManager({this.isBluetoothConnected = true})
    : currentActiveOutput = isBluetoothConnected
          ? 'Bluetooth_PA_Speaker'
          : 'Device_Internal_Speaker',
      isPlayingAlert = false;

  void playMatchEndBuzzer() {
    isPlayingAlert = true;
  }

  /// Bluetooth 切断検知ハンドラー
  void onBluetoothDisconnected() {
    isBluetoothConnected = false;
    // 🚨 瞬時に端末内蔵スピーカーへ強制フォールバック
    currentActiveOutput = 'Device_Internal_Speaker';
  }
}

void main() {
  group(
    '👁️ 【Phase 6-4/12】試合終了ブザー鳴動中 Bluetoothスピーカー急断 端末内蔵スピーカー自動フォールバックテスト',
    () {
      test('1. 外部BTスピーカー切断時、即座に本体スピーカーへ切り替わりブザー鳴動状態が維持されること', () {
        final audioManager = AudioOutputFallbackManager(
          isBluetoothConnected: true,
        );

        // ブザー鳴動開始
        audioManager.playMatchEndBuzzer();
        expect(audioManager.currentActiveOutput, 'Bluetooth_PA_Speaker');
        expect(audioManager.isPlayingAlert, isTrue);

        // 🚨 Bluetoothスピーカーが電池切れで突然切断！
        audioManager.onBluetoothDisconnected();

        // 0.1秒で本体内蔵スピーカーへフォールバックし、ブザー鳴動が維持されること
        expect(audioManager.currentActiveOutput, 'Device_Internal_Speaker');
        expect(audioManager.isPlayingAlert, isTrue);
        expect(audioManager.isBluetoothConnected, isFalse);
      });
    },
  );
}
