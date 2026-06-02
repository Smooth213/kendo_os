import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'system_time_source.dart';

/// Replay Determinism を保証するための時間の抽象化インターフェース
abstract class TimeSource {
  DateTime now();
}

/// アプリ全体で時間を取得するためのプロバイダ
final timeSourceProvider = Provider<TimeSource>((ref) => SystemTimeSource());
