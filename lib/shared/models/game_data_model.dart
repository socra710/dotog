import 'package:cloud_firestore/cloud_firestore.dart';

import 'codex_bonus_model.dart';
import 'codex_entry_data_model.dart';
import 'player_model.dart';

class GameDataModel {
  const GameDataModel({
    required this.player,
    required this.inventoryItemIds,
    required this.codexEntries,
    required this.codexBonusState,
    required this.createdAt,
    required this.updatedAt,
  });

  final PlayerModel player;
  final List<String> inventoryItemIds;
  final List<CodexEntryDataModel> codexEntries;
  final CodexBonusState codexBonusState;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 코덱스 보너스가 반영된 플레이어 스탯
  PlayerModel get playerWithCodexBonus =>
      player.applyCodexBonus(codexBonusState);

  GameDataModel copyWith({
    PlayerModel? player,
    List<String>? inventoryItemIds,
    List<CodexEntryDataModel>? codexEntries,
    CodexBonusState? codexBonusState,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameDataModel(
      player: player ?? this.player,
      inventoryItemIds: inventoryItemIds ?? this.inventoryItemIds,
      codexEntries: codexEntries ?? this.codexEntries,
      codexBonusState: codexBonusState ?? this.codexBonusState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory GameDataModel.initial() {
    final now = DateTime.now();
    return GameDataModel(
      player: PlayerModel.initial(),
      inventoryItemIds: const ['copper_lantern'],
      codexEntries: [
        CodexEntryDataModel.initialDiscovered('copper_lantern'),
      ],
      codexBonusState: CodexBonusState.initial(),
      createdAt: now,
      updatedAt: now,
    );
  }

  factory GameDataModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final playerData = data['player'] as Map<String, dynamic>? ?? {};
    final inventory = (data['inventoryItemIds'] as List<dynamic>?) ?? const [];
    final codex = (data['codexEntries'] as List<dynamic>?) ?? const [];
    final codexBonusData =
        data['codexBonusState'] as Map<String, dynamic>? ?? const {};

    return GameDataModel(
      player: PlayerModel.fromMap(playerData),
      inventoryItemIds: inventory.map((e) => e.toString()).toList(),
      codexEntries: codex
          .whereType<Map<String, dynamic>>()
          .map(CodexEntryDataModel.fromMap)
          .toList(),
      codexBonusState: codexBonusData.isEmpty
          ? CodexBonusState.initial()
          : CodexBonusState.fromMap(codexBonusData),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'player': player.toMap(),
      'inventoryItemIds': inventoryItemIds,
      'codexEntries': codexEntries.map((entry) => entry.toMap()).toList(),
      'codexBonusState': codexBonusState.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
