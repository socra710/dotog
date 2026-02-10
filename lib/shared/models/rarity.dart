/// 아이템 희귀도
enum Rarity {
  common('일반', 'common'),
  rare('희귀', 'rare'),
  epic('에픽', 'epic'),
  legendary('전설', 'legendary');

  const Rarity(this.label, this.code);

  final String label;
  final String code;

  static Rarity fromCode(String code) {
    return Rarity.values.firstWhere(
      (r) => r.code == code,
      orElse: () => Rarity.common,
    );
  }
}
