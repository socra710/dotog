import 'rarity.dart';

/// 코덱스 보너스 등급별 설정
class CodexBonusConfig {
  const CodexBonusConfig({
    required this.rarity,
    required this.level,
    required this.attackBonus,
    required this.defenseBonus,
    required this.hpBonus,
    required this.luckBonus,
    required this.upgradeCost,
  });

  final Rarity rarity;
  /// 보너스 레벨 (0 = 비활성화)
  final int level;
  final int attackBonus;
  final int defenseBonus;
  final int hpBonus;
  final int luckBonus;
  /// 다음 레벨 업그레이드 비용 (룬)
  final int upgradeCost;

  CodexBonusConfig copyWith({
    Rarity? rarity,
    int? level,
    int? attackBonus,
    int? defenseBonus,
    int? hpBonus,
    int? luckBonus,
    int? upgradeCost,
  }) {
    return CodexBonusConfig(
      rarity: rarity ?? this.rarity,
      level: level ?? this.level,
      attackBonus: attackBonus ?? this.attackBonus,
      defenseBonus: defenseBonus ?? this.defenseBonus,
      hpBonus: hpBonus ?? this.hpBonus,
      luckBonus: luckBonus ?? this.luckBonus,
      upgradeCost: upgradeCost ?? this.upgradeCost,
    );
  }

  /// 보너스 요약 문자열
  String get bonusSummary {
    final bonuses = <String>[];
    if (attackBonus > 0) bonuses.add('+$attackBonus 공격');
    if (defenseBonus > 0) bonuses.add('+$defenseBonus 방어');
    if (hpBonus > 0) bonuses.add('+$hpBonus 체력');
    if (luckBonus > 0) bonuses.add('+$luckBonus 운');
    return bonuses.isEmpty ? '없음' : bonuses.join(', ');
  }

  /// 활성화 여부
  bool get isActive => level > 0;

  factory CodexBonusConfig.fromMap(Map<String, dynamic> data) {
    return CodexBonusConfig(
      rarity: Rarity.values.firstWhere(
        (r) => r.name == data['rarity'],
        orElse: () => Rarity.common,
      ),
      level: data['level'] as int? ?? 0,
      attackBonus: data['attackBonus'] as int? ?? 0,
      defenseBonus: data['defenseBonus'] as int? ?? 0,
      hpBonus: data['hpBonus'] as int? ?? 0,
      luckBonus: data['luckBonus'] as int? ?? 0,
      upgradeCost: data['upgradeCost'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rarity': rarity.name,
      'level': level,
      'attackBonus': attackBonus,
      'defenseBonus': defenseBonus,
      'hpBonus': hpBonus,
      'luckBonus': luckBonus,
      'upgradeCost': upgradeCost,
    };
  }
}

/// 코덱스 보너스 상태 (4개 등급 전체)
class CodexBonusState {
  const CodexBonusState({
    required this.common,
    required this.rare,
    required this.epic,
    required this.legendary,
  });

  final CodexBonusConfig common;
  final CodexBonusConfig rare;
  final CodexBonusConfig epic;
  final CodexBonusConfig legendary;

  /// 초기 상태 (모두 비활성화)
  factory CodexBonusState.initial() {
    return CodexBonusState(
      common: CodexBonusConfig(
        rarity: Rarity.common,
        level: 0,
        attackBonus: 0,
        defenseBonus: 0,
        hpBonus: 0,
        luckBonus: 0,
        upgradeCost: 10,
      ),
      rare: CodexBonusConfig(
        rarity: Rarity.rare,
        level: 0,
        attackBonus: 0,
        defenseBonus: 0,
        hpBonus: 0,
        luckBonus: 0,
        upgradeCost: 20,
      ),
      epic: CodexBonusConfig(
        rarity: Rarity.epic,
        level: 0,
        attackBonus: 0,
        defenseBonus: 0,
        hpBonus: 0,
        luckBonus: 0,
        upgradeCost: 50,
      ),
      legendary: CodexBonusConfig(
        rarity: Rarity.legendary,
        level: 0,
        attackBonus: 0,
        defenseBonus: 0,
        hpBonus: 0,
        luckBonus: 0,
        upgradeCost: 100,
      ),
    );
  }

