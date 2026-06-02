import 'package:kendo_os/domain/match/match_model.dart';

class MatchBuilder {
  String _id = 'builder_match_default_001';
  String _matchType = '先鋒';
  String _redName = '紅組: 皿田選手';
  String _whiteName = '白組: 切込選手';
  String? _groupName = '一般の部_リーグ戦';
  String _status = 'waiting';
  double _matchTimeMinutes = 3.0;
  SyncState _syncState = SyncState.synced;

  MatchBuilder id(String id) {
    _id = id;
    return this;
  }

  MatchBuilder matchType(String type) {
    _matchType = type;
    return this;
  }

  MatchBuilder kachinuki() {
    _matchType = '勝ち抜き';
    return this;
  }

  MatchBuilder redName(String name) {
    _redName = name;
    return this;
  }

  MatchBuilder whiteName(String name) {
    _whiteName = name;
    return this;
  }

  MatchBuilder groupName(String? name) {
    _groupName = name;
    return this;
  }

  MatchBuilder individual() {
    _groupName = '個人戦の部';
    return this;
  }

  MatchBuilder approved() {
    _status = 'approved';
    return this;
  }

  MatchBuilder inProgress() {
    _status = 'in_progress';
    return this;
  }

  MatchBuilder matchTimeMinutes(double minutes) {
    _matchTimeMinutes = minutes;
    return this;
  }

  MatchBuilder localOnly() {
    _syncState = SyncState.localOnly;
    return this;
  }

  MatchModel build() {
    return MatchModel(
      id: _id,
      matchType: _matchType,
      redName: _redName,
      whiteName: _whiteName,
      groupName: _groupName,
      status: _status,
      matchTimeMinutes: _matchTimeMinutes,
      syncState: _syncState,
    );
  }
}
