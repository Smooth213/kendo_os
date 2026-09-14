import 'server_clock_offset_service.dart';
import 'time_source.dart';

/// プロダクション環境で使用する標準のシステム時間プロバイダ (Plan 3-② 時計ズレ補正対応)
class SystemTimeSource implements TimeSource {
  final ServerClockOffsetService? _offsetService;

  SystemTimeSource([this._offsetService]);

  @override
  DateTime now() {
    final offset = (_offsetService ?? ServerClockOffsetService.instance).offset;
    return DateTime.now().toUtc().add(offset);
  }
}
