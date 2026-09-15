import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

class LocalMatchMicroBatch {
  final Future<void> Function(MatchModel) saveMatch;
  final Future<void> Function(List<MatchModel>) saveMatchesBulk;
  Timer? _timer;
  Future<void>? _flushInFlight;
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
    _timer = Timer(const Duration(milliseconds: 1000), _flushFromTimer);
  }

  Future<void> _flushFromTimer() async {
    try {
      await flush();
    } catch (error, stack) {
      debugPrint('⚠️ [Adaptive Micro-Batch] フラッシュ失敗: $error\n$stack');
    }
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
    final currentFlush = _flushInFlight;
    if (currentFlush != null) {
      await currentFlush;
      if (_buffer.isNotEmpty) await flush();
      return;
    }
    if (_buffer.isEmpty) return;
    final matches = _buffer.values.toList();
    final flushFuture = _saveBatch(matches);
    _flushInFlight = flushFuture;
    try {
      await flushFuture;
      for (final match in matches) {
        if (_buffer[match.id] == match) _buffer.remove(match.id);
      }
      debugPrint('💾 [Adaptive Micro-Batch] ${matches.length} 件を一括フラッシュしました');
    } finally {
      if (identical(_flushInFlight, flushFuture)) _flushInFlight = null;
    }
  }

  Future<void> _saveBatch(List<MatchModel> matches) {
    if (matches.length == 1) return saveMatch(matches.first);
    return saveMatchesBulk(matches);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    unawaited(flush());
  }
}
