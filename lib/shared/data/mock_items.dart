import '../../../shared/models/item_model.dart';
import '../../../shared/models/rarity.dart';

/// Mock 아이템 데이터
class MockItems {
  static final List<ItemModel> items = [
    const ItemModel(
      id: 'copper_lantern',
      name: '구리 등불',
      description: '어둠을 밝히는 소박한 등불',
      rarity: Rarity.common,
      attackBonus: 0,
      defenseBonus: 1,
      hpBonus: 0,
      luckBonus: 0,
    ),
    const ItemModel(
      id: 'rune_fragment',
      name: '룬 조각',
      description: '고대 마법의 흔적이 남아있다',
      rarity: Rarity.common,
      attackBonus: 1,
      defenseBonus: 0,
      hpBonus: 0,
      luckBonus: 0,
    ),
    const ItemModel(
      id: 'mist_compass',
      name: '안개 나침반',
      description: '안개 속에서도 길을 찾게 해준다',
      rarity: Rarity.rare,
      attackBonus: 0,
      defenseBonus: 0,
      hpBonus: 0,
      luckBonus: 2,
    ),
    const ItemModel(
      id: 'wraith_sigil',
      name: '망령의 인장',
      description: '망령의 힘이 깃든 인장',
      rarity: Rarity.rare,
      attackBonus: 2,
      defenseBonus: 0,
      hpBonus: 0,
      luckBonus: 0,
    ),
    const ItemModel(
      id: 'golden_shell',
      name: '황금 껍질',
      description: '전설적인 방어구의 파편',
      rarity: Rarity.legendary,
      attackBonus: 0,
      defenseBonus: 0,
      hpBonus: 5,
      luckBonus: 0,
    ),
    const ItemModel(
      id: 'silent_pillar',
      name: '침묵의 주상',
      description: '모든 소리를 흡수하는 신비한 기둥',
      rarity: Rarity.legendary,
      attackBonus: 0,
      defenseBonus: 3,
      hpBonus: 0,
      luckBonus: 0,
    ),
  ];

  static ItemModel? findById(String id) {
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
}
