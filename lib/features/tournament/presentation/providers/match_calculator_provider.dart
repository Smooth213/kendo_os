import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_allocation_engine.dart';

/// 🥋 計算機状態
@immutable
class MatchCalculatorState {
  final CalculatorSettings settings;
  final AllocationResult result;

  const MatchCalculatorState({required this.settings, required this.result});

  MatchCalculatorState copyWith({
    CalculatorSettings? settings,
    AllocationResult? result,
  }) {
    return MatchCalculatorState(
      settings: settings ?? this.settings,
      result: result ?? this.result,
    );
  }
}

/// 🥋 試合数・コート配分計算Notifier
class MatchCalculatorNotifier extends StateNotifier<MatchCalculatorState> {
  MatchCalculatorNotifier() : super(_initialState());

  static MatchCalculatorState _initialState() {
    const defaultSettings = CalculatorSettings();
    final result = MatchAllocationEngine.calculate(defaultSettings);
    return MatchCalculatorState(settings: defaultSettings, result: result);
  }

  void updateFormat(MatchFormatType format) {
    _updateSettings(state.settings.copyWith(format: format));
  }

  void updatePattern(AllocationPattern pattern) {
    _updateSettings(state.settings.copyWith(pattern: pattern));
  }

  void updateParticipantCount(int count) {
    if (count < 2) return;
    _updateSettings(
      state.settings.copyWith(
        participantCount: count,
        customLeagueParticipants: null, // 全体人数変更時は均等配分にリセット
      ),
    );
  }

  void updateLeagueCount(int count) {
    if (count < 1) return;
    _updateSettings(
      state.settings.copyWith(
        leagueCount: count,
        customLeagueParticipants: null,
      ),
    );
  }

  /// リーグごとの人数を個別に更新 (例: Aリーグ=4人, Bリーグ=6人)
  void updateLeagueParticipantCount(int leagueIndex, int count) {
    if (count < 2) return;
    final currentCounts = List<int>.from(
      state.settings.leagueParticipantCounts,
    );
    if (leagueIndex < 0 || leagueIndex >= currentCounts.length) return;

    currentCounts[leagueIndex] = count;
    final total = currentCounts.fold<int>(0, (sum, c) => sum + c);

    _updateSettings(
      state.settings.copyWith(
        participantCount: total,
        customLeagueParticipants: currentCounts,
      ),
    );
  }

  /// リーグ人数を均等にリセット
  void resetLeagueParticipantsToEqual() {
    _updateSettings(state.settings.copyWith(customLeagueParticipants: null));
  }

  void updateCourtCount(int count) {
    if (count < 1) return;
    _updateSettings(state.settings.copyWith(courtCount: count));
  }

  void updateThirdPlaceMatch(bool has) {
    _updateSettings(state.settings.copyWith(hasThirdPlaceMatch: has));
  }

  void updateAdvancingCount(int count) {
    if (count < 1) return;
    _updateSettings(state.settings.copyWith(advancingCountPerLeague: count));
  }

  void updateMatchDuration(double minutes) {
    if (minutes < 0.5) return;
    _updateSettings(state.settings.copyWith(matchDurationMinutes: minutes));
  }

  /// 試合時間を「全リーグ一括」か「リーグ別に個別設定」か切り替える
  void setUseCustomLeagueMatchDurations(bool enabled) {
    if (enabled) {
      final leagueCount = state.settings.leagueCount;
      final currentDurations =
          state.settings.customLeagueMatchDurations != null &&
              state.settings.customLeagueMatchDurations!.length == leagueCount
          ? state.settings.customLeagueMatchDurations!
          : List<double>.filled(
              leagueCount,
              state.settings.matchDurationMinutes,
            );
      _updateSettings(
        state.settings.copyWith(
          useCustomLeagueMatchDurations: true,
          customLeagueMatchDurations: currentDurations,
        ),
      );
    } else {
      _updateSettings(
        state.settings.copyWith(useCustomLeagueMatchDurations: false),
      );
    }
  }

  /// リーグごとの試合時間を個別に更新 (例: Aリーグ=2.0分, Bリーグ=2.5分, Cリーグ=3.0分)
  void updateLeagueMatchDuration(int leagueIndex, double minutes) {
    if (minutes < 0.5) return;
    final leagueCount = state.settings.leagueCount;
    final currentDurations =
        state.settings.customLeagueMatchDurations != null &&
            state.settings.customLeagueMatchDurations!.length == leagueCount
        ? List<double>.from(state.settings.customLeagueMatchDurations!)
        : List<double>.filled(leagueCount, state.settings.matchDurationMinutes);

    if (leagueIndex < 0 || leagueIndex >= currentDurations.length) return;
    currentDurations[leagueIndex] = minutes;

    _updateSettings(
      state.settings.copyWith(
        useCustomLeagueMatchDurations: true,
        customLeagueMatchDurations: currentDurations,
      ),
    );
  }

  /// 決勝トーナメントの試合時間を更新
  void updateTournamentMatchDuration(double minutes) {
    if (minutes < 0.5) return;
    _updateSettings(
      state.settings.copyWith(
        useCustomLeagueMatchDurations: true,
        customTournamentMatchDuration: minutes,
      ),
    );
  }

  /// リーグ試合時間を共通デフォルトにリセット
  void resetLeagueMatchDurationsToDefault() {
    _updateSettings(
      state.settings.copyWith(
        useCustomLeagueMatchDurations: false,
        customLeagueMatchDurations: null,
        customTournamentMatchDuration: null,
      ),
    );
  }

  void updateIntervalDuration(double minutes) {
    if (minutes < 0.0) return;
    _updateSettings(state.settings.copyWith(intervalDurationMinutes: minutes));
  }

  void updateStartTime(TimeOfDay time) {
    _updateSettings(state.settings.copyWith(startTime: time));
  }

  void resetToDefaults() {
    _updateSettings(const CalculatorSettings());
  }

  String getClipboardSummary() {
    return MatchAllocationEngine.formatSummaryForClipboard(
      state.settings,
      state.result,
    );
  }

  void _updateSettings(CalculatorSettings newSettings) {
    final result = MatchAllocationEngine.calculate(newSettings);
    state = MatchCalculatorState(settings: newSettings, result: result);
  }
}

final matchCalculatorProvider =
    StateNotifierProvider<MatchCalculatorNotifier, MatchCalculatorState>((ref) {
      return MatchCalculatorNotifier();
    });
