import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';

export 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
export 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
export 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';

/// 🥋 KendoOS - 共通モックサービス定義
/// 各テストファイルでの重複クラス宣言を排除し、モック定義の保守性を向上させます。

class MockMatchApplicationService extends Mock
    implements MatchApplicationService {}

class MockMatchRepository extends Mock implements MatchRepository {}

class MockTournamentRepository extends Mock implements TournamentRepository {}

/// fallbackValue の登録（必要に応じてテスト開始時に呼び出し）
void registerCommonFallbackValues() {
  registerFallbackValue(
    const MatchModel(
      id: 'fallback_id',
      matchType: '先鋒',
      redName: '赤',
      whiteName: '白',
    ),
  );
}
