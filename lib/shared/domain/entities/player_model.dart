class PlayerModel {
  static const String statusActive = 'active';
  static const String statusGraduated = 'graduated';

  final String id;

  /// ★ 新・同期空間統治キー：名簿データが所属する固有の道場ID
  final String organizationId;
  final String lastName;
  final String firstName;
  final String lastNameKana; // ★ 追加：名字のよみがな
  final String firstNameKana; // ★ 追加：名前のよみがな
  final int grade;
  final String organization;
  final String gender;
  final bool isBeginner; // ★ 追加：初心者フラグ

  /// 在籍ステータス（'active' = 現役 / 'graduated' = 卒業・OB/OG）
  final String status;

  /// 卒業年度（例：2027年3月卒 = 2026年度卒）
  final int? graduatedFiscalYear;

  /// 卒業アーカイブ処理日時
  final DateTime? graduatedAt;

  PlayerModel({
    required this.id,
    this.organizationId = 'default_org',
    required this.lastName,
    required this.firstName,
    required this.lastNameKana,
    required this.firstNameKana,
    required this.grade,
    this.organization = '',
    this.gender = '男子',
    this.isBeginner = false, // デフォルトは通常選手
    this.status = statusActive,
    this.graduatedFiscalYear,
    this.graduatedAt,
  });

  String get name => '$lastName $firstName'.trim();
  String get nameKana => '$lastNameKana $firstNameKana'.trim(); // ★ よみがなフルネーム
  bool get isGraduated => status == statusGraduated;
  bool get isActive => !isGraduated;

  String get graduationLabel =>
      graduatedFiscalYear != null ? '$graduatedFiscalYear年度卒' : 'OB/OG';

  String get gradeOrGraduationDisplay {
    if (!isGraduated) return gradeName;
    if (grade >= 17 || grade < 0) return 'OB/OG';
    return '$gradeName卒';
  }

  Map<String, dynamic> toMap() {
    return {
      'lastName': lastName,
      'firstName': firstName,
      'lastNameKana': lastNameKana,
      'firstNameKana': firstNameKana,
      'name': name,
      'grade': grade,
      'organization': organization,
      'gender': gender,
      'isBeginner': isBeginner,
      'status': status,
      if (graduatedFiscalYear != null)
        'graduatedFiscalYear': graduatedFiscalYear,
      if (graduatedAt != null) 'graduatedAt': graduatedAt!.toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw);
    try {
      final dynamic converted = (raw as dynamic).toDate();
      if (converted is DateTime) return converted;
    } catch (_) {}
    return null;
  }

  factory PlayerModel.fromMap(Map<String, dynamic> map, String documentId) {
    String lName = map['lastName'] ?? '';
    String fName = map['firstName'] ?? '';

    if (lName.isEmpty && fName.isEmpty && map['name'] != null) {
      final parts = map['name'].toString().split(RegExp(r'\s+'));
      if (parts.isNotEmpty) {
        lName = parts[0];
        if (parts.length > 1) fName = parts.sublist(1).join(' ');
      }
    }

    final rawStatus = map['status']?.toString().trim() ?? '';
    final normalizedStatus = rawStatus == statusGraduated
        ? statusGraduated
        : statusActive;

    return PlayerModel(
      id: documentId,
      lastName: lName,
      firstName: fName,
      lastNameKana: map['lastNameKana'] ?? '',
      firstNameKana: map['firstNameKana'] ?? '',
      grade: map['grade']?.toInt() ?? 99,
      organization: map['organization'] ?? '',
      gender: map['gender'] ?? '男子',
      isBeginner: map['isBeginner'] ?? false,
      status: normalizedStatus,
      graduatedFiscalYear: (map['graduatedFiscalYear'] as num?)?.toInt(),
      graduatedAt: _parseDateTime(map['graduatedAt']),
    );
  }

  PlayerModel copyWith({
    String? id,
    String? organizationId,
    String? lastName,
    String? firstName,
    String? lastNameKana,
    String? firstNameKana,
    int? grade,
    String? organization,
    String? gender,
    bool? isBeginner,
    String? status,
    int? graduatedFiscalYear,
    bool clearGraduatedFiscalYear = false,
    DateTime? graduatedAt,
    bool clearGraduatedAt = false,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      lastNameKana: lastNameKana ?? this.lastNameKana,
      firstNameKana: firstNameKana ?? this.firstNameKana,
      grade: grade ?? this.grade,
      organization: organization ?? this.organization,
      gender: gender ?? this.gender,
      isBeginner: isBeginner ?? this.isBeginner,
      status: status ?? this.status,
      graduatedFiscalYear: clearGraduatedFiscalYear
          ? null
          : (graduatedFiscalYear ?? this.graduatedFiscalYear),
      graduatedAt: clearGraduatedAt ? null : (graduatedAt ?? this.graduatedAt),
    );
  }

  String get gradeName {
    // 画面表示は数値に基づく（初心者はバッジで出すのでここは通常の学年表示）
    if (grade == 0) return '未就学';
    if (grade >= 1 && grade <= 6) return '小学$grade年';
    if (grade >= 7 && grade <= 9) return '中学${grade - 6}年';
    if (grade >= 10 && grade <= 12) return '高校${grade - 9}年';
    if (grade >= 13 && grade <= 16) return '大学${grade - 12}年';
    return '一般';
  }
}
