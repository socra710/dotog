import 'codex_bonus_model.dart';

/// 플레이어 상태 모델
class PlayerModel {
  const PlayerModel({
    required this.nickname,
    required this.currentHp,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.luck,
    required this.tokens,
    required this.runes,
    required this.level,
    required this.currentExp,
  });

  final String nickname;
  final int currentHp;
  final int maxHp;
  final int attack;
  final int defense;
  final int luck;

  /// 토큰: 던전 진입 비용으로 사용
  final int tokens;

  /// 룬: 코덱스 보너스 활성화/업그레이드에 사용
  final int runes;
  final int level;

  /// 현재 경험치
  final int currentExp;

  /// 다음 레벨까지 필요한 경험치
  int get expToNext => _expToNextForLevel(level);

  /// 경험치 진행률 (0.0 ~ 1.0)
  double get expProgress {
    final requiredExp = expToNext;
    if (requiredExp <= 0) return 0;
    return currentExp / requiredExp;
  }

  /// 레벨 보너스 스탯 (기본 스탯과 별개)
  int get levelAttackBonus => (level - 1).clamp(0, 999);
  int get levelDefenseBonus => ((level - 1) ~/ 2).clamp(0, 999);
  int get levelHpBonus => ((level - 1) * 5).clamp(0, 9999);
  int get levelLuckBonus => ((level - 1) ~/ 3).clamp(0, 999);

  /// 전투 계산용 총합 스탯
  int get totalAttack => attack + levelAttackBonus;
  int get totalDefense => defense + levelDefenseBonus;
  int get totalMaxHp => maxHp + levelHpBonus;
  int get totalLuck => luck + levelLuckBonus;

  PlayerModel copyWith({
    String? nickname,
    int? currentHp,
    int? maxHp,
    int? attack,
    int? defense,
    int? luck,
    int? tokens,
    int? runes,
    int? level,
    int? currentExp,
  }) {
    return PlayerModel(
      nickname: nickname ?? this.nickname,
      currentHp: currentHp ?? this.currentHp,
      maxHp: maxHp ?? this.maxHp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      luck: luck ?? this.luck,
      tokens: tokens ?? this.tokens,
      runes: runes ?? this.runes,
      level: level ?? this.level,
      currentExp: currentExp ?? this.currentExp,
    );
  }

  /// 초기 플레이어 상태
  factory PlayerModel.initial() {
    return const PlayerModel(
      nickname: '모험가',
      currentHp: 120,
      maxHp: 120,
      attack: 12,
      defense: 6,
      luck: 3,
      tokens: 10,
      runes: 0,
      level: 1,
      currentExp: 0,
    );
  }

  factory PlayerModel.fromMap(Map<String, dynamic> data) {
    return PlayerModel(
      nickname: data['nickname'] as String? ?? '모험가',
      currentHp: data['currentHp'] as int? ?? 120,
      maxHp: data['maxHp'] as int? ?? 120,
      attack: data['attack'] as int? ?? 12,
      defense: data['defense'] as int? ?? 6,
      luck: data['luck'] as int? ?? 3,
      tokens: data['tokens'] as int? ?? 10,
      runes: data['runes'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      currentExp: data['currentExp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'currentHp': currentHp,
      'maxHp': maxHp,
      'attack': attack,
      'defense': defense,
      'luck': luck,
      'tokens': tokens,
      'runes': runes,
      'level': level,
      'currentExp': currentExp,
    };
  }

  /// 경험치 획득 및 레벨업 처리
  PlayerModel gainExp(int amount) {
    if (amount <= 0) return this;

    var newLevel = level;
    var newExp = currentExp + amount;
    var requiredExp = _expToNextForLevel(newLevel);

    while (newExp >= requiredExp) {
      newExp -= requiredExp;
      newLevel += 1;
      requiredExp = _expToNextForLevel(newLevel);
    }

    return copyWith(level: newLevel, currentExp: newExp);
  }

  /// 코덱스 보너스 적용 (표시/전투용 합산 스탯)
  PlayerModel applyCodexBonus(CodexBonusState bonusState) {
    final total = bonusState.totalBonus;
    final newMaxHp = maxHp + total.hp;
    final newCurrentHp = currentHp.clamp(0, newMaxHp);

    return copyWith(
      attack: attack + total.attack,
      defense: defense + total.defense,
      luck: luck + total.luck,
      maxHp: newMaxHp,
      currentHp: newCurrentHp,
    );
  }

  static int _expToNextForLevel(int level) {
    final safeLevel = level.clamp(1, 999);
    return 100 + ((safeLevel - 1) * 50);
  }
}
