import 'time_source.dart';

/// テストおよびReplay検証で使用する時間固定プロバイダ
class FixedTimeSource implements TimeSource {
  final DateTime _fixedTime;

  FixedTimeSource(this._fixedTime);

  @override
  DateTime now() => _fixedTime;
}
