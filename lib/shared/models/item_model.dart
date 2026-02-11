import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Firestore 데이터로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rarity': rarity.toFirestore(),
      'attackBonus': attackBonus,
      'defenseBonus': defenseBonus,
      'hpBonus': hpBonus,
      'luckBonus': luckBonus,
      'createdAt': Timestamp.now(),
    };
  }

  /// Firestore 문서에서 생성
  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      rarity: Rarity.fromFirestore(data['rarity'] as String? ?? 'common'),
      attackBonus: data['attackBonus'] as int? ?? 0,
      defenseBonus: data['defenseBonus'] as int? ?? 0,
      hpBonus: data['hpBonus'] as int? ?? 0,
      luckBonus: data['luckBonus'] as int? ?? 0,
    );
  }

  /// Map에서 생성 (Firestore 데이터용)
  factory ItemModel.fromMap(Map<String, dynamic> data) {
    return ItemModel(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      rarity: Rarity.fromFirestore(data['rarity'] as String? ?? 'common'),
      attackBonus: data['attackBonus'] as int? ?? 0,
      defenseBonus: data['defenseBonus'] as int? ?? 0,
      hpBonus: data['hpBonus'] as int? ?? 0,
      luckBonus: data['luckBonus'] as int? ?? 0,
    );
  }
}
