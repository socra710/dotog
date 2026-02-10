/// 플레이어 상태 모델
class PlayerModel {
  const PlayerModel({
    required this.currentHp,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.luck,
    required this.runes,
    required this.level,
  });

  final int currentHp;
  final int maxHp;
  final int attack;
  final int defense;
  final int luck;
  final int runes;
  final int level;

  PlayerModel copyWith({
    int? currentHp,
    int? maxHp,
    int? attack,
    int? defense,
    int? luck,
    int? runes,
    int? level,
  }) {
    return PlayerModel(
      currentHp: currentHp ?? this.currentHp,
      maxHp: maxHp ?? this.maxHp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      luck: luck ?? this.luck,
      runes: runes ?? this.runes,
      level: level ?? this.level,
    );
  }

  /// 초기 플레이어 상태
  factory PlayerModel.initial() {
    return const PlayerModel(
      currentHp: 120,
      maxHp: 120,
      attack: 8,
      defense: 5,
      luck: 3,
      runes: 12,
      level: 1,
    );
  }
}
