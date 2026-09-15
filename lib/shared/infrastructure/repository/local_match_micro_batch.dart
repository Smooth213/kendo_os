import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

class LocalMatchMicroBatch {
  final Future<void> Function(MatchModel) saveMatch;
  final Future<void> Function(List<MatchModel>) saveMatchesBulk;
  Timer? _timer;
  final Map<String, MatchModel> _buffer = {};

  LocalMatchMicroBatch({
    required this.saveMatch,
    required this.saveMatchesBulk,
  });

  Future<void> saveMatchBatched(
    MatchModel match, {
    bool isCritical = false,
  }) async {
    _buffer[match.id] = match;
    if (isCritical || _isCriticalMatchChange(match)) {
      await flush();
      return;
    }
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1000), () async {
      await flush();
    });
  }

  bool _isCriticalMatchChange(MatchModel match) {
    return match.status == 'finished' ||
        match.status == 'paused' ||
        match.redScore > 0 ||
        match.whiteScore > 0 ||
        match.events.isNotEmpty;
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_buffer.isEmpty) return;
    final matches = _buffer.values.toList();
    _buffer.clear();
    if (matches.length == 1) {
      await saveMatch(matches.first);
    } else {
      await saveMatchesBulk(matches);
    }
    debugPrint('💾 [Adaptive Micro-Batch] ${matches.length} 件を一括フラッシュしました');
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    unawaited(flush());
  }
}
