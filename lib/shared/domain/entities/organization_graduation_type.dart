import 'package:kendo_os/shared/domain/entities/player_model.dart';

/// 組織（道場・部活）の卒業ライン種別
enum OrganizationGraduationType {
  elementary(
    id: 'elementary',
    label: '小学生のみ',
    description: '小学6年で卒業（OB/OGへ）',
    graduationGrade: 6,
  ),
  juniorDojo(
    id: 'junior_dojo',
    label: '少年道場（中3まで）',
    description: '中学3年で卒業（OB/OGへ）',
    graduationGrade: 9,
  ),
  juniorHighClub(
    id: 'junior_high_club',
    label: '中学校部活',
    description: '中学3年で卒業（OB/OGへ）',
    graduationGrade: 9,
  ),
  highSchoolClub(
    id: 'high_school_club',
    label: '高校部活',
    description: '高校3年で卒業（OB/OGへ）',
    graduationGrade: 12,
  ),
  universityClub(
    id: 'university_club',
    label: '大学部活',
    description: '大学4年で卒業（OB/OGへ）',
    graduationGrade: 16,
  ),
  allAges(
    id: 'all_ages',
    label: '一貫道場・全年齢',
    description: '大学4年後は一般へ進級',
    graduationGrade: null,
  );

  final String id;
  final String label;
  final String description;

  /// 卒業対象となる学年コード（null の場合は卒業アーカイブなし）
  final int? graduationGrade;

  const OrganizationGraduationType({
    required this.id,
    required this.label,
    required this.description,
    required this.graduationGrade,
  });

  /// ID文字列から卒業区分を復元する（未知・未設定時は少年道場をデフォルトとする）
  static OrganizationGraduationType fromId(String? id) {
    if (id == null || id.isEmpty) return OrganizationGraduationType.juniorDojo;
    for (final value in values) {
      if (value.id == id) return value;
    }
    return OrganizationGraduationType.juniorDojo;
  }

  /// 指定選手がこの組織種別における卒業候補かどうかを判定する
  bool isGraduationCandidate(PlayerModel player) {
    if (player.isGraduated) return false;
    final gradGrade = graduationGrade;
    return gradGrade != null && player.grade == gradGrade;
  }

  /// 1人の選手に対する新年度進級結果を計算する
  PlayerPromotionOutcome evaluatePromotion(
    PlayerModel player, {
    required bool retainInActive,
    required int graduationFiscalYear,
    required DateTime now,
  }) {
    if (player.isGraduated) {
      return PlayerPromotionOutcome.unchanged(player);
    }
    // 一般（grade == 99 等）や特殊学年（grade < 0）は維持
    if (player.grade < 0 || player.grade >= 17) {
      return PlayerPromotionOutcome.unchanged(player);
    }

    if (graduationGrade != null && player.grade == graduationGrade) {
      if (retainInActive) {
        final nextGrade = player.grade >= 16 ? 99 : player.grade + 1;
        return PlayerPromotionOutcome.promoted(
          player.copyWith(grade: nextGrade),
        );
      }
      return PlayerPromotionOutcome.graduated(
        player.copyWith(
          status: PlayerModel.statusGraduated,
          graduatedFiscalYear: graduationFiscalYear,
          graduatedAt: now,
        ),
      );
    }

    if (player.grade < 16) {
      return PlayerPromotionOutcome.promoted(
        player.copyWith(grade: player.grade + 1),
      );
    }

    // grade == 16 かつ graduationGrade != 16（一貫道場など）の場合は一般へ進級
    return PlayerPromotionOutcome.promoted(player.copyWith(grade: 99));
  }
}

/// 進級判定の種類
enum PlayerPromotionKind { promoted, graduated, unchanged }

/// 1名分の進級結果
class PlayerPromotionOutcome {
  final PlayerModel updatedPlayer;
  final PlayerPromotionKind kind;

  const PlayerPromotionOutcome._({
    required this.updatedPlayer,
    required this.kind,
  });

  factory PlayerPromotionOutcome.promoted(PlayerModel player) =>
      PlayerPromotionOutcome._(
        updatedPlayer: player,
        kind: PlayerPromotionKind.promoted,
      );

  factory PlayerPromotionOutcome.graduated(PlayerModel player) =>
      PlayerPromotionOutcome._(
        updatedPlayer: player,
        kind: PlayerPromotionKind.graduated,
      );

  factory PlayerPromotionOutcome.unchanged(PlayerModel player) =>
      PlayerPromotionOutcome._(
        updatedPlayer: player,
        kind: PlayerPromotionKind.unchanged,
      );
}

/// 進級・卒業年度の計算ヘルパー（日本の学校年度基準）
class FiscalYearHelper {
  /// 進級対象となる新年度を返す（3月は次年度に向けた前倒し進級とみなす）
  /// 例：2027年3月・2027年4月 いずれも 2027 を返す
  static int targetPromotionFiscalYear(DateTime date) {
    return date.month >= 3 ? date.year : date.year - 1;
  }

  /// 卒業生に付与するデフォルトの卒業年度を返す
  /// 例：2027年3月卒・2027年4月進級実行時は 2026（2026年度卒）を返す
  static int defaultGraduationFiscalYear(DateTime date) {
    return targetPromotionFiscalYear(date) - 1;
  }
}

/// 組織ドキュメントから取得する進級・卒業設定情報
class OrganizationPromotionConfig {
  final String name;
  final OrganizationGraduationType graduationType;
  final int? lastPromotedFiscalYear;
  final DateTime? lastPromotedAt;

  const OrganizationPromotionConfig({
    this.name = '',
    this.graduationType = OrganizationGraduationType.juniorDojo,
    this.lastPromotedFiscalYear,
    this.lastPromotedAt,
  });

  factory OrganizationPromotionConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const OrganizationPromotionConfig();
    DateTime? promotedAt;
    final rawAt = data['lastPromotedAt'];
    if (rawAt is DateTime) {
      promotedAt = rawAt;
    } else if (rawAt is String) {
      promotedAt = DateTime.tryParse(rawAt);
    } else if (rawAt is int) {
      promotedAt = DateTime.fromMillisecondsSinceEpoch(rawAt);
    } else if (rawAt != null) {
      try {
        final dynamic converted = (rawAt as dynamic).toDate();
        if (converted is DateTime) promotedAt = converted;
      } catch (_) {}
    }

    return OrganizationPromotionConfig(
      name: data['name'] as String? ?? '',
      graduationType: OrganizationGraduationType.fromId(
        data['graduationType'] as String?,
      ),
      lastPromotedFiscalYear: (data['lastPromotedFiscalYear'] as num?)?.toInt(),
      lastPromotedAt: promotedAt,
    );
  }

  bool isAlreadyPromotedFor(int fiscalYear) =>
      lastPromotedFiscalYear == fiscalYear;
}
