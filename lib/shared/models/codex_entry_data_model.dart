import 'package:cloud_firestore/cloud_firestore.dart';

class CodexEntryDataModel {
  const CodexEntryDataModel({
    required this.itemId,
    required this.collected,
    required this.discoveredAt,
    required this.encounterCount,
  });

  final String itemId;
  final bool collected;
  final DateTime? discoveredAt;
  final int encounterCount;

  CodexEntryDataModel copyWith({
    String? itemId,
    bool? collected,
    DateTime? discoveredAt,
    int? encounterCount,
  }) {
    return CodexEntryDataModel(
      itemId: itemId ?? this.itemId,
      collected: collected ?? this.collected,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      encounterCount: encounterCount ?? this.encounterCount,
    );
  }

  factory CodexEntryDataModel.fromMap(Map<String, dynamic> data) {
    final discoveredAt = data['discoveredAt'] as Timestamp?;
    return CodexEntryDataModel(
      itemId: data['itemId'] as String? ?? '',
      collected: data['collected'] as bool? ?? false,
      discoveredAt: discoveredAt?.toDate(),
      encounterCount: data['encounterCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'collected': collected,
      'discoveredAt':
          discoveredAt == null ? null : Timestamp.fromDate(discoveredAt!),
      'encounterCount': encounterCount,
    };
  }

  factory CodexEntryDataModel.initialDiscovered(String itemId) {
    return CodexEntryDataModel(
      itemId: itemId,
      collected: true,
      discoveredAt: DateTime.now(),
      encounterCount: 1,
    );
  }
}