  /// 특정 등급의 보너스 가져오기
  CodexBonusConfig getByRarity(Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return common;
      case Rarity.rare:
        return rare;
      case Rarity.epic:
        return epic;
      case Rarity.legendary:
        return legendary;
    }
  }

  /// 특정 등급의 보너스 업그레이드
  CodexBonusState upgradeRarity(Rarity rarity, int collectionRate) {
    switch (rarity) {
      case Rarity.common:
        return copyWith(
          common: _calculateBonus(rarity, common.level + 1, collectionRate),
        );
      case Rarity.rare:
        return copyWith(
          rare: _calculateBonus(rarity, rare.level + 1, collectionRate),
        );
      case Rarity.epic:
        return copyWith(
          epic: _calculateBonus(rarity, epic.level + 1, collectionRate),
        );
      case Rarity.legendary:
        return copyWith(
          legendary:
              _calculateBonus(rarity, legendary.level + 1, collectionRate),
        );
    }
  }

  /// 보너스 계산 로직
  /// 수집률 10%당 스텟 상승, 레벨이 높을수록 배율 증가
  CodexBonusConfig _calculateBonus(
      Rarity rarity, int level, int collectionRate) {
    // 수집률 10%당 1 스텟 포인트 (최소 밸런스)
    final basePoints = (collectionRate ~/ 10) * level;

    // 등급별 스텟 분배
    final (attack, defense, hp, luck) = switch (rarity) {
      Rarity.common => (basePoints, 0, 0, 0), // 공격
      Rarity.rare => (0, basePoints, 0, 0), // 방어
      Rarity.epic => (0, 0, basePoints * 5, 0), // 체력 (x5)
      Rarity.legendary => (0, 0, 0, basePoints), // 운
    };

    // 다음 레벨 업그레이드 비용
    final upgradeCost = switch (rarity) {
      Rarity.common => 10 + (level * 5),
      Rarity.rare => 20 + (level * 10),
      Rarity.epic => 50 + (level * 20),
      Rarity.legendary => 100 + (level * 50),
    };

    return CodexBonusConfig(
      rarity: rarity,
      level: level,
      attackBonus: attack,
      defenseBonus: defense,
      hpBonus: hp,
      luckBonus: luck,
      upgradeCost: upgradeCost,
    );
  }

  /// 전체 보너스 합계
  ({int attack, int defense, int hp, int luck}) get totalBonus {
    return (
      attack: common.attackBonus + rare.attackBonus + epic.attackBonus + legendary.attackBonus,
      defense: common.defenseBonus + rare.defenseBonus + epic.defenseBonus + legendary.defenseBonus,
      hp: common.hpBonus + rare.hpBonus + epic.hpBonus + legendary.hpBonus,
      luck: common.luckBonus + rare.luckBonus + epic.luckBonus + legendary.luckBonus,
    );
  }

  CodexBonusState copyWith({
    CodexBonusConfig? common,
    CodexBonusConfig? rare,
    CodexBonusConfig? epic,
    CodexBonusConfig? legendary,
  }) {
    return CodexBonusState(
      common: common ?? this.common,
      rare: rare ?? this.rare,
      epic: epic ?? this.epic,
      legendary: legendary ?? this.legendary,
    );
  }

  factory CodexBonusState.fromMap(Map<String, dynamic> data) {
    return CodexBonusState(
      common: CodexBonusConfig.fromMap(data['common'] as Map<String, dynamic>),
      rare: CodexBonusConfig.fromMap(data['rare'] as Map<String, dynamic>),
      epic: CodexBonusConfig.fromMap(data['epic'] as Map<String, dynamic>),
      legendary:
          CodexBonusConfig.fromMap(data['legendary'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'common': common.toMap(),
      'rare': rare.toMap(),
      'epic': epic.toMap(),
      'legendary': legendary.toMap(),
    };
  }
}
