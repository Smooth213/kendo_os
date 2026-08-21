import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';

enum CommandType {
  addScore,
  undoLastEvent,
  approveMatch,
  rewindTo,
  updateMatch,
}

enum CommandStatus { pending, done, failed }

/// 操作の意図をパッキングするデータクラス
class MatchCommandModel {
  final String id;
  final CommandType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  CommandStatus status;

  MatchCommandModel({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.status = CommandStatus.pending,
  });
}

final isMatchCommandProcessingProvider = StateProvider<bool>((ref) => false);
final matchCommandErrorProvider = StateProvider<String?>((ref) => null);

class DeadLetterQueueNotifier extends Notifier<List<MatchCommandModel>> {
  @override
  List<MatchCommandModel> build() => [];

  void addErrorCommand(MatchCommandModel cmd) {
    state = [...state, cmd];
  }

  Future<void> retryCommand(MatchCommandModel cmd) async {
    final queue = ref.read(matchCommandQueueProvider);
    state = state.where((c) => c.id != cmd.id).toList();

    final newCmd = MatchCommandModel(
      id: cmd.id,
      type: cmd.type,
      payload: cmd.payload,
      createdAt: cmd.createdAt,
      status: CommandStatus.pending,
    );
    await queue.enqueue(newCmd);
  }

  void discardCommand(MatchCommandModel cmd) {
    state = state.where((c) => c.id != cmd.id).toList();
  }
}

final deadLetterQueueProvider =
    NotifierProvider<DeadLetterQueueNotifier, List<MatchCommandModel>>(() {
      return DeadLetterQueueNotifier();
    });

class MatchCommandQueue {
  final Ref ref;
  final List<MatchCommandModel> _queue = [];
  final Map<String, int> _errorCounts = {};
  bool _isProcessing = false;

  MatchCommandQueue(this.ref);

  Future<void> init() async {
    final localRepo = ref.read(localMatchRepositoryProvider);
    final pendingCommands = await localRepo.getPendingCommands();
    if (pendingCommands.isNotEmpty) {
      _queue.addAll(pendingCommands);
      _process();
    }
  }

  Future<void> enqueue(MatchCommandModel cmd) async {
    _queue.add(cmd);
    _process();
  }

  Future<void> _process() async {
    if (_isProcessing) return;
    _isProcessing = true;
    ref.read(isMatchCommandProcessingProvider.notifier).state = true;

    final localRepo = ref.read(localMatchRepositoryProvider);

    try {
      while (_queue.isNotEmpty) {
        final cmd = _queue.first;
        await localRepo.savePendingCommand(cmd);

        try {
          await _executeCommand(cmd);
          await localRepo.deleteCommand(cmd.id);
          _queue.removeAt(0);
          _errorCounts.remove(cmd.id);
        } catch (e) {
          _errorCounts[cmd.id] = (_errorCounts[cmd.id] ?? 0) + 1;
          debugPrint('🔥 [CommandQueue] 処理失敗 (${_errorCounts[cmd.id]}回目): $e');

          final errStr = e.toString();
          if (errStr.contains('DomainException') ||
              errStr.contains('取り消すイベントがありません') ||
              errStr.contains('既に規定本数に達しています')) {
            debugPrint('🛡️ [CommandQueue] ドメインルールの制約によりコマンドを破棄します: $errStr');
            _queue.removeAt(0);
            await localRepo.deleteCommand(cmd.id);
            _errorCounts.remove(cmd.id);
            continue;
          }

          if (errStr.contains('ConcurrencyException') &&
              _errorCounts[cmd.id]! < 5) {
            await Future.delayed(const Duration(milliseconds: 200));
            continue;
          }

          if (_errorCounts[cmd.id]! >= 3) {
            debugPrint('🚨 [CommandQueue] 失敗上限到達。デッドレターキューへ退避: ${cmd.id}');
            ref.read(deadLetterQueueProvider.notifier).addErrorCommand(cmd);
            _queue.removeAt(0);
            await localRepo.deleteCommand(cmd.id);
            ref.read(matchCommandErrorProvider.notifier).state =
                '一時的な通信エラーにより、データ送信を保留しました。電波状況を確認して再送してください。';
          } else {
            break;
          }
        }
      }
    } finally {
      _isProcessing = false;
      ref.read(isMatchCommandProcessingProvider.notifier).state = false;
      ref.read(syncEngineProvider).syncNow();
    }
  }

  Future<void> _executeCommand(MatchCommandModel cmd) async {
    final appService = ref.read(matchApplicationServiceProvider);
    final matchId = cmd.payload['matchId'] as String;

    switch (cmd.type) {
      case CommandType.addScore:
        final sideStr = cmd.payload['side'] as String;
        final typeStr = cmd.payload['type'] as String;
        final side = Side.values.firstWhere(
          (e) => e.name == sideStr,
          orElse: () => Side.none,
        );
        final type = PointType.values.firstWhere(
          (e) => e.name == typeStr,
          orElse: () => PointType.men,
        );

        if (type == PointType.undo) {
          await appService.undo(matchId);
        } else {
          await appService.addIppon(matchId, side, type);
        }
        break;
      case CommandType.undoLastEvent:
        await appService.undo(matchId);
        break;
      case CommandType.approveMatch:
        await appService.approveMatch(matchId);
        break;
      case CommandType.rewindTo:
        final version = cmd.payload['version'] as int;
        await appService.rewindTo(matchId, version);
        break;
      case CommandType.updateMatch:
        break;
    }
  }
}

final matchCommandQueueProvider = Provider<MatchCommandQueue>((ref) {
  final queue = MatchCommandQueue(ref);
  queue.init();
  return queue;
});
