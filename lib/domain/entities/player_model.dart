class PlayerModel {
  final String id;
  final String lastName; 
  final String firstName; 
  final String lastNameKana;  // ★ 追加：名字のよみがな
  final String firstNameKana; // ★ 追加：名前のよみがな
  final int grade; 
  final String organization; 
  final String gender; 
  final bool isBeginner;      // ★ 追加：初心者フラグ

  PlayerModel({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.lastNameKana,
    required this.firstNameKana,
    required this.grade,
    this.organization = '道上剣友会', 
    this.gender = '男子', 
    this.isBeginner = false,   // デフォルトは通常選手
  });

  String get name => '$lastName $firstName'.trim();
  String get nameKana => '$lastNameKana $firstNameKana'.trim(); // ★ よみがなフルネーム

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
    };
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
    );
  }

  PlayerModel copyWith({
    String? id,
    String? lastName,
    String? firstName,
    String? lastNameKana,
    String? firstNameKana,
    int? grade,
    String? organization,
    String? gender, 
    bool? isBeginner,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      lastNameKana: lastNameKana ?? this.lastNameKana,
      firstNameKana: firstNameKana ?? this.firstNameKana,
      grade: grade ?? this.grade,
      organization: organization ?? this.organization,
      gender: gender ?? this.gender, 
      isBeginner: isBeginner ?? this.isBeginner,
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