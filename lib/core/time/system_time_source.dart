import 'time_source.dart';

/// プロダクション環境で使用する標準のシステム時間プロバイダ
class SystemTimeSource implements TimeSource {
  @override
  DateTime now() => DateTime.now().toUtc();
}
