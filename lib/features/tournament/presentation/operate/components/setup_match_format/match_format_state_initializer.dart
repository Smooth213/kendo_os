import 'package:flutter/material.dart';
import 'match_format_form_state.dart';
import 'match_format_setup_helper.dart';

/// 🥋 対戦フォーマット設定画面の初期化・設定復元ヘルパー
class MatchFormatStateInitializer {
  /// 直近使用した設定からフォームステートおよびコントローラーの初期値を復元
  static void initializeFromLastUsed({
    required MatchFormatFormState state,
    required Map<String, dynamic> last,
    required TextEditingController winPointController,
    required TextEditingController lossPointController,
    required TextEditingController drawPointController,
  }) {
    state.matchType = last['matchType'] ?? '団体戦';

    final (maj, min) = MatchFormatSetupHelper.parseCategoryToState(
      last['category'] ?? '小学生低学年の部',
    );
    state.selectedMajorCategory = maj;
    state.selectedMinorCategory = min;
    state.matchTime = last['matchTime'] ?? 3.0;
    state.isRunningTime = last['isRunningTime'] ?? false;
    state.hasExtension = last['hasExtension'] ?? false;
    state.hasHantei = last['hasHantei'] ?? true;
    state.isRenseikai = last['isRenseikai'] ?? false;
    state.kachinukiUnlimitedType = last['kachinukiUnlimitedType'] ?? '大将対大将';
    state.hasLeagueDaihyo = last['hasLeagueDaihyo'] ?? false;
    state.renseikaiType = last['renseikaiType'] ?? '一試合制';
    state.isDaihyoIpponShobu = last['isDaihyoIpponShobu'] ?? true;
    state.daihyoMatchTime =
        (last['daihyoMatchTime'] as num?)?.toDouble() ?? 0.0;
    state.daihyoHasExtension = last['daihyoHasExtension'] ?? true;
    state.daihyoEnchoTime =
        (last['daihyoEnchoTime'] as num?)?.toDouble() ?? 3.0;
    state.daihyoEnchoCount = last['daihyoEnchoCount'] ?? -2;
    state.daihyoHasHantei = last['daihyoHasHantei'] ?? false;
    state.isIpponShobu = last['isIpponShobu'] ?? false;
    state.ipponLimit = last['ipponLimit'] ?? 2;
    state.hansokuLimit = last['hansokuLimit'] ?? 2;

    winPointController.text = (last['winPoint'] ?? 0).toString();
    lossPointController.text = (last['lossPoint'] ?? 0).toString();
    drawPointController.text = (last['drawPoint'] ?? 0).toString();
  }
}
