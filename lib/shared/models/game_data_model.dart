import 'package:cloud_firestore/cloud_firestore.dart';

import 'codex_entry_data_model.dart';
import 'player_model.dart';

class GameDataModel {
  const GameDataModel({
    required this.player,
    required this.inventoryItemIds,
    required this.codexEntries,
    required this.createdAt,
    required this.updatedAt,
  });

  final PlayerModel player;
  final List<String> inventoryItemIds;
  final List<CodexEntryDataModel> codexEntries;
  final DateTime createdAt;
  final DateTime updatedAt;

  GameDataModel copyWith({
    PlayerModel? player,
    List<String>? inventoryItemIds,
    List<CodexEntryDataModel>? codexEntries,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameDataModel(
      player: player ?? this.player,
      inventoryItemIds: inventoryItemIds ?? this.inventoryItemIds,
      codexEntries: codexEntries ?? this.codexEntries,
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
      createdAt: now,
      updatedAt: now,
    );
  }

  factory GameDataModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final playerData = data['player'] as Map<String, dynamic>? ?? {};
    final inventory = (data['inventoryItemIds'] as List<dynamic>?) ?? const [];
    final codex = (data['codexEntries'] as List<dynamic>?) ?? const [];

    return GameDataModel(
      player: PlayerModel.fromMap(playerData),
      inventoryItemIds: inventory.map((e) => e.toString()).toList(),
      codexEntries: codex
          .whereType<Map<String, dynamic>>()
          .map(CodexEntryDataModel.fromMap)
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'player': player.toMap(),
      'inventoryItemIds': inventoryItemIds,
      'codexEntries': codexEntries.map((entry) => entry.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
