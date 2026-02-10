import 'rarity.dart';

/// 아이템/유물 모델
class ItemModel {
  const ItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.attackBonus,
    required this.defenseBonus,
    required this.hpBonus,
    required this.luckBonus,
  });

  final String id;
  final String name;
  final String description;
  final Rarity rarity;
  final int attackBonus;
  final int defenseBonus;
  final int hpBonus;
  final int luckBonus;

  /// 보너스 요약 문자열 생성
  String get bonusSummary {
    final bonuses = <String>[];
    if (attackBonus > 0) bonuses.add('+$attackBonus 공격');
    if (defenseBonus > 0) bonuses.add('+$defenseBonus 방어');
    if (hpBonus > 0) bonuses.add('+$hpBonus 체력');
    if (luckBonus > 0) bonuses.add('+$luckBonus 운');
    return bonuses.join(', ');
  }
}
