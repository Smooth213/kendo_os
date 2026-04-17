// 1. 保管したい荷物（6点セット＋錬成会情報）をまとめた箱の設計図
class MatchRule {
  final List<String> positions;
  final int matchTimeMinutes; 
  final bool isRunningTime;
  final bool isLeague;
  final String category;
  final String note;
  final bool isRenseikai; 
  final List<String> baseOrder; 
  final String teamName; 
  final bool isKachinuki; 
  final String kachinukiUnlimitedType; 
  final bool hasLeagueDaihyo;          
  final String renseikaiType;          
  final int overallTimeMinutes; 
  final bool isDaihyoIpponShobu;

  MatchRule({
    this.positions = const ['選手'],
    this.matchTimeMinutes = 3,
    this.isRunningTime = false,
    this.isLeague = false,
    this.category = '',
    this.note = '',
    this.isRenseikai = false, 
    this.baseOrder = const [], 
    this.teamName = '', 
    this.isKachinuki = false, 
    this.kachinukiUnlimitedType = '大将対大将',
    this.hasLeagueDaihyo = false,
    this.renseikaiType = '一試合制',
    this.overallTimeMinutes = 30,
    this.isDaihyoIpponShobu = true,
  });

  // 中身の一部だけを書き換えるための便利機能
  MatchRule copyWith({
    List<String>? positions,
    int? matchTimeMinutes,
    bool? isRunningTime,
    bool? isLeague,
    String? category,
    String? note,
    bool? isRenseikai, 
    List<String>? baseOrder, 
    String? teamName, 
    bool? isKachinuki, 
    String? kachinukiUnlimitedType, 
    bool? hasLeagueDaihyo,          
    String? renseikaiType,          
    int? overallTimeMinutes,
    bool? isDaihyoIpponShobu, 
  }) {
    return MatchRule(
      positions: positions ?? this.positions,
      matchTimeMinutes: matchTimeMinutes ?? this.matchTimeMinutes,
      isRunningTime: isRunningTime ?? this.isRunningTime,
      isLeague: isLeague ?? this.isLeague,
      category: category ?? this.category,
      note: note ?? this.note,
      isRenseikai: isRenseikai ?? this.isRenseikai,
      baseOrder: baseOrder ?? this.baseOrder,
      teamName: teamName ?? this.teamName,
      isKachinuki: isKachinuki ?? this.isKachinuki,
      kachinukiUnlimitedType: kachinukiUnlimitedType ?? this.kachinukiUnlimitedType,
      hasLeagueDaihyo: hasLeagueDaihyo ?? this.hasLeagueDaihyo,
      renseikaiType: renseikaiType ?? this.renseikaiType,
      overallTimeMinutes: overallTimeMinutes ?? this.overallTimeMinutes,
      isDaihyoIpponShobu: isDaihyoIpponShobu ?? this.isDaihyoIpponShobu,
    );
  }
}